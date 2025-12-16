import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/horario_service.dart';
import '../../services/asistencia_service.dart';
import '../../services/edificio_service.dart';
import '../../services/carrera_service.dart';
import '../../models/horario.dart';
import '../../models/asistencia.dart';
import '../../models/carrera.dart';

class ChecadorControlScreen extends StatefulWidget {
  const ChecadorControlScreen({super.key});

  @override
  State<ChecadorControlScreen> createState() => _ChecadorControlScreenState();
}

class _ChecadorControlScreenState extends State<ChecadorControlScreen> {
  final HorarioService _horarioService = HorarioService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  final EdificioService _edificioService = EdificioService();
  final CarreraService _carreraService = CarreraService();

  List<HorarioMaestro> _horarios = [];
  List<dynamic> _edificios = [];
  List<Carrera> _carreras = [];
  bool _isLoading = true;
  String _selectedDate = '';

  // Filtros en orden: Hora → Carrera → Edificio
  String? _selectedHora;
  int? _selectedCarrera;
  int? _selectedEdificio;

  String _diaActual = '';
  final Map<int, String> _asistenciasMap = {}; // horarioId -> estado

  // Horas disponibles (7am a 7pm)
  final List<String> _horasDisponibles = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00'
  ];

  final Map<int, String> _diasMap = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
  };

  void refresh() {
    _loadHorarios();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().split('T')[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDiaActual();
      _loadEdificios();
      _loadCarreras();
    });
  }

  void _updateDiaActual() {
    final date = DateTime.parse(_selectedDate);
    final diaSemana = date.weekday;

    if (diaSemana == 6 || diaSemana == 7) {
      setState(() {
        _diaActual = '';
        _horarios = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clases los fines de semana'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _diaActual = _diasMap[diaSemana] ?? '';
    });
    // NO cargar horarios automáticamente
    // Solo cuando seleccione un filtro
  }

  Future<void> _loadEdificios() async {
    try {
      final edificios = await _edificioService.getAll();
      setState(() {
        _edificios = edificios;
      });
    } catch (e) {
      print('Error al cargar edificios: $e');
    }
  }

  Future<void> _loadCarreras() async {
    try {
      final carreras = await _carreraService.getAll();
      setState(() {
        _carreras = carreras;
      });
    } catch (e) {
      print('Error al cargar carreras: $e');
    }
  }

  Future<void> _loadHorarios() async {
    if (_diaActual.isEmpty) return;

    // NO cargar si no hay ningún filtro seleccionado
    if (_selectedHora == null &&
        _selectedCarrera == null &&
        _selectedEdificio == null) {
      setState(() {
        _horarios = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener todos los horarios
      final todosHorarios = await _horarioService.getAll();

      print('📊 Total de horarios en BD: ${todosHorarios.length}');

      // Filtrar por día
      var horariosFiltrados = todosHorarios.where((h) {
        if (h.dias == null) return false;

        // Normalizar: quitar espacios, comas, y convertir a minúsculas
        final diasLista = h.dias!
            .toLowerCase()
            .split(',')
            .map((d) => d.trim().replaceAll(' ', ''))
            .toList();

        final diaActualNormalizado =
            _diaActual.toLowerCase().replaceAll(' ', '');

        final encontrado = diasLista.any((dia) => dia == diaActualNormalizado);

        return encontrado;
      }).toList();

      print('📅 Horarios del día $_diaActual: ${horariosFiltrados.length}');
      if (horariosFiltrados.isEmpty) {
        print('⚠️  No hay horarios para $_diaActual');
      }

      // FILTRO 1: Por Hora (si está seleccionada)
      if (_selectedHora != null) {
        print('🕐 Filtrando por hora: $_selectedHora');

        // Debug: ver todas las horas disponibles
        final horasEncontradas = horariosFiltrados
            .where((h) => h.horaInicio != null)
            .map((h) {
              final hora = h.horaInicio!;
              // Si la hora tiene formato "HH:MM:SS", tomar solo "HH:MM"
              return hora.length >= 5 ? hora.substring(0, 5) : hora;
            })
            .toSet()
            .toList();
        print('   Horas disponibles en horarios: $horasEncontradas');

        horariosFiltrados = horariosFiltrados.where((h) {
          if (h.horaInicio == null) return false;
          final hora = h.horaInicio!;
          // Extraer solo HH:MM (primeros 5 caracteres)
          final horaFormateada = hora.length >= 5 ? hora.substring(0, 5) : hora;
          final coincide = horaFormateada == _selectedHora;
          if (coincide) {
            print(
                '   ✅ Coincidencia: ${h.nombreMateria} a las $horaFormateada');
          }
          return coincide;
        }).toList();

        print('   Resultado: ${horariosFiltrados.length} horarios');
      }

      // FILTRO 2: Por Carrera (si está seleccionada)
      if (_selectedCarrera != null) {
        print('🎓 Filtrando por carrera ID: $_selectedCarrera');

        final carrerasEncontradas = horariosFiltrados
            .where((h) => h.grupo != null && h.grupo!['carrera_id'] != null)
            .map((h) => h.grupo!['carrera_id'])
            .toSet()
            .toList();
        print('   Carreras disponibles: $carrerasEncontradas');

        horariosFiltrados = horariosFiltrados.where((h) {
          final carreraId = h.grupo?['carrera_id'];
          final coincide = carreraId == _selectedCarrera;
          if (coincide) {
            print(
                '   ✅ Coincidencia: ${h.nombreMateria} de carrera $carreraId');
          }
          return coincide;
        }).toList();

        print('   Resultado: ${horariosFiltrados.length} horarios');
      }

      // FILTRO 3: Por Edificio (si está seleccionado)
      if (_selectedEdificio != null) {
        print('🏢 Filtrando por edificio ID: $_selectedEdificio');

        final edificiosEncontrados = horariosFiltrados
            .where((h) => h.grupo?['aula']?['edificio_id'] != null)
            .map((h) => h.grupo!['aula']['edificio_id'])
            .toSet()
            .toList();
        print('   Edificios disponibles: $edificiosEncontrados');

        horariosFiltrados = horariosFiltrados.where((h) {
          final edificioId = h.grupo?['aula']?['edificio_id'];
          final coincide = edificioId == _selectedEdificio;
          if (coincide) {
            print(
                '   ✅ Coincidencia: ${h.nombreMateria} en edificio $edificioId');
          }
          return coincide;
        }).toList();

        print('   Resultado: ${horariosFiltrados.length} horarios');
      }

      // Cargar asistencias existentes para la fecha seleccionada
      _asistenciasMap.clear();
      for (var horario in horariosFiltrados) {
        if (horario.id != null) {
          try {
            final asistencias = await _asistenciaService.getAsistenciasChecador(
              horarioId: horario.id,
              fecha: _selectedDate,
            );
            if (asistencias.isNotEmpty) {
              _asistenciasMap[horario.id!] = asistencias.first.asistencia.value;
            }
          } catch (e) {
            print('Error al cargar asistencia para horario ${horario.id}: $e');
          }
        }
      }

      setState(() {
        _horarios = horariosFiltrados;
        _isLoading = false;
      });

      print(
          '✅ RESULTADO FINAL: ${horariosFiltrados.length} horarios mostrados');
      print('═══════════════════════════════════════════════════\n');
    } catch (e) {
      print('❌ ERROR: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar horarios: $e')),
        );
      }
    }
  }

  // Handlers de filtros
  void _onHoraChange(String? hora) {
    print('🔧 Cambio de hora seleccionada: $hora');
    setState(() {
      _selectedHora = hora;
      // Resetear filtros posteriores
      _selectedCarrera = null;
      _selectedEdificio = null;
    });
    _loadHorarios();
  }

  void _onCarreraChange(int? carreraId) {
    setState(() {
      _selectedCarrera = carreraId;
      // Resetear filtro posterior
      _selectedEdificio = null;
    });
    _loadHorarios();
  }

  void _onEdificioChange(int? edificioId) {
    setState(() {
      _selectedEdificio = edificioId;
    });
    _loadHorarios();
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
      List<AsistenciaChecador> asistencias = [];
      try {
        asistencias = await _asistenciaService.getAsistenciasChecador(
          horarioId: horario.id,
          fecha: _selectedDate,
        );
      } catch (e) {
        print('Error al consultar asistencias previas: $e');
        asistencias = [];
      }

      if (asistencias.isNotEmpty && asistencias.first.id != null) {
        // Actualizar asistencia existente
        await _asistenciaService.updateAsistenciaChecador(
          asistencias.first.id!,
          tipo,
        );
      } else {
        // Crear nueva asistencia
        final asistencia = AsistenciaChecador(
          horarioId: horario.id,
          fecha: _selectedDate,
          asistencia: tipo,
          checadorId: user!.id!,
        );

        await _asistenciaService.createAsistenciaChecador(asistencia);
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
        // Card de fecha actual y filtros
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha actual (solo lectura)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // FILTROS
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // FILTRO 1: Hora
                DropdownButtonFormField<String>(
                  initialValue: _selectedHora,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las horas'),
                    ),
                    ..._horasDisponibles.map((hora) {
                      return DropdownMenuItem<String>(
                        value: hora,
                        child: Text(hora),
                      );
                    }),
                  ],
                  onChanged: _onHoraChange,
                ),

                const SizedBox(height: 12),

                // FILTRO 2: Carrera (habilitado solo si hay hora seleccionada o si no)
                DropdownButtonFormField<int>(
                  initialValue: _selectedCarrera,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todas las carreras'),
                    ),
                    ..._carreras.map((carrera) {
                      return DropdownMenuItem<int>(
                        value: carrera.id,
                        child: Text(carrera.nombre),
                      );
                    }),
                  ],
                  onChanged: _onCarreraChange,
                ),

                const SizedBox(height: 12),

                // FILTRO 3: Edificio
                DropdownButtonFormField<int>(
                  initialValue: _selectedEdificio,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todos los edificios'),
                    ),
                    ..._edificios.map((edificio) {
                      return DropdownMenuItem<int>(
                        value: edificio['id'] as int?,
                        child: Text(
                            edificio['nombre']?.toString() ?? 'Sin nombre'),
                      );
                    }),
                  ],
                  onChanged: _onEdificioChange,
                ),

                // Botón para limpiar filtros
                if (_selectedHora != null ||
                    _selectedCarrera != null ||
                    _selectedEdificio != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedHora = null;
                          _selectedCarrera = null;
                          _selectedEdificio = null;
                        });
                        _loadHorarios();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar filtros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Lista de horarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _diaActual.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay clases los fines de semana',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seleccione un día entre semana',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_selectedHora == null &&
                          _selectedCarrera == null &&
                          _selectedEdificio == null)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Seleccione al menos un filtro',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hora, Carrera o Edificio',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _horarios.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron horarios',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'con los filtros seleccionados',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadHorarios,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
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
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header con ícono y info
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: const Icon(Icons.school,
                                                    color: Colors.blue),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Profesor: ${horario.nombreMaestro}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Grupo: ${horario.nombreGrupo}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Aula: ${horario.nombreAula} - ${horario.nombreEdificio}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Hora: ${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                                                      style: TextStyle(
                                                        fontSize: 13,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getColorForAsistencia(
                                                        asistenciaActual)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getIconForAsistencia(
                                                        asistenciaActual),
                                                    size: 16,
                                                    color:
                                                        _getColorForAsistencia(
                                                            asistenciaActual),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Estado: $asistenciaActual',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          _getColorForAsistencia(
                                                              asistenciaActual),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: 12),

                                          // Botones de asistencia
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
