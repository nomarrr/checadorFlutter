import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/carrera.dart';
import 'auth_service.dart';

class CarreraService {
  final AuthService _authService = AuthService();

  Future<List<Carrera>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/carreras'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => Carrera.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Carrera> create(String name) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/carreras'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['success']) {
        return Carrera.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear carrera');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Carrera> update(int id, String name) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/carreras/$id'),
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return Carrera.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al actualizar carrera');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/carreras/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(result['error'] ?? 'Error al eliminar carrera');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
