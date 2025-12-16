import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'admin_drawer.dart';
import 'admin_dashboard_screen.dart';
import 'admin_gestion_horarios_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_grupos_screen.dart';
import 'admin_materias_screen.dart';
import 'admin_carreras_screen.dart';
import 'admin_edificios_screen.dart';
import 'admin_aulas_screen.dart';
import 'admin_consulta_asistencias_screen.dart';

class AdminLayoutScreen extends StatefulWidget {
  final String currentRoute;

  const AdminLayoutScreen({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _routes = [
    '/admin/dashboard',
    '/admin/horarios',
    '/admin/grupos',
    '/admin/usuarios',
    '/admin/materias',
    '/admin/carreras',
    '/admin/edificios',
    '/admin/aulas',
    '/admin/consulta-asistencias',
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(AdminLayoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index =
        _routes.indexWhere((route) => widget.currentRoute.contains(route));
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemSelected(int index) {
    if (index < _routes.length) {
      // Cerrar el drawer
      _scaffoldKey.currentState?.closeDrawer();
      // Navegar a la ruta
      context.go(_routes[index]);
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getAppBarTitle() {
    if (widget.currentRoute.contains('/dashboard')) {
      return 'Dashboard';
    } else if (widget.currentRoute.contains('/horarios')) {
      return 'Horarios';
    } else if (widget.currentRoute.contains('/usuarios')) {
      return 'Usuarios';
    } else if (widget.currentRoute.contains('/grupos')) {
      return 'Grupos';
    } else if (widget.currentRoute.contains('/materias')) {
      return 'Materias';
    } else if (widget.currentRoute.contains('/carreras')) {
      return 'Carreras';
    } else if (widget.currentRoute.contains('/edificios')) {
      return 'Edificios';
    } else if (widget.currentRoute.contains('/aulas')) {
      return 'Aulas';
    } else if (widget.currentRoute.contains('/consulta-asistencias')) {
      return 'Consulta de Asistencias';
    }
    return 'Administrador';
  }

  Widget _buildContent() {
    if (widget.currentRoute.contains('/dashboard')) {
      return const AdminDashboardScreen();
    } else if (widget.currentRoute.contains('/horarios')) {
      return const AdminGestionHorariosScreen();
    } else if (widget.currentRoute.contains('/usuarios')) {
      return const AdminUsuariosScreen();
    } else if (widget.currentRoute.contains('/grupos')) {
      return const AdminGruposScreen();
    } else if (widget.currentRoute.contains('/materias')) {
      return const AdminMateriasScreen();
    } else if (widget.currentRoute.contains('/carreras')) {
      return const AdminCarrerasScreen();
    } else if (widget.currentRoute.contains('/edificios')) {
      return const AdminEdificiosScreen();
    } else if (widget.currentRoute.contains('/aulas')) {
      return const AdminAulasScreen();
    } else if (widget.currentRoute.contains('/consulta-asistencias')) {
      return const AdminConsultaAsistenciasScreen();
    }
    return const AdminDashboardScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F3F8),
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: AdminDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _buildContent(),
    );
  }
}
