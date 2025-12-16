import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final UsuarioService _usuarioService = UsuarioService();

  List<Usuario> usuarios = [];
  List<Usuario> usuariosFiltrados = [];

  // Controladores del formulario
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numeroCuentaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedRole;
  Usuario? _selectedUser;
  bool _isEditing = false;
  bool _showForm = false;

  bool _loading = false;
  String? _error;
  String? _success;

  final List<String> roles = [
    'Alumno',
    'Jefe de Grupo',
    'Checador',
    'Profesor',
    'Administrador'
  ];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _searchController.addListener(_filterUsuarios);
  }

  Future<void> _loadUsuarios() async {
    setState(() => _loading = true);
    try {
      final usuarios = await _usuarioService.getAll();
      setState(() {
        this.usuarios = usuarios;
        usuariosFiltrados = [...usuarios];
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar los usuarios');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterUsuarios() {
    final term = _searchController.text.toLowerCase();
    setState(() {
      if (term.isEmpty) {
        usuariosFiltrados = [...usuarios];
      } else {
        usuariosFiltrados = usuarios.where((u) {
          return u.name.toLowerCase().contains(term) ||
              (u.email?.toLowerCase().contains(term) ?? false) ||
              (u.numeroCuenta?.contains(term) ?? false);
        }).toList();
      }
    });
  }

  void _openForm({Usuario? usuario}) {
    if (usuario != null) {
      _isEditing = true;
      _selectedUser = usuario;
      _nameController.text = usuario.name;
      _emailController.text = usuario.email ?? '';
      _selectedRole = usuario.role ?? 'Alumno';
      _numeroCuentaController.text = usuario.numeroCuenta ?? '';
      _passwordController.clear();
    } else {
      _isEditing = false;
      _selectedUser = null;
      _clearForm();
    }
    setState(() => _showForm = true);
  }

  void _closeForm() {
    setState(() => _showForm = false);
    _clearForm();
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _numeroCuentaController.clear();
    _selectedRole = 'Alumno';
    _selectedUser = null;
  }

  Future<void> _saveUsuario() async {
    // Validaciones
    if (_nameController.text.trim().isEmpty) {
      _showMessage('El nombre es requerido', isError: true);
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showMessage('El email es requerido', isError: true);
      return;
    }

    if (!_isEditing && _passwordController.text.isEmpty) {
      _showMessage('La contraseña es requerida para nuevos usuarios',
          isError: true);
      return;
    }

    if (_numeroCuentaController.text.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(_numeroCuentaController.text)) {
      _showMessage('El número de cuenta debe contener solo números',
          isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final usuarioData = Usuario(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        role: _selectedRole,
        numeroCuenta: _numeroCuentaController.text.isNotEmpty
            ? _numeroCuentaController.text
            : null,
      );

      if (_isEditing && _selectedUser != null) {
        await _usuarioService.update(_selectedUser!.id!, usuarioData);
        _showMessage('Usuario actualizado correctamente');
      } else {
        await _usuarioService.create(usuarioData);
        _showMessage('Usuario creado correctamente');
      }

      await _loadUsuarios();
      _closeForm();
    } catch (e) {
      final errorMsg = _isEditing
          ? 'Error al actualizar el usuario'
          : 'Error al crear el usuario';
      _showMessage(errorMsg, isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUsuario(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de eliminar al usuario "${usuario.name}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _usuarioService.delete(usuario.id!);
      _showMessage('Usuario eliminado correctamente');
      await _loadUsuarios();
    } catch (e) {
      _showMessage('Error al eliminar el usuario', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      if (isError) {
        _error = message;
        _success = null;
      } else {
        _success = message;
        _error = null;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _numeroCuentaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Alertas
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _error = null),
                        ),
                      ],
                    ),
                  ),
                if (_success != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _success!,
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _success = null),
                        ),
                      ],
                    ),
                  ),
                // Barra de búsqueda y botón nuevo usuario
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuario',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Nuevo Usuario'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tabla de usuarios
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usuarios Registrados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (usuariosFiltrados.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No hay usuarios registrados'),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Rol')),
                                DataColumn(label: Text('Número de Cuenta')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: usuariosFiltrados
                                  .map(
                                    (usuario) => DataRow(
                                      cells: [
                                        DataCell(Text(usuario.name)),
                                        DataCell(Text(usuario.email ?? '-')),
                                        DataCell(Text(usuario.role ?? '-')),
                                        DataCell(
                                            Text(usuario.numeroCuenta ?? '-')),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () =>
                                                    _openForm(usuario: usuario),
                                                tooltip: 'Editar usuario',
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _deleteUsuario(usuario),
                                                tooltip: 'Eliminar usuario',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Modal del formulario
          if (_showForm)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Dialog(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isEditing ? Icons.edit : Icons.person_add,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _closeForm,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Rol',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                            ),
                            items: roles
                                .map((r) =>
                                    DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedRole = value),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _numeroCuentaController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Cuenta',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              hintText: 'Solo números',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              helperText: _isEditing
                                  ? 'Dejar en blanco para mantener la actual'
                                  : 'Requerida para nuevos usuarios',
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _closeForm,
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _loading ? null : _saveUsuario,
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
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
        ],
      ),
    );
  }
}
