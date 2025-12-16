import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/horario_service.dart';
import '../../services/grupo_service.dart';
import '../../services/asistencia_service.dart';
import '../../models/horario.dart';
import '../../models/grupo.dart';
import '../../models/asistencia.dart';

class JefeHorarioScreen extends StatefulWidget {
  const JefeHorarioScreen({super.key});

  @override
  State<JefeHorarioScreen> createState() => _JefeHorarioScreenState();
}

class _JefeHorarioScreenState extends State<JefeHorarioScreen> {
  final HorarioService _horarioService = HorarioService();
  final GrupoService _grupoService = GrupoService();
  final AsistenciaService _asistenciaService = AsistenciaService();

  List<HorarioMaestro> _horarios = [];
  Grupo? _miGrupo;
  bool _isLoading = true;
  String _selectedDate = '';
  final Map<int, String> _asistenciasMap = {}; // horarioId -> estado asistencia

  void refresh() {
    _loadHorarios();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().split('T')[0];
    // Postpone loading until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHorarios();
    });
  }

  Future<void> _loadHorarios() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user?.id == null) {
        throw Exception('Usuario no encontrado');
      }

      // Obtener el grupo del jefe
      final grupos = await _grupoService.getAll();
      _miGrupo = grupos.firstWhere(
        (g) => g.jefeId == user!.id,
        orElse: () => throw Exception('No se encontró un grupo asignado'),
      );

      // Obtener horarios del grupo
      final todosHorarios = await _horarioService.getAll();
      final horariosGrupo =
          todosHorarios.where((h) => h.grupoId == _miGrupo!.id).toList();

      // Obtener asistencias del día seleccionado
      final asistencias = await _asistenciaService.getAsistenciasJefe(
        fecha: _selectedDate,
      );

      // Crear mapa de asistencias
      _asistenciasMap.clear();
      for (var asistencia in asistencias) {
        if (asistencia.horarioId != null) {
          _asistenciasMap[asistencia.horarioId!] = asistencia.asistencia.value;
        }
      }

      if (mounted) {
        setState(() {
          _horarios = horariosGrupo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _registrarAsistencia(
      HorarioMaestro horario, TipoAsistencia tipo) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user?.id == null) {
        throw Exception('Usuario no autenticado');
      }

      if (horario.id == null) {
        throw Exception('Horario sin ID válido');
      }

      // Verificar si ya existe una asistencia
      List<AsistenciaJefe> asistencias = [];
      try {
        asistencias = await _asistenciaService.getAsistenciasJefe(
          horarioId: horario.id,
          fecha: _selectedDate,
        );
      } catch (e) {
        // Si falla la consulta, asumimos que no hay asistencias previas
        print('Error al consultar asistencias previas: $e');
        asistencias = [];
      }

      if (asistencias.isNotEmpty && asistencias.first.id != null) {
        // Actualizar asistencia existente
        await _asistenciaService.updateAsistenciaJefe(
          asistencias.first.id!,
          tipo,
        );
      } else {
        // Crear nueva asistencia
        final asistencia = AsistenciaJefe(
          horarioId: horario.id,
          fecha: _selectedDate,
          asistencia: tipo,
          jefeId: user!.id!,
        );

        await _asistenciaService.createAsistenciaJefe(asistencia);
      }

      // Actualizar mapa local
      if (mounted) {
        setState(() {
          _asistenciasMap[horario.id!] = tipo.value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asistencia registrada: ${tipo.value}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al registrar asistencia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Información del grupo y fecha
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (_miGrupo != null) ...[
                        Text(
                          'Grupo: ${_miGrupo!.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Aula: ${_miGrupo!.nombreAula}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      ] else
                        const Text(
                          'Cargando...',
                          style: TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.orange[700],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedDate,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Lista de horarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _horarios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay horarios para este día',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHorarios,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _horarios.length,
                        itemBuilder: (context, index) {
                          final horario = _horarios[index];
                          final asistenciaActual = horario.id != null
                              ? _asistenciasMap[horario.id!]
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Información del horario
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.orange.shade100,
                                        child: const Icon(Icons.school,
                                            color: Colors.orange),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              horario.nombreMateria,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Profesor: ${horario.nombreMaestro}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            Text(
                                              'Hora: ${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Estado actual
                                  if (asistenciaActual != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getColorForAsistencia(
                                                asistenciaActual)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getIconForAsistencia(
                                                asistenciaActual),
                                            size: 16,
                                            color: _getColorForAsistencia(
                                                asistenciaActual),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Estado: $asistenciaActual',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _getColorForAsistencia(
                                                  asistenciaActual),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 12),
                                  const SizedBox(height: 8),

                                  // Botones de asistencia
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildAsistenciaButton(
                                        'Presente',
                                        Colors.green,
                                        Icons.check_circle,
                                        TipoAsistencia.presente,
                                        horario,
                                        asistenciaActual == 'Presente',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildAsistenciaButton(
                                        'Falta',
                                        Colors.red,
                                        Icons.cancel,
                                        TipoAsistencia.falta,
                                        horario,
                                        asistenciaActual == 'Falta',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildAsistenciaButton(
                                        'Retardo',
                                        Colors.orange,
                                        Icons.access_time,
                                        TipoAsistencia.retardado,
                                        horario,
                                        asistenciaActual == 'Retardo',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAsistenciaButton(
    String label,
    Color color,
    IconData icon,
    TipoAsistencia tipo,
    HorarioMaestro horario,
    bool isSelected,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _registrarAsistencia(horario, tipo),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 8),
          elevation: isSelected ? 2 : 0,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForAsistencia(String asistencia) {
    switch (asistencia) {
      case 'Presente':
        return Colors.green;
      case 'Falta':
        return Colors.red;
      case 'Retardo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForAsistencia(String asistencia) {
    switch (asistencia) {
      case 'Presente':
        return Icons.check_circle;
      case 'Falta':
        return Icons.cancel;
      case 'Retardo':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}
