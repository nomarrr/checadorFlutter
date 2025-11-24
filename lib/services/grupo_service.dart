import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/grupo.dart';
import 'auth_service.dart';

class GrupoService {
  final AuthService _authService = AuthService();

  Future<List<Grupo>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/grupos'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Grupo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Grupo> create(Grupo grupo) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/grupos'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(grupo.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['success']) {
        return Grupo.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear grupo');
    } catch (e) {
      throw Exception('Error al crear grupo: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/grupos/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al eliminar grupo');
      }
    } catch (e) {
      throw Exception('Error al eliminar grupo: $e');
    }
  }
}



