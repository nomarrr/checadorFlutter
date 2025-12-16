import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/auth_provider.dart';
import '../../services/horario_service.dart';
import '../../services/asistencia_service.dart';
import '../../models/horario.dart';
import '../../models/asistencia.dart';

class MaestroDashboardScreen extends StatefulWidget {
  const MaestroDashboardScreen({super.key});

  @override
  State<MaestroDashboardScreen> createState() => _MaestroDashboardScreenState();
}

class _MaestroDashboardScreenState extends State<MaestroDashboardScreen> {
  final HorarioService _horarioService = HorarioService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  List<HorarioMaestro> _horarios = [];
  final Map<int, AsistenciaMaestro?> _asistenciasHoy = {};
  bool _isLoading = true;
  final DateTime _selectedDate = DateTime.now();
  bool _localeInitialized = false;

  void refresh() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    if (!_localeInitialized) {
      await initializeDateFormatting('es_ES', null);
      _localeInitialized = true;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user?.id != null) {
        final horarios = await _horarioService.getByMaestro(user!.id!);
        await _loadAsistencias(horarios);

        setState(() {
          _horarios = horarios;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _loadAsistencias(List<HorarioMaestro> horarios) async {
    final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    for (var horario in horarios) {
      if (horario.id != null) {
        try {
          final asistencias = await _asistenciaService.getAsistenciasMaestro(
            horarioId: horario.id,
            fecha: fechaStr,
          );

          if (asistencias.isNotEmpty) {
            _asistenciasHoy[horario.id!] = asistencias.first;
          } else {
            _asistenciasHoy[horario.id!] = null;
          }
        } catch (e) {
          _asistenciasHoy[horario.id!] = null;
        }
      }
    }
  }

  Future<void> _registrarAsistencia(
      HorarioMaestro horario, TipoAsistencia tipo) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user?.id == null || horario.id == null) return;

    try {
      final asistencia = AsistenciaMaestro(
        horarioId: horario.id!,
        maestroId: user!.id!,
        fecha: DateFormat('yyyy-MM-dd').format(_selectedDate),
        asistencia: tipo,
      );

      await _asistenciaService.createAsistenciaMaestro(asistencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistencia registrada correctamente')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesAsistencia(HorarioMaestro horario) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar Asistencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${horario.nombreMateria} - ${horario.nombreGrupo}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white),
              ),
              title: const Text('Presente'),
              onTap: () {
                Navigator.pop(context);
                _registrarAsistencia(horario, TipoAsistencia.presente);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.access_time, color: Colors.white),
              ),
              title: const Text('Retardo'),
              onTap: () {
                Navigator.pop(context);
                _registrarAsistencia(horario, TipoAsistencia.retardado);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white),
              ),
              title: const Text('Falta'),
              onTap: () {
                Navigator.pop(context);
                _registrarAsistencia(horario, TipoAsistencia.falta);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(TipoAsistencia? tipo) {
    if (tipo == null) return Colors.grey.shade200;
    switch (tipo) {
      case TipoAsistencia.presente:
        return Colors.green.shade100;
      case TipoAsistencia.retardado:
        return Colors.orange.shade100;
      case TipoAsistencia.falta:
        return Colors.red.shade100;
    }
  }

  Color _getEstadoIconColor(TipoAsistencia? tipo) {
    if (tipo == null) return Colors.grey;
    switch (tipo) {
      case TipoAsistencia.presente:
        return Colors.green;
      case TipoAsistencia.retardado:
        return Colors.orange;
      case TipoAsistencia.falta:
        return Colors.red;
    }
  }

  IconData _getEstadoIcon(TipoAsistencia? tipo) {
    if (tipo == null) return Icons.radio_button_unchecked;
    switch (tipo) {
      case TipoAsistencia.presente:
        return Icons.check_circle;
      case TipoAsistencia.retardado:
        return Icons.access_time;
      case TipoAsistencia.falta:
        return Icons.cancel;
    }
  }

  String _getEstadoTexto(TipoAsistencia? tipo) {
    if (tipo == null) return 'Sin registro';
    switch (tipo) {
      case TipoAsistencia.presente:
        return 'Presente';
      case TipoAsistencia.retardado:
        return 'Retardo';
      case TipoAsistencia.falta:
        return 'Falta';
    }
  }

  List<HorarioMaestro> _getHorariosDelDia() {
    final diaActual = DateFormat('EEEE', 'es_ES').format(_selectedDate);
    final diasMap = {
      'Monday': 'lunes',
      'Tuesday': 'martes',
      'Wednesday': 'miércoles',
      'Thursday': 'jueves',
      'Friday': 'viernes',
    };

    final diaEnEspanol = diasMap[diaActual] ?? diaActual.toLowerCase();

    return _horarios.where((h) {
      final dias = h.dias?.toLowerCase() ?? '';
      return dias.contains(diaEnEspanol);
    }).toList()
      ..sort((a, b) {
        final horaA = a.horaInicio ?? '';
        final horaB = b.horaInicio ?? '';
        return horaA.compareTo(horaB);
      });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final horariosHoy = _getHorariosDelDia();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Header con información del día
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bienvenido, ${user?.name ?? "Maestro"}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadData,
                            tooltip: 'Actualizar',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es_ES')
                                .format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clases hoy: ${horariosHoy.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lista de horarios del día
              Expanded(
                child: horariosHoy.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes clases programadas hoy',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: horariosHoy.length,
                          itemBuilder: (context, index) {
                            final horario = horariosHoy[index];
                            final asistencia = _asistenciasHoy[horario.id];
                            final tipoAsistencia = asistencia?.asistencia;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getEstadoColor(tipoAsistencia),
                                  child: Icon(
                                    _getEstadoIcon(tipoAsistencia),
                                    color: _getEstadoIconColor(tipoAsistencia),
                                  ),
                                ),
                                title: Text(
                                  horario.nombreMateria,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Grupo: ${horario.nombreGrupo}'),
                                    Text(
                                        'Aula: ${horario.nombreAula} - ${horario.nombreEdificio}'),
                                    Text(
                                      'Hora: ${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(tipoAsistencia),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getEstadoTexto(tipoAsistencia),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getEstadoIconColor(
                                              tipoAsistencia),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: asistencia == null
                                    ? ElevatedButton(
                                        onPressed: () =>
                                            _mostrarOpcionesAsistencia(horario),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Registrar'),
                                      )
                                    : const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
  }
}
