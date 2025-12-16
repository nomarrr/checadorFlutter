import 'package:go_router/go_router.dart';
import '../screens/login/login_screen.dart';
import '../screens/admin/admin_layout_screen.dart';
import '../screens/alumno/alumno_layout_screen.dart';
import '../screens/maestro/maestro_layout_screen.dart';
import '../screens/jefe/jefe_layout_screen.dart';
import '../screens/checador/checador_layout_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  static final AuthService _authService = AuthService();

  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = await _authService.isAuthenticated();
      final isLoginPage = state.matchedLocation == '/login';

      // Si no está logueado y no está en login, redirigir a login
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }

      // Si está logueado y está en login, redirigir según rol
      if (isLoggedIn && isLoginPage) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          return getRouteByRole(user.role ?? '');
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Admin routes with layout
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/dashboard',
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/dashboard',
        ),
      ),
      GoRoute(
        path: '/admin/horarios',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/horarios',
        ),
      ),
      GoRoute(
        path: '/admin/grupos',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/grupos',
        ),
      ),
      GoRoute(
        path: '/admin/usuarios',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/usuarios',
        ),
      ),
      GoRoute(
        path: '/admin/materias',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/materias',
        ),
      ),
      GoRoute(
        path: '/admin/carreras',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/carreras',
        ),
      ),
      GoRoute(
        path: '/admin/edificios',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/edificios',
        ),
      ),
      GoRoute(
        path: '/admin/aulas',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/aulas',
        ),
      ),
      GoRoute(
        path: '/admin/consulta-horarios',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/consulta-horarios',
        ),
      ),
      GoRoute(
        path: '/admin/consulta-asistencias',
        builder: (context, state) => const AdminLayoutScreen(
          currentRoute: '/admin/consulta-asistencias',
        ),
      ),
      // Alumno routes
      GoRoute(
        path: '/alumno',
        redirect: (context, state) => '/alumno/horario',
      ),
      GoRoute(
        path: '/alumno/horario',
        builder: (context, state) => const AlumnoLayoutScreen(
          currentRoute: '/alumno/horario',
        ),
      ),
      // Maestro routes
      GoRoute(
        path: '/maestro',
        redirect: (context, state) => '/maestro/dashboard',
      ),
      GoRoute(
        path: '/maestro/dashboard',
        builder: (context, state) => const MaestroLayoutScreen(
          currentRoute: '/maestro/dashboard',
        ),
      ),
      // Jefe routes
      GoRoute(
        path: '/jefe',
        redirect: (context, state) => '/jefe/horario',
      ),
      GoRoute(
        path: '/jefe/horario',
        builder: (context, state) => const JefeLayoutScreen(
          currentRoute: '/jefe/horario',
        ),
      ),
      // Checador routes
      GoRoute(
        path: '/checador',
        redirect: (context, state) => '/checador/control',
      ),
      GoRoute(
        path: '/checador/control',
        builder: (context, state) => const ChecadorLayoutScreen(
          currentRoute: '/checador/control',
        ),
      ),
    ],
  );

  static String getRouteByRole(String role) {
    switch (role) {
      case 'Administrador':
        return '/admin/dashboard';
      case 'Alumno':
        return '/alumno/horario';
      case 'Profesor':
      case 'Maestro':
        return '/maestro/dashboard';
      case 'Jefe_de_Grupo':
      case 'Jefe de Grupo':
        return '/jefe/horario';
      case 'Checador':
        return '/checador/control';
      default:
        return '/login';
    }
  }
}
