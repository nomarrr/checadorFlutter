import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

class UsuarioService {
  final AuthService _authService = AuthService();

  Future<List<Usuario>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/usuarios'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Usuario.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Usuario>> getMaestros() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/usuarios/maestros'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Usuario.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Usuario>> getJefes() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/usuarios/jefes'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Usuario.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Usuario> create(Usuario usuario) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/usuarios'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['success']) {
        return Usuario.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear usuario');
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<Usuario> update(int id, Usuario usuario) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/usuarios/$id'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return Usuario.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al actualizar usuario');
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/usuarios/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
