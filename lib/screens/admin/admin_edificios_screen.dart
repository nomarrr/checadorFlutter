import 'package:flutter/material.dart';
import '../../services/edificio_service.dart';

class AdminEdificiosScreen extends StatefulWidget {
  const AdminEdificiosScreen({super.key});

  @override
  State<AdminEdificiosScreen> createState() => _AdminEdificiosScreenState();
}

class _AdminEdificiosScreenState extends State<AdminEdificiosScreen> {
  final EdificioService _edificioService = EdificioService();
  final TextEditingController _nombreController = TextEditingController();
  
  List<dynamic> _edificios = [];
  bool _loading = false;
  dynamic _edificioEditando;

  @override
  void initState() {
    super.initState();
    _loadEdificios();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadEdificios() async {
    setState(() => _loading = true);
    try {
      final edificios = await _edificioService.getAll();
      if (mounted) {
        setState(() {
          _edificios = edificios;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar edificios: $e')),
        );
      }
    }
  }

  void _showForm([dynamic edificio]) {
    _edificioEditando = edificio;
    _nombreController.text = edificio?['nombre'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(edificio == null ? 'Nuevo Edificio' : 'Editar Edificio'),
        content: TextField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Edificio',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarEdificio();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarEdificio() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_edificioEditando == null) {
        await _edificioService.create(nombre);
      } else {
        await _edificioService.update(_edificioEditando['id'], nombre);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edificio ${_edificioEditando == null ? "creado" : "actualizado"} correctamente')),
        );
        _loadEdificios();
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

  Future<void> _eliminarEdificio(dynamic edificio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar el edificio "${edificio['nombre']}"?'),
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

    if (confirmar == true && edificio['id'] != null) {
      setState(() => _loading = true);
      try {
        await _edificioService.delete(edificio['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edificio eliminado correctamente')),
          );
          _loadEdificios();
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
                  'Gestión de Edificios',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Edificio'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _edificios.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay edificios registrados',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                            columns: const [
                              DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _edificios.map((edificio) {
                              return DataRow(cells: [
                                DataCell(Text(edificio['nombre'])),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showForm(edificio),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarEdificio(edificio),
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

