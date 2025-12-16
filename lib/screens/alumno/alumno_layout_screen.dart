import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'alumno_drawer.dart';
import 'alumno_horario_screen.dart';

class AlumnoLayoutScreen extends StatefulWidget {
  final String currentRoute;

  const AlumnoLayoutScreen({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AlumnoLayoutScreen> createState() => _AlumnoLayoutScreenState();
}

class _AlumnoLayoutScreenState extends State<AlumnoLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _refreshKey = 0;

  final List<String> _routes = [
    '/alumno/horario',
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(AlumnoLayoutScreen oldWidget) {
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
      _scaffoldKey.currentState?.closeDrawer();
      context.go(_routes[index]);
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _getAppBarTitle() {
    if (widget.currentRoute.contains('/horario')) {
      return 'Mi Horario';
    }
    return 'Alumno';
  }

  Widget _buildContent() {
    if (widget.currentRoute.contains('/horario')) {
      return AlumnoHorarioScreen(
        key: ValueKey(_refreshKey),
      );
    }
    return AlumnoHorarioScreen(
      key: ValueKey(_refreshKey),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _refreshKey++;
              });
            },
          ),
        ],
      ),
      drawer: AlumnoDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _buildContent(),
    );
  }
}
