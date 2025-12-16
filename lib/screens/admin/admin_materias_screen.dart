import 'package:flutter/material.dart';
import '../../services/materia_service.dart';
import '../../services/carrera_service.dart';
import '../../models/materia.dart';
import '../../models/carrera.dart';

class AdminMateriasScreen extends StatefulWidget {
  const AdminMateriasScreen({super.key});

  @override
  State<AdminMateriasScreen> createState() => _AdminMateriasScreenState();
}

class _AdminMateriasScreenState extends State<AdminMateriasScreen> {
  final MateriaService _materiaService = MateriaService();
  final CarreraService _carreraService = CarreraService();
  final TextEditingController _nombreController = TextEditingController();

  List<Materia> _materias = [];
  List<Carrera> _carreras = [];
  bool _loading = false;
  Materia? _materiaEditando;
  int? _selectedCarreraId;
  int? _selectedSemestre;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMaterias(),
      _loadCarreras(),
    ]);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterias() async {
    setState(() => _loading = true);
    try {
      final materias = await _materiaService.getAll();
      if (mounted) {
        setState(() {
          _materias = materias;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar materias: $e')),
        );
      }
    }
  }

  Future<void> _loadCarreras() async {
    try {
      final carreras = await _carreraService.getAll();
      if (mounted) {
        setState(() {
          _carreras = carreras;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar carreras: $e')),
        );
      }
    }
  }

  void _showForm([Materia? materia]) {
    _materiaEditando = materia;
    _nombreController.text = materia?.name ?? '';
    _selectedCarreraId = materia?.carreraId;
    _selectedSemestre = materia?.semestre;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(materia == null ? 'Nueva Materia' : 'Editar Materia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Materia',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedCarreraId,
                  decoration: const InputDecoration(
                    labelText: 'Carrera',
                    border: OutlineInputBorder(),
                  ),
                  items: _carreras.map((carrera) {
                    return DropdownMenuItem<int?>(
                      value: carrera.id,
                      child: Text(carrera.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCarreraId = value;
                      _selectedSemestre = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedCarreraId != null)
                  DropdownButtonFormField<int?>(
                    initialValue: _selectedSemestre,
                    decoration: const InputDecoration(
                      labelText: 'Semestre',
                      border: OutlineInputBorder(),
                    ),
                    items: _buildSemestreItems(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSemestre = value;
                      });
                    },
                  )
                else
                  const Text(
                    'Selecciona una carrera primero',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _guardarMateria();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<int?>> _buildSemestreItems() {
    final carrera = _carreras.firstWhere(
      (c) => c.id == _selectedCarreraId,
      orElse: () => Carrera(
        id: 0,
        nombre: '',
        semestres: 0,
      ),
    );

    final semestres = carrera.semestres ?? 0;
    return List.generate(
      semestres,
      (index) => DropdownMenuItem<int?>(
        value: index + 1,
        child: Text('${index + 1}'),
      ),
    );
  }

  Future<void> _guardarMateria() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es requerido')),
        );
      }
      return;
    }

    if (_selectedCarreraId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La carrera es requerida')),
        );
      }
      return;
    }

    if (_selectedSemestre == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El semestre es requerido')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      if (_materiaEditando == null) {
        await _materiaService.create(
          nombre,
          _selectedSemestre!,
          _selectedCarreraId,
        );
      } else {
        await _materiaService.update(
          _materiaEditando!.id!,
          nombre,
          _selectedSemestre!,
          _selectedCarreraId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Materia ${_materiaEditando == null ? "creada" : "actualizada"} correctamente')),
        );
        _loadMaterias();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _eliminarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar la materia "${materia.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && materia.id != null) {
      setState(() => _loading = true);
      try {
        await _materiaService.delete(materia.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materia eliminada correctamente')),
          );
          _loadMaterias();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Gestión de Materias',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Materia'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _materias.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay materias registradas',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.blue.shade50),
                            columns: const [
                              DataColumn(
                                  label: Text('Nombre',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Carrera',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Semestre',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Acciones',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: _materias.map((materia) {
                              final carrera = _carreras.firstWhere(
                                (c) => c.id == materia.carreraId,
                                orElse: () => Carrera(
                                  id: 0,
                                  nombre: 'Sin carrera',
                                ),
                              );
                              return DataRow(cells: [
                                DataCell(Text(materia.name)),
                                DataCell(Text(carrera.nombre)),
                                DataCell(Text(
                                    materia.semestre?.toString() ?? 'N/A')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showForm(materia),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _eliminarMateria(materia),
                                        tooltip: 'Eliminar',
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
