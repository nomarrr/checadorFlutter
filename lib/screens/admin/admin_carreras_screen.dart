import 'package:flutter/material.dart';
import '../../services/carrera_service.dart';
import '../../models/carrera.dart';

class AdminCarrerasScreen extends StatefulWidget {
  const AdminCarrerasScreen({super.key});

  @override
  State<AdminCarrerasScreen> createState() => _AdminCarrerasScreenState();
}

class _AdminCarrerasScreenState extends State<AdminCarrerasScreen> {
  final CarreraService _carreraService = CarreraService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _semestresController = TextEditingController();

  List<Carrera> _carreras = [];
  bool _loading = false;
  Carrera? _carreraEditando;

  @override
  void initState() {
    super.initState();
    _loadCarreras();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _semestresController.dispose();
    super.dispose();
  }

  Future<void> _loadCarreras() async {
    setState(() => _loading = true);
    try {
      final carreras = await _carreraService.getAll();
      if (mounted) {
        setState(() {
          _carreras = carreras;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar carreras: $e')),
        );
      }
    }
  }

  void _showForm([Carrera? carrera]) {
    _carreraEditando = carrera;
    _nombreController.text = carrera?.nombre ?? '';
    _semestresController.text = carrera?.semestres?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(carrera == null ? 'Nueva Carrera' : 'Editar Carrera'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Carrera',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _semestresController,
                decoration: const InputDecoration(
                  labelText: 'Duración (Semestres)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 4, 8, 9, etc.',
                ),
                keyboardType: TextInputType.number,
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
              _guardarCarrera();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCarrera() async {
    final nombre = _nombreController.text.trim();
    final semestresStr = _semestresController.text.trim();

    if (nombre.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre es requerido')),
        );
      }
      return;
    }

    if (semestresStr.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La duración en semestres es requerida')),
        );
      }
      return;
    }

    final semestres = int.tryParse(semestresStr);
    if (semestres == null || semestres < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La duración debe ser un número positivo')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      if (_carreraEditando == null) {
        await _carreraService.create(nombre, semestres);
      } else {
        await _carreraService.update(_carreraEditando!.id!, nombre, semestres);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Carrera ${_carreraEditando == null ? "creada" : "actualizada"} correctamente')),
        );
        _loadCarreras();
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

  Future<void> _eliminarCarrera(Carrera carrera) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content:
            Text('¿Está seguro de eliminar la carrera "${carrera.nombre}"?'),
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

    if (confirmar == true && carrera.id != null) {
      setState(() => _loading = true);
      try {
        await _carreraService.delete(carrera.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Carrera eliminada correctamente')),
          );
          _loadCarreras();
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
                  'Gestión de Carreras',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Carrera'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _carreras.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay carreras registradas',
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
                                  label: Text('Duración (Semestres)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Acciones',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: _carreras.map((carrera) {
                              return DataRow(cells: [
                                DataCell(Text(carrera.nombre)),
                                DataCell(Text(
                                    carrera.semestres?.toString() ?? 'N/A')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showForm(carrera),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _eliminarCarrera(carrera),
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
