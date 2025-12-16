import 'package:flutter/material.dart';
import '../../models/grupo.dart';
import '../../models/usuario.dart';
import '../../models/carrera.dart';
import '../../services/grupo_service.dart';
import '../../services/usuario_service.dart';
import '../../services/carrera_service.dart';
import '../../services/aula_service.dart';
import '../../services/edificio_service.dart';

class AdminGruposScreen extends StatefulWidget {
  const AdminGruposScreen({super.key});

  @override
  State<AdminGruposScreen> createState() => _AdminGruposScreenState();
}

class _AdminGruposScreenState extends State<AdminGruposScreen> {
  final GrupoService _grupoService = GrupoService();
  final UsuarioService _usuarioService = UsuarioService();
  final CarreraService _carreraService = CarreraService();
  final AulaService _aulaService = AulaService();
  final EdificioService _edificioService = EdificioService();

  List<Grupo> grupos = [];
  List<Carrera> carreras = [];
  List<Usuario> jefes = [];
  List<dynamic> aulas = [];
  List<dynamic> edificios = [];

  // Controladores del formulario
  final TextEditingController _nombreController = TextEditingController();
  int? _selectedCarreraId;
  int? _selectedJefeId;
  dynamic _selectedAulaId;

  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _grupoService.getAll(),
        _carreraService.getAll(),
        _usuarioService.getJefes(),
        _aulaService.getAll(),
        _edificioService.getAll(),
      ]);

      setState(() {
        grupos = results[0] as List<Grupo>;
        carreras = results[1] as List<Carrera>;
        jefes = results[2] as List<Usuario>;
        aulas = results[3];
        edificios = results[4];
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar los datos');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _crearGrupo() async {
    if (_nombreController.text.isEmpty ||
        _selectedCarreraId == null ||
        _selectedJefeId == null ||
        _selectedAulaId == null) {
      setState(() => _error = 'Por favor complete todos los campos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final nuevoGrupo = Grupo(
        name: _nombreController.text,
        carreraId: _selectedCarreraId,
        jefeId: _selectedJefeId,
        aulaId: _selectedAulaId,
      );

      await _grupoService.create(nuevoGrupo);
      setState(() => _success = 'Grupo creado correctamente');
      _limpiarFormulario();
      await _loadData();
    } catch (e) {
      setState(() => _error = 'Error al crear el grupo');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _eliminarGrupo(Grupo grupo) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el grupo "${grupo.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _grupoService.delete(grupo.id ?? 0);
      setState(() => _success = 'Grupo eliminado correctamente');
      await _loadData();
    } catch (e) {
      setState(() => _error = 'Error al eliminar el grupo');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _selectedCarreraId = null;
    _selectedJefeId = null;
    _selectedAulaId = null;
  }

  String _getNombreCarrera(int? carreraId) {
    if (carreraId == null) return 'N/A';
    try {
      return carreras.firstWhere((c) => c.id == carreraId).nombre;
    } catch (e) {
      return 'N/A';
    }
  }

  String _getNombreJefe(int? jefeId) {
    if (jefeId == null) return 'N/A';
    try {
      final jefe = jefes.firstWhere((j) => j.id == jefeId);
      return '${jefe.name} - ${jefe.numeroCuenta}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getNombreAula(int? aulaId) {
    if (aulaId == null) return 'N/A';
    try {
      final aula = aulas.firstWhere((a) => a['id'] == aulaId);
      return aula['numero']?.toString() ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getNombreEdificio(int? aulaId) {
    if (aulaId == null) return 'N/A';
    try {
      final aula = aulas.firstWhere((a) => a['id'] == aulaId);
      final edificioId = aula['edificio_id'];
      final edificio = edificios.firstWhere((e) => e['id'] == edificioId);
      return edificio['nombre']?.toString() ?? 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Grupos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alertas
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _success!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _success = null),
                    ),
                  ],
                ),
              ),
            // Tarjeta de formulario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear Nuevo Grupo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Grupo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCarreraId,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      items: carreras
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.nombre),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCarreraId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedJefeId,
                      decoration: const InputDecoration(
                        labelText: 'Jefe de Grupo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: jefes
                          .map((j) => DropdownMenuItem(
                                value: j.id,
                                child: Text('${j.name} - ${j.numeroCuenta}'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedJefeId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<dynamic>(
                      initialValue: _selectedAulaId,
                      decoration: const InputDecoration(
                        labelText: 'Aula',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.door_sliding),
                      ),
                      items: aulas
                          .map<DropdownMenuItem<dynamic>>(
                              (a) => DropdownMenuItem(
                                    value: a['id'],
                                    child: Text(
                                        '${a['numero']} - ${_getNombreEdificioParaAula(a)}'),
                                  ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAulaId = value),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _crearGrupo,
                        icon: const Icon(Icons.add),
                        label: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear Grupo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tarjeta de tabla
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grupos Existentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (grupos.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No hay grupos registrados'),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nombre')),
                            DataColumn(label: Text('Carrera')),
                            DataColumn(label: Text('Jefe de Grupo')),
                            DataColumn(label: Text('Aula')),
                            DataColumn(label: Text('Edificio')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: grupos
                              .map(
                                (grupo) => DataRow(
                                  cells: [
                                    DataCell(Text(grupo.name)),
                                    DataCell(Text(
                                        _getNombreCarrera(grupo.carreraId))),
                                    DataCell(
                                        Text(_getNombreJefe(grupo.jefeId))),
                                    DataCell(
                                        Text(_getNombreAula(grupo.aulaId))),
                                    DataCell(
                                        Text(_getNombreEdificio(grupo.aulaId))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _eliminarGrupo(grupo),
                                        tooltip: 'Eliminar grupo',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNombreEdificioParaAula(dynamic aula) {
    try {
      final edificioId = aula['edificio_id'];
      final edificio = edificios.firstWhere((e) => e['id'] == edificioId);
      return edificio['nombre']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }
}
