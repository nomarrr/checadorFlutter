import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'checador_drawer.dart';
import 'checador_control_screen.dart';

class ChecadorLayoutScreen extends StatefulWidget {
  final String currentRoute;

  const ChecadorLayoutScreen({
    super.key,
    required this.currentRoute,
  });

  @override
  State<ChecadorLayoutScreen> createState() => _ChecadorLayoutScreenState();
}

class _ChecadorLayoutScreenState extends State<ChecadorLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _refreshKey = 0;

  final List<String> _routes = [
    '/checador/control',
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(ChecadorLayoutScreen oldWidget) {
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
    if (widget.currentRoute.contains('/control')) {
      return 'Control de Asistencia';
    }
    return 'Checador';
  }

  Widget _buildContent() {
    if (widget.currentRoute.contains('/control')) {
      return ChecadorControlScreen(key: ValueKey(_refreshKey));
    }
    return ChecadorControlScreen(key: ValueKey(_refreshKey));
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
      drawer: ChecadorDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _buildContent(),
    );
  }
}
