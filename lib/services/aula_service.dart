import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'auth_service.dart';

class AulaService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/aulas'),
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

  Future<void> create(String numero, int edificioId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('${Environment.apiUrl}/aulas'),
      headers: headers,
      body: jsonEncode({'numero': numero, 'edificio_id': edificioId}),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode != 201 || !result['success']) {
      throw Exception(result['error'] ?? 'Error al crear aula');
    }
  }

  Future<void> update(int id, String numero, int edificioId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('${Environment.apiUrl}/aulas/$id'),
      headers: headers,
      body: jsonEncode({'numero': numero, 'edificio_id': edificioId}),
    );

    final result = jsonDecode(response.body);
    if (response.statusCode != 200 || !result['success']) {
      throw Exception(result['error'] ?? 'Error al actualizar aula');
    }
  }

  Future<void> delete(int id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('${Environment.apiUrl}/aulas/$id'),
      headers: headers,
    );

    final result = jsonDecode(response.body);
    if (response.statusCode != 200 || !result['success']) {
      throw Exception(result['error'] ?? 'Error al eliminar aula');
    }
  }
}
