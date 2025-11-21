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

class AdminGestionHorariosScreen extends StatefulWidget {
  const AdminGestionHorariosScreen({super.key});

  @override
  State<AdminGestionHorariosScreen> createState() => _AdminGestionHorariosScreenState();
}

class _AdminGestionHorariosScreenState extends State<AdminGestionHorariosScreen> {
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

  bool _loading = false;
  bool _showForm = false;
  bool _isEditing = false;
  HorarioMaestro? _selectedHorario;

  // Formulario
  String? _selectedMaestro;
  String? _selectedMateria;
  String? _selectedGrupo;
  List<String> _selectedDias = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String _ampmInicio = 'AM';
  String _ampmFin = 'AM';

  // Filtros
  String? _filtroCarrera;
  String? _filtroGrupo;

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _usuarioService.getMaestros(),
        _materiaService.getAll(),
        _grupoService.getAll(),
        _carreraService.getAll(),
        _horarioService.getAll(),
      ]);

      setState(() {
        _maestros = results[0] as List<Usuario>;
        _materias = results[1] as List<Materia>;
        _grupos = results[2] as List<Grupo>;
        _carreras = results[3] as List<Carrera>;
        _horarios = results[4] as List<HorarioMaestro>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<Grupo> get _gruposFiltrados {
    if (_filtroCarrera == null || _filtroCarrera!.isEmpty) {
      return _grupos;
    }
    return _grupos
        .where((g) => g.carreraId == int.parse(_filtroCarrera!))
        .toList();
  }

  List<HorarioMaestro> get _horariosFiltrados {
    if (_filtroGrupo == null || _filtroGrupo!.isEmpty) {
      return _horarios;
    }
    return _horarios
        .where((h) => h.grupoId == int.parse(_filtroGrupo!))
        .toList();
  }

  void _openForm([HorarioMaestro? horario]) {
    if (horario != null) {
      setState(() {
        _isEditing = true;
        _selectedHorario = horario;
        _selectedMaestro = horario.maestroId?.toString();
        _selectedMateria = horario.materiaId?.toString();
        _selectedGrupo = horario.grupoId?.toString();
        _selectedDias = horario.dias?.split(',').map((d) => d.trim()).toList() ?? [];
        
        if (horario.horaInicio != null) {
          final parts = horario.horaInicio!.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          _horaInicio = TimeOfDay(hour: hour, minute: minute);
          _ampmInicio = hour >= 12 ? 'PM' : 'AM';
        }
        
        if (horario.horaFin != null) {
          final parts = horario.horaFin!.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          _horaFin = TimeOfDay(hour: hour, minute: minute);
          _ampmFin = hour >= 12 ? 'PM' : 'AM';
        }
      });
    } else {
      _clearForm();
    }
    setState(() => _showForm = true);
  }

  void _clearForm() {
    setState(() {
      _isEditing = false;
      _selectedHorario = null;
      _selectedMaestro = null;
      _selectedMateria = null;
      _selectedGrupo = null;
      _selectedDias = [];
      _horaInicio = null;
      _horaFin = null;
      _ampmInicio = 'AM';
      _ampmFin = 'AM';
    });
  }

  void _closeForm() {
    setState(() => _showForm = false);
    _clearForm();
  }

  String _convertTo24Hour(TimeOfDay time, String ampm) {
    int hour = time.hour;
    if (ampm == 'PM' && hour != 12) {
      hour += 12;
    } else if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _crearHorario() async {
    if (_selectedMaestro == null ||
        _selectedMateria == null ||
        _selectedGrupo == null ||
        _selectedDias.isEmpty ||
        _horaInicio == null ||
        _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }

    final horaInicio24 = _convertTo24Hour(_horaInicio!, _ampmInicio);
    final horaFin24 = _convertTo24Hour(_horaFin!, _ampmFin);

    // Validar duración
    final inicioMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
    final finMinutos = _horaFin!.hour * 60 + _horaFin!.minute;
    final duracion = finMinutos - inicioMinutos;

    if (duracion <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La hora de fin debe ser mayor que la hora de inicio')),
      );
      return;
    }

    if (duracion < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La duración de la clase debe ser de al menos 50 minutos')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final horarioData = {
        'maestro_id': int.parse(_selectedMaestro!),
        'materia_id': int.parse(_selectedMateria!),
        'grupo_id': int.parse(_selectedGrupo!),
        'dias': _selectedDias.join(', '),
        'hora_inicio': '$horaInicio24:00',
        'hora_fin': '$horaFin24:00',
      };

      if (_isEditing && _selectedHorario?.id != null) {
        await _horarioService.update(_selectedHorario!.id!, horarioData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado correctamente')),
        );
      } else {
        await _horarioService.create(HorarioMaestro.fromJson(horarioData));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario creado correctamente')),
        );
      }

      await _loadData();
      _closeForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _eliminarHorario(HorarioMaestro horario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro de eliminar este horario?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && horario.id != null) {
      setState(() => _loading = true);
      try {
        await _horarioService.delete(horario.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario eliminado correctamente')),
        );
        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      } finally {
        setState(() => _loading = false);
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

  String _getEdificioNombre(int? id) {
    if (id == null) return 'N/A';
    final grupo = _grupos.firstWhere((g) => g.id == id, orElse: () => Grupo(name: 'N/A'));
    return grupo.nombreEdificio;
  }

  String _getAulaInfo(int? id) {
    if (id == null) return 'N/A';
    final grupo = _grupos.firstWhere((g) => g.id == id, orElse: () => Grupo(name: 'N/A'));
    return grupo.nombreAula;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros y botón nuevo
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filtros en columna para pantallas pequeñas
                  DropdownButtonFormField<String>(
                    value: _filtroCarrera,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Carrera',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las carreras')),
                      ..._carreras.map((c) => DropdownMenuItem(
                            value: c.id.toString(),
                            child: Text(c.nombre),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroCarrera = value;
                        _filtroGrupo = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _filtroGrupo,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Grupo',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos los grupos')),
                      ..._gruposFiltrados.map((g) => DropdownMenuItem(
                            value: g.id.toString(),
                            child: Text(g.name),
                          )),
                    ],
                    onChanged: _filtroCarrera == null
                        ? null
                        : (value) {
                            setState(() => _filtroGrupo = value);
                          },
                  ),
                  const SizedBox(height: 16),
                  // Botón nuevo horario
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Nuevo Horario'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tabla
              Card(
                child: _loading && _horarios.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _horariosFiltrados.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.schedule, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay horarios registrados',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 12,
                                columns: const [
                                  DataColumn(label: Text('Profesor', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Materia', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Edificio', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Aula', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Días', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Horario', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _horariosFiltrados.map((horario) {
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
                                          width: 100,
                                          child: Text(
                                            _getEdificioNombre(horario.grupoId),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
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
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _openForm(horario),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _eliminarHorario(horario),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
        // Modal de formulario
        if (_showForm)
          Container(
            color: Colors.black54,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxWidth: 600,
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_isEditing ? Icons.edit : Icons.add_circle,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditing ? 'Editar Horario' : 'Nuevo Horario',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _closeForm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Profesor
                        DropdownButtonFormField<String>(
                          value: _selectedMaestro,
                          decoration: const InputDecoration(
                            labelText: 'Profesor',
                            border: OutlineInputBorder(),
                          ),
                          items: _maestros
                              .map((m) => DropdownMenuItem(
                                    value: m.id.toString(),
                                    child: Text(m.name),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedMaestro = value),
                        ),
                        const SizedBox(height: 16),
                        // Materia
                        DropdownButtonFormField<String>(
                          value: _selectedMateria,
                          decoration: const InputDecoration(
                            labelText: 'Materia',
                            border: OutlineInputBorder(),
                          ),
                          items: _materias
                              .map((m) => DropdownMenuItem(
                                    value: m.id.toString(),
                                    child: Text(m.name),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedMateria = value),
                        ),
                        const SizedBox(height: 16),
                        // Grupo
                        DropdownButtonFormField<String>(
                          value: _selectedGrupo,
                          decoration: const InputDecoration(
                            labelText: 'Grupo',
                            border: OutlineInputBorder(),
                          ),
                          items: _grupos
                              .map((g) => DropdownMenuItem(
                                    value: g.id.toString(),
                                    child: Text(g.name),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedGrupo = value),
                        ),
                        const SizedBox(height: 16),
                        // Días
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Días de la semana',
                            border: OutlineInputBorder(),
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: _diasSemana.map((dia) {
                              final isSelected = _selectedDias.contains(dia);
                              return FilterChip(
                                label: Text(dia),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      if (!_selectedDias.contains(dia)) {
                                        _selectedDias.add(dia);
                                      }
                                    } else {
                                      _selectedDias.remove(dia);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Hora Inicio
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Hora Inicio'),
                                subtitle: Text(
                                  _horaInicio == null
                                      ? 'Seleccionar hora'
                                      : _horaInicio!.format(context),
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _horaInicio ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() => _horaInicio = time);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            DropdownButton<String>(
                              value: _ampmInicio,
                              items: const [
                                DropdownMenuItem(value: 'AM', child: Text('AM')),
                                DropdownMenuItem(value: 'PM', child: Text('PM')),
                              ],
                              onChanged: (value) => setState(() => _ampmInicio = value!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Hora Fin
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Hora Fin'),
                                subtitle: Text(
                                  _horaFin == null
                                      ? 'Seleccionar hora'
                                      : _horaFin!.format(context),
                                ),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _horaFin ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() => _horaFin = time);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            DropdownButton<String>(
                              value: _ampmFin,
                              items: const [
                                DropdownMenuItem(value: 'AM', child: Text('AM')),
                                DropdownMenuItem(value: 'PM', child: Text('PM')),
                              ],
                              onChanged: (value) => setState(() => _ampmFin = value!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'La clase debe durar al menos 50 minutos',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Botones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _closeForm,
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _loading ? null : _crearHorario,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isEditing ? 'Actualizar' : 'Crear'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
