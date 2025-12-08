import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/materia.dart';
import 'auth_service.dart';

class MateriaService {
  final AuthService _authService = AuthService();

  Future<List<Materia>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/materias'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Materia.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Materia> create(String name) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/materias'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['success']) {
        return Materia.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear materia');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Materia> update(int id, String name) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/materias/$id'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return Materia.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al actualizar materia');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/materias/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(result['error'] ?? 'Error al eliminar materia');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

