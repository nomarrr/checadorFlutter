import 'package:flutter/material.dart';
import '../../services/aula_service.dart';
import '../../services/edificio_service.dart';

class AdminAulasScreen extends StatefulWidget {
  const AdminAulasScreen({super.key});

  @override
  State<AdminAulasScreen> createState() => _AdminAulasScreenState();
}

class _AdminAulasScreenState extends State<AdminAulasScreen> {
  final AulaService _aulaService = AulaService();
  final EdificioService _edificioService = EdificioService();
  final TextEditingController _nombreController = TextEditingController();
  
  List<dynamic> _aulas = [];
  List<dynamic> _edificios = [];
  bool _loading = false;
  dynamic _aulaEditando;
  int? _selectedEdificio;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final aulas = await _aulaService.getAll();
      final edificios = await _edificioService.getAll();
      if (mounted) {
        setState(() {
          _aulas = aulas;
          _edificios = edificios;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void _showForm([dynamic aula]) {
    _aulaEditando = aula;
    _nombreController.text = aula?['numero'] ?? '';
    _selectedEdificio = aula?['edificio_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(aula == null ? 'Nueva Aula' : 'Editar Aula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Número del Aula (ej: 101, 201)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedEdificio,
                decoration: const InputDecoration(
                  labelText: 'Edificio',
                  border: OutlineInputBorder(),
                ),
                items: _edificios.map((edificio) {
                  return DropdownMenuItem<int>(
                    value: edificio['id'],
                    child: Text(edificio['nombre'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    _selectedEdificio = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _guardarAula();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarAula() async {
    final numero = _nombreController.text.trim();
    if (numero.isEmpty || _selectedEdificio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número y edificio son requeridos')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_aulaEditando == null) {
        await _aulaService.create(numero, _selectedEdificio!);
      } else {
        await _aulaService.update(_aulaEditando['id'], numero, _selectedEdificio!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aula ${_aulaEditando == null ? "creada" : "actualizada"} correctamente')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _eliminarAula(dynamic aula) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar el aula "${aula['numero']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && aula['id'] != null) {
      setState(() => _loading = true);
      try {
        await _aulaService.delete(aula['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aula eliminada correctamente')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  String _getNombreEdificio(int? edificioId) {
    if (edificioId == null) return 'N/A';
    final edificio = _edificios.firstWhere(
      (e) => e['id'] == edificioId,
      orElse: () => <String, dynamic>{'nombre': 'N/A'},
    );
    return edificio['nombre'] ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Gestión de Aulas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Aula'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _aulas.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay aulas registradas',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                            columns: const [
                              DataColumn(label: Text('Numero', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Edificio', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _aulas.map((aula) {
                              return DataRow(cells: [
                                DataCell(Text(aula['numero'] ?? '')),
                                DataCell(Text(_getNombreEdificio(aula['edificio_id']))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showForm(aula),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarAula(aula),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

