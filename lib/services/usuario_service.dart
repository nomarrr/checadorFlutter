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
}

