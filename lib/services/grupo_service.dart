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
}

