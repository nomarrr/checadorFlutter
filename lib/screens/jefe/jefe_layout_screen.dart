import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'jefe_drawer.dart';
import 'jefe_horario_screen.dart';

class JefeLayoutScreen extends StatefulWidget {
  final String currentRoute;
  
  const JefeLayoutScreen({
    super.key,
    required this.currentRoute,
  });

  @override
  State<JefeLayoutScreen> createState() => _JefeLayoutScreenState();
}

class _JefeLayoutScreenState extends State<JefeLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _refreshKey = 0;

  final List<String> _routes = [
    '/jefe/horario',
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(JefeLayoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _routes.indexWhere((route) => widget.currentRoute.contains(route));
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
      return 'Horarios - Jefe de Grupo';
    }
    return 'Jefe de Grupo';
  }

  Widget _buildContent() {
    if (widget.currentRoute.contains('/horario')) {
      return JefeHorarioScreen(key: ValueKey(_refreshKey));
    }
    return JefeHorarioScreen(key: ValueKey(_refreshKey));
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
      drawer: JefeDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _buildContent(),
    );
  }
}

