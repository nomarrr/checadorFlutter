import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'auth_service.dart';

class EdificioService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/edificios'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> create(String nombre) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/edificios'),
        headers: headers,
        body: jsonEncode({'nombre': nombre}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['success']) {
        return result['data'];
      }
      throw Exception(result['error'] ?? 'Error al crear edificio');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> update(int id, String nombre) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/edificios/$id'),
        headers: headers,
        body: jsonEncode({'nombre': nombre}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return result['data'];
      }
      throw Exception(result['error'] ?? 'Error al actualizar edificio');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/edificios/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(result['error'] ?? 'Error al eliminar edificio');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
