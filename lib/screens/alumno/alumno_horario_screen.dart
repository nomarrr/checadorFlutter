import 'package:flutter/material.dart';
import '../../services/horario_service.dart';
import '../../models/horario.dart';

class AlumnoHorarioScreen extends StatefulWidget {
  const AlumnoHorarioScreen({super.key});

  @override
  State<AlumnoHorarioScreen> createState() => _AlumnoHorarioScreenState();
}

class _AlumnoHorarioScreenState extends State<AlumnoHorarioScreen> {
  final HorarioService _horarioService = HorarioService();
  List<HorarioMaestro> _horarios = [];
  List<HorarioMaestro> _horariosFiltrados = [];
  bool _isLoading = true;
  String _filtroMateria = '';

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
        _horariosFiltrados = horarios;
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

  void _filtrarHorarios(String query) {
    setState(() {
      _filtroMateria = query;
      if (query.isEmpty) {
        _horariosFiltrados = _horarios;
      } else {
        _horariosFiltrados = _horarios.where((h) {
          return h.nombreMateria.toLowerCase().contains(query.toLowerCase()) ||
              h.nombreMaestro.toLowerCase().contains(query.toLowerCase()) ||
              h.nombreGrupo.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Map<String, List<HorarioMaestro>> _agruparPorDia() {
    final Map<String, List<HorarioMaestro>> agrupados = {
      'Lunes': [],
      'Martes': [],
      'Miércoles': [],
      'Jueves': [],
      'Viernes': [],
    };

    for (var horario in _horariosFiltrados) {
      final dias = horario.dias?.toLowerCase() ?? '';
      
      if (dias.contains('lunes')) agrupados['Lunes']!.add(horario);
      if (dias.contains('martes')) agrupados['Martes']!.add(horario);
      if (dias.contains('miércoles') || dias.contains('miercoles')) {
        agrupados['Miércoles']!.add(horario);
      }
      if (dias.contains('jueves')) agrupados['Jueves']!.add(horario);
      if (dias.contains('viernes')) agrupados['Viernes']!.add(horario);
    }

    // Ordenar por hora de inicio
    agrupados.forEach((key, value) {
      value.sort((a, b) {
        final horaA = a.horaInicio ?? '';
        final horaB = b.horaInicio ?? '';
        return horaA.compareTo(horaB);
      });
    });

    return agrupados;
  }

  @override
  Widget build(BuildContext context) {
    final horariosPorDia = _agruparPorDia();
    
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _filtrarHorarios,
            decoration: InputDecoration(
              hintText: 'Buscar materia, maestro o grupo...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),
        // Información del total
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_horariosFiltrados.length} horarios disponibles',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadHorarios,
                tooltip: 'Actualizar',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista de horarios
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _horariosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _filtroMateria.isEmpty
                                ? 'No hay horarios disponibles'
                                : 'No se encontraron resultados',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_filtroMateria.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _filtrarHorarios(''),
                              child: const Text('Limpiar búsqueda'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHorarios,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (var dia in horariosPorDia.keys)
                            if (horariosPorDia[dia]!.isNotEmpty) ...[
                              _buildDiaSection(dia, horariosPorDia[dia]!),
                              const SizedBox(height: 16),
                            ],
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDiaSection(String dia, List<HorarioMaestro> horarios) {
    final colorMap = {
      'Lunes': Colors.blue,
      'Martes': Colors.green,
      'Miércoles': Colors.orange,
      'Jueves': Colors.purple,
      'Viernes': Colors.teal,
    };

    final color = colorMap[dia] ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del día
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                dia,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${horarios.length} clase${horarios.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Horarios del día
        ...horarios.map((horario) => _buildHorarioCard(horario, color)),
      ],
    );
  }

  Widget _buildHorarioCard(HorarioMaestro horario, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hora y materia
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${horario.horaInicio ?? "N/A"} - ${horario.horaFin ?? "N/A"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    horario.nombreMateria,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Información adicional
            _buildInfoRow(Icons.person, 'Profesor', horario.nombreMaestro),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.group, 'Grupo', horario.nombreGrupo),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.room, 'Aula', 
                '${horario.nombreAula} - ${horario.nombreEdificio}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

