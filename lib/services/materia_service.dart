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
}

