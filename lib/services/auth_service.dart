import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../models/usuario.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Login con el backend
  Future<Usuario> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al iniciar sesión');
      }

      final user = Usuario.fromJson(result['data']['user']);
      final token = result['data']['token'];

      // Guardar token y usuario
      await _saveToken(token);
      await _saveUser(user);

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Registro de usuario
  Future<Usuario> register({
    required String email,
    required String password,
    required String name,
    String role = 'Alumno',
    String? numeroCuenta,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'numero_cuenta': numeroCuenta,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al registrar usuario');
      }

      final user = Usuario.fromJson(result['data']);
      await _saveUser(user);

      return user;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Obtener usuario actual
  Future<Usuario?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return Usuario.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Obtener token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    final token = await getToken();
    return user != null && token != null;
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Eliminar datos de usuario y token
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      // Limpiar todas las preferencias relacionadas con la sesión
      await prefs.clear();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      // Aún si hay error, intentar limpiar
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // Guardar usuario
  Future<void> _saveUser(Usuario user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Guardar token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Obtener headers con autenticación
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

