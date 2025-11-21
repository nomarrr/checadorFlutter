import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/horario_service.dart';
import '../../services/asistencia_service.dart';
import '../../models/horario.dart';
import '../../models/asistencia.dart';

class ChecadorControlScreen extends StatefulWidget {
  const ChecadorControlScreen({super.key});

  @override
  State<ChecadorControlScreen> createState() => _ChecadorControlScreenState();
}

class _ChecadorControlScreenState extends State<ChecadorControlScreen> {
  final HorarioService _horarioService = HorarioService();
  final AsistenciaService _asistenciaService = AsistenciaService();
  List<HorarioMaestro> _horarios = [];
  bool _isLoading = true;
  String _selectedDate = '';

  void refresh() {
    _loadHorarios();
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().split('T')[0];
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final horarios = await _horarioService.getAll();
      setState(() {
        _horarios = horarios;
        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _registrarAsistencia(
      HorarioMaestro horario, TipoAsistencia tipo) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user?.id == null) {
        throw Exception('Usuario no autenticado');
      }

      final asistencia = AsistenciaChecador(
        horarioId: horario.id,
        fecha: _selectedDate,
        asistencia: tipo,
        checadorId: user!.id!,
      );

      await _asistenciaService.createAsistenciaChecador(asistencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asistencia registrada: ${tipo.value}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha de asistencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDate,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ],
              ),
            ),
          ),
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
                              'No hay horarios disponibles',
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                horario.nombreMateria,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Grupo: ${horario.nombreGrupo}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                'Hora: ${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildAsistenciaButton(
                                          'Presente',
                                          Colors.green,
                                          TipoAsistencia.presente,
                                          horario,
                                        ),
                                        _buildAsistenciaButton(
                                          'Falta',
                                          Colors.red,
                                          TipoAsistencia.falta,
                                          horario,
                                        ),
                                        _buildAsistenciaButton(
                                          'Retardo',
                                          Colors.orange,
                                          TipoAsistencia.retardado,
                                          horario,
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
    TipoAsistencia tipo,
    HorarioMaestro horario,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _registrarAsistencia(horario, tipo),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

