import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/asistencia_service.dart';
import '../../services/horario_service.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';
import '../../models/horario.dart';

class AdminConsultaAsistenciasScreen extends StatefulWidget {
  const AdminConsultaAsistenciasScreen({super.key});

  @override
  State<AdminConsultaAsistenciasScreen> createState() =>
      _AdminConsultaAsistenciasScreenState();
}

class _AdminConsultaAsistenciasScreenState
    extends State<AdminConsultaAsistenciasScreen> {
  final AsistenciaService _asistenciaService = AsistenciaService();
  final HorarioService _horarioService = HorarioService();
  final UsuarioService _usuarioService = UsuarioService();

  List<Usuario> _maestros = [];
  List<HorarioMaestro> _horarios = [];
  Map<String, List<dynamic>> _asistencias = {
    'checador': [],
    'jefe': [],
    'maestro': [],
  };

  int? _selectedMaestroId;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _error;

  // Estadísticas
  final Map<String, int> _stats = {
    'total': 0,
    'checador_presente': 0,
    'checador_falta': 0,
    'checador_retardo': 0,
    'jefe_presente': 0,
    'jefe_falta': 0,
    'jefe_retardo': 0,
    'maestro_presente': 0,
    'maestro_falta': 0,
    'maestro_retardo': 0,
  };

  final List<Map<String, dynamic>> _diasSemana = [
    {'nombre': 'Lunes', 'index': 1},
    {'nombre': 'Martes', 'index': 2},
    {'nombre': 'Miércoles', 'index': 3},
    {'nombre': 'Jueves', 'index': 4},
    {'nombre': 'Viernes', 'index': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadMaestros();
  }

  Future<void> _loadMaestros() async {
    try {
      final maestros = await _usuarioService.getMaestros();
      setState(() {
        _maestros = maestros;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar maestros: $e';
      });
    }
  }

  Future<void> _consultarAsistencias() async {
    if (_selectedMaestroId == null) {
      setState(() {
        _error = 'Por favor seleccione un profesor';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fechaInicio = _getWeekStart(_selectedDate);
      final fechaFin = _getWeekEnd(_selectedDate);

      // Obtener horarios del maestro
      _horarios = await _horarioService.getByMaestro(_selectedMaestroId!);

      // Obtener asistencias de la semana
      _asistencias = await _asistenciaService.getAsistenciasPorSemana(
        maestroId: _selectedMaestroId!,
        fechaInicio: DateFormat('yyyy-MM-dd').format(fechaInicio),
        fechaFin: DateFormat('yyyy-MM-dd').format(fechaFin),
      );

      // Filtrar solo las asistencias de los horarios del maestro
      final horariosIds = _horarios.map((h) => h.id).toSet();
      _asistencias['checador'] = _asistencias['checador']!
          .where((a) => horariosIds.contains(a['horario_id']))
          .toList();
      _asistencias['jefe'] = _asistencias['jefe']!
          .where((a) => horariosIds.contains(a['horario_id']))
          .toList();
      _asistencias['maestro'] = _asistencias['maestro']!
          .where((a) => horariosIds.contains(a['horario_id']))
          .toList();

      _calcularEstadisticas();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al consultar asistencias: $e';
      });
    }
  }

  void _calcularEstadisticas() {
    // Resetear estadísticas
    _stats.updateAll((key, value) => 0);

    // Calcular total de clases esperadas
    int totalClases = 0;
    for (final horario in _horarios) {
      final dias = horario.dias?.toLowerCase() ?? '';
      for (final dia in _diasSemana) {
        if (dias.contains(dia['nombre'].toString().toLowerCase())) {
          totalClases++;
        }
      }
    }
    _stats['total'] = totalClases;

    // Contar asistencias por tipo
    for (final tipo in ['checador', 'jefe', 'maestro']) {
      for (final asistencia in _asistencias[tipo]!) {
        final estado = asistencia['asistencia'];
        if (estado == 'Presente') {
          _stats['${tipo}_presente'] = (_stats['${tipo}_presente'] ?? 0) + 1;
        } else if (estado == 'Falta') {
          _stats['${tipo}_falta'] = (_stats['${tipo}_falta'] ?? 0) + 1;
        } else if (estado == 'Retardo') {
          _stats['${tipo}_retardo'] = (_stats['${tipo}_retardo'] ?? 0) + 1;
        }
      }
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  String _getWeekRange() {
    final start = _getWeekStart(_selectedDate);
    final end = _getWeekEnd(_selectedDate);
    return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
  }

  List<HorarioMaestro> _getHorariosForDay(String dia) {
    return _horarios.where((h) {
      final dias = h.dias?.toLowerCase() ?? '';
      return dias.contains(dia.toLowerCase());
    }).toList()
      ..sort((a, b) => (a.horaInicio ?? '').compareTo(b.horaInicio ?? ''));
  }

  String _getAsistenciaEstado(int? horarioId, String tipo, String dia) {
    if (horarioId == null) return 'Sin registro';

    final fecha = _getFechaDelDia(dia);
    try {
      final asistencia = _asistencias[tipo]?.firstWhere(
        (a) =>
            a['horario_id'] == horarioId &&
            a['fecha'] == DateFormat('yyyy-MM-dd').format(fecha),
      );
      return asistencia?['asistencia'] ?? 'Sin registro';
    } catch (e) {
      return 'Sin registro';
    }
  }

  DateTime _getFechaDelDia(String dia) {
    final diasMap = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
    };

    final startOfWeek = _getWeekStart(_selectedDate);
    final targetDay = diasMap[dia] ?? 1;
    return startOfWeek.add(Duration(days: targetDay - 1));
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Presente':
        return Colors.green.shade100;
      case 'Falta':
        return Colors.red.shade100;
      case 'Retardo':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'Presente':
        return Colors.green.shade900;
      case 'Falta':
        return Colors.red.shade900;
      case 'Retardo':
        return Colors.orange.shade900;
      default:
        return Colors.grey.shade700;
    }
  }

  String _calcularPorcentaje(int presentes, int retardos, int total) {
    if (total == 0) return '0%';
    final valorPonderado = presentes + (retardos * 0.5);
    return '${((valorPonderado / total) * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Profesor',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: _selectedMaestroId,
                          items: _maestros.map((maestro) {
                            return DropdownMenuItem(
                              value: maestro.id,
                              child: Text(
                                maestro.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMaestroId = value;
                            });
                            if (value != null) {
                              _consultarAsistencias();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              locale: const Locale('es', 'ES'),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                              if (_selectedMaestroId != null) {
                                _consultarAsistencias();
                              }
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semana: ${_getWeekRange()}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate
                                  .subtract(const Duration(days: 7));
                            });
                            if (_selectedMaestroId != null) {
                              _consultarAsistencias();
                            }
                          },
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(const Duration(days: 7));
                            });
                            if (_selectedMaestroId != null) {
                              _consultarAsistencias();
                            }
                          },
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Siguiente'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!_loading &&
              _selectedMaestroId != null &&
              _horarios.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Estadísticas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen Semanal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.blue.shade50),
                        columns: const [
                          DataColumn(
                              label: Text('Concepto',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Checador',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Jefe',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Maestro',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: [
                          DataRow(cells: [
                            const DataCell(Text('Total de Clases',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${_stats['total']}')),
                            DataCell(Text('${_stats['total']}')),
                            DataCell(Text('${_stats['total']}')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('Presentes')),
                            DataCell(Text('${_stats['checador_presente']}')),
                            DataCell(Text('${_stats['jefe_presente']}')),
                            DataCell(Text('${_stats['maestro_presente']}')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('Retardos')),
                            DataCell(Text('${_stats['checador_retardo']}')),
                            DataCell(Text('${_stats['jefe_retardo']}')),
                            DataCell(Text('${_stats['maestro_retardo']}')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('Faltas')),
                            DataCell(Text('${_stats['checador_falta']}')),
                            DataCell(Text('${_stats['jefe_falta']}')),
                            DataCell(Text('${_stats['maestro_falta']}')),
                          ]),
                          DataRow(cells: [
                            const DataCell(Text('% Asistencia*',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(_calcularPorcentaje(
                              _stats['checador_presente']!,
                              _stats['checador_retardo']!,
                              _stats['total']!,
                            ))),
                            DataCell(Text(_calcularPorcentaje(
                              _stats['jefe_presente']!,
                              _stats['jefe_retardo']!,
                              _stats['total']!,
                            ))),
                            DataCell(Text(_calcularPorcentaje(
                              _stats['maestro_presente']!,
                              _stats['maestro_retardo']!,
                              _stats['total']!,
                            ))),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* Los retardos cuentan como 0.5 (50% de asistencia)',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Detalle por día
            const Text(
              'Detalle por Día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._diasSemana.map((dia) {
              final horariosDelDia = _getHorariosForDay(dia['nombre']);
              if (horariosDelDia.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    dia['nombre'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  initiallyExpanded: true,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DataTable(
                          columnSpacing: 12,
                          headingRowColor:
                              WidgetStateProperty.all(Colors.blue.shade50),
                          columns: const [
                            DataColumn(
                                label: Text('Hora',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Materia',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Grupo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Checador',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Jefe',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Maestro',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: horariosDelDia.map((horario) {
                            final checadorEstado = _getAsistenciaEstado(
                                horario.id, 'checador', dia['nombre']);
                            final jefeEstado = _getAsistenciaEstado(
                                horario.id, 'jefe', dia['nombre']);
                            final maestroEstado = _getAsistenciaEstado(
                                horario.id, 'maestro', dia['nombre']);

                            return DataRow(cells: [
                              DataCell(Text(
                                '${horario.horaInicio} - ${horario.horaFin}',
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(SizedBox(
                                width: 120,
                                child: Text(
                                  horario.nombreMateria,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(SizedBox(
                                width: 80,
                                child: Text(
                                  horario.nombreGrupo,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(checadorEstado),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  checadorEstado,
                                  style: TextStyle(
                                    color: _getEstadoTextColor(checadorEstado),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(jefeEstado),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  jefeEstado,
                                  style: TextStyle(
                                    color: _getEstadoTextColor(jefeEstado),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(maestroEstado),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  maestroEstado,
                                  style: TextStyle(
                                    color: _getEstadoTextColor(maestroEstado),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (!_loading && _selectedMaestroId != null && _horarios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No se encontraron horarios para este profesor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
