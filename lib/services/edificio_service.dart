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
}
