import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/horario_service.dart';
import '../../models/horario.dart';

class MaestroDashboardScreen extends StatefulWidget {
  const MaestroDashboardScreen({super.key});
  
  @override
  State<MaestroDashboardScreen> createState() => _MaestroDashboardScreenState();
}

class _MaestroDashboardScreenState extends State<MaestroDashboardScreen> {
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user?.id != null) {
        final horarios = await _horarioService.getByMaestro(user!.id!);
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
          SnackBar(content: Text('Error al cargar horarios: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido, ${user?.name ?? "Maestro"}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total de horarios: ${_horarios.length}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _horarios.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes horarios asignados',
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
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: const Icon(Icons.class_,
                                        color: Colors.green),
                                  ),
                                  title: Text(
                                    horario.nombreMateria,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
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
                                      // TODO: Navegar a detalles o asistencias
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Próximamente: Gestión de Asistencias')),
                                      );
                                    },
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

