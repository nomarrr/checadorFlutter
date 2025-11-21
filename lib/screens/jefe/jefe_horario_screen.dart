import 'package:flutter/material.dart';
import '../../services/horario_service.dart';
import '../../models/horario.dart';

class JefeHorarioScreen extends StatefulWidget {
  const JefeHorarioScreen({super.key});

  @override
  State<JefeHorarioScreen> createState() => _JefeHorarioScreenState();
}

class _JefeHorarioScreenState extends State<JefeHorarioScreen> {
  final HorarioService _horarioService = HorarioService();
  List<HorarioMaestro> _horarios = [];
  bool _isLoading = true;

  void refresh() {
    _loadHorarios();
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _horarios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _horarios.length,
                    itemBuilder: (context, index) {
                      final horario = _horarios[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.group, color: Colors.orange),
                          ),
                          title: Text(
                            horario.nombreMateria,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Profesor: ${horario.nombreMaestro}'),
                              Text('Grupo: ${horario.nombreGrupo}'),
                              Text('Aula: ${horario.nombreAula}'),
                              Text('Día: ${horario.dias ?? "N/A"}'),
                              Text(
                                'Hora: ${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              // TODO: Navegar a asistencias del grupo
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Próximamente: Ver Asistencias del Grupo')),
                              );
                            },
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                );
  }
}

