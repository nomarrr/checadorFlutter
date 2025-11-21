import 'package:flutter/material.dart';
import '../../models/horario.dart';
import '../../models/usuario.dart';
import '../../models/materia.dart';
import '../../models/grupo.dart';
import '../../models/carrera.dart';
import '../../services/horario_service.dart';
import '../../services/usuario_service.dart';
import '../../services/materia_service.dart';
import '../../services/grupo_service.dart';
import '../../services/carrera_service.dart';

class AdminConsultaHorariosScreen extends StatefulWidget {
  const AdminConsultaHorariosScreen({super.key});

  @override
  State<AdminConsultaHorariosScreen> createState() => _AdminConsultaHorariosScreenState();
}

class _AdminConsultaHorariosScreenState extends State<AdminConsultaHorariosScreen> {
  final HorarioService _horarioService = HorarioService();
  final UsuarioService _usuarioService = UsuarioService();
  final MateriaService _materiaService = MateriaService();
  final GrupoService _grupoService = GrupoService();
  final CarreraService _carreraService = CarreraService();

  List<HorarioMaestro> _horarios = [];
  List<Usuario> _maestros = [];
  List<Materia> _materias = [];
  List<Grupo> _grupos = [];
  List<Carrera> _carreras = [];

  String _filtroTipo = 'carrera';
  String? _filtroCarrera;
  String? _filtroMaestro;
  String? _filtroGrupo;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSelectors();
  }

  Future<void> _loadSelectors() async {
    try {
      final results = await Future.wait([
        _usuarioService.getMaestros(),
        _materiaService.getAll(),
        _grupoService.getAll(),
        _carreraService.getAll(),
      ]);

      setState(() {
        _maestros = results[0] as List<Usuario>;
        _materias = results[1] as List<Materia>;
        _grupos = results[2] as List<Grupo>;
        _carreras = results[3] as List<Carrera>;
      });
    } catch (e) {
      // Error al cargar datos
    }
  }

  Future<void> _buscarHorarios() async {
    setState(() {
      _loading = true;
      _horarios = [];
    });

    try {
      final filtros = <String, dynamic>{};

      if (_filtroTipo == 'carrera' && _filtroCarrera != null) {
        filtros['carrera_id'] = int.parse(_filtroCarrera!);
      } else if (_filtroTipo == 'maestro' && _filtroMaestro != null) {
        filtros['maestro_id'] = int.parse(_filtroMaestro!);
      } else if (_filtroTipo == 'grupo' && _filtroGrupo != null) {
        filtros['grupo_id'] = int.parse(_filtroGrupo!);
      }

      final horarios = await _horarioService.searchHorarios(filtros);
      setState(() {
        _horarios = horarios;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar horarios: $e')),
        );
      }
    }
  }

  String _getMaestroNombre(int? id) {
    if (id == null) return 'N/A';
    final maestro = _maestros.firstWhere((m) => m.id == id, orElse: () => Usuario(name: 'N/A'));
    return maestro.name;
  }

  String _getMateriaNombre(int? id) {
    if (id == null) return 'N/A';
    final materia = _materias.firstWhere((m) => m.id == id, orElse: () => Materia(name: 'N/A'));
    return materia.name;
  }

  String _getGrupoNombre(int? id) {
    if (id == null) return 'N/A';
    final grupo = _grupos.firstWhere((g) => g.id == id, orElse: () => Grupo(name: 'N/A'));
    return grupo.name;
  }

  String _getAulaInfo(int? id) {
    if (id == null) return 'N/A';
    final grupo = _grupos.firstWhere((g) => g.id == id, orElse: () => Grupo(name: 'N/A'));
    final aula = grupo.nombreAula;
    final edificio = grupo.nombreEdificio;
    return edificio != 'N/A' ? '$aula - $edificio' : aula;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consulta de Horarios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filtro tipo
                  DropdownButtonFormField<String>(
                    value: _filtroTipo,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'carrera', child: Text('Carrera')),
                      DropdownMenuItem(value: 'maestro', child: Text('Profesor')),
                      DropdownMenuItem(value: 'grupo', child: Text('Grupo')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroTipo = value!;
                        _filtroCarrera = null;
                        _filtroMaestro = null;
                        _filtroGrupo = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filtro específico según tipo
                  if (_filtroTipo == 'carrera')
                    DropdownButtonFormField<String>(
                      value: _filtroCarrera,
                      decoration: const InputDecoration(
                        labelText: 'Carrera',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccionar')),
                        ..._carreras.map((c) => DropdownMenuItem(
                              value: c.id.toString(),
                              child: Text(c.nombre),
                            )),
                      ],
                      onChanged: (value) => setState(() => _filtroCarrera = value),
                    ),
                  if (_filtroTipo == 'maestro')
                    DropdownButtonFormField<String>(
                      value: _filtroMaestro,
                      decoration: const InputDecoration(
                        labelText: 'Profesor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccionar')),
                        ..._maestros.map((m) => DropdownMenuItem(
                              value: m.id.toString(),
                              child: Text(m.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _filtroMaestro = value),
                    ),
                  if (_filtroTipo == 'grupo')
                    DropdownButtonFormField<String>(
                      value: _filtroGrupo,
                      decoration: const InputDecoration(
                        labelText: 'Grupo',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Seleccionar')),
                        ..._grupos.map((g) => DropdownMenuItem(
                              value: g.id.toString(),
                              child: Text(g.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _filtroGrupo = value),
                    ),
                  const SizedBox(height: 16),
                  // Botón buscar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _buscarHorarios,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabla de resultados
          if (_loading || _horarios.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horarios Encontrados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _horarios.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No se encontraron horarios',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 16,
                                    columns: const [
                                      DataColumn(label: Text('Profesor', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Materia', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Aula - Edificio', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Días', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _horarios.map((horario) {
                                      final horaInicio = horario.horaInicio?.substring(0, 5) ?? 'N/A';
                                      final horaFin = horario.horaFin?.substring(0, 5) ?? 'N/A';
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            SizedBox(
                                              width: 150,
                                              child: Text(
                                                _getMaestroNombre(horario.maestroId),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                _getMateriaNombre(horario.materiaId),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                _getGrupoNombre(horario.grupoId),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                _getAulaInfo(horario.grupoId),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                horario.dias ?? 'N/A',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('$horaInicio - $horaFin')),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
