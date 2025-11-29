import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastPausedTime;
  static const Duration _inactivityTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App pasa a segundo plano o se minimiza
        if (authProvider.isAuthenticated) {
          _lastPausedTime = DateTime.now();
          print('App pausada a las: $_lastPausedTime');
        }
        break;
        
      case AppLifecycleState.resumed:
        // App vuelve a primer plano
        if (_lastPausedTime != null && authProvider.isAuthenticated) {
          final inactiveTime = DateTime.now().difference(_lastPausedTime!);
          print('App resumida. Tiempo inactivo: ${inactiveTime.inMinutes} minutos');
          
          if (inactiveTime >= _inactivityTimeout) {
            // Cerrar sesión automáticamente
            print('Sesión cerrada por inactividad');
            authProvider.logout().then((_) {
              if (mounted) {
                // Navegar al login
                context.go('/login');
                
                // Mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada por inactividad'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
          _lastPausedTime = null;
        }
        break;
        
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        title: 'Sistema Checador',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}

