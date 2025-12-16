import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/horario.dart';
import 'auth_service.dart';

class HorarioService {
  final AuthService _authService = AuthService();

  // Obtener todos los horarios
  Future<List<HorarioMaestro>> getAll() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/horarios'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => HorarioMaestro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obtener horarios por maestro
  Future<List<HorarioMaestro>> getByMaestro(int maestroId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/horarios?maestro_id=$maestroId'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => HorarioMaestro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obtener horarios por grupo
  Future<List<HorarioMaestro>> getByGrupo(int grupoId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/horarios?grupo_id=$grupoId'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => HorarioMaestro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obtener horario por ID
  Future<HorarioMaestro?> getById(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/horarios/$id'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return HorarioMaestro.fromJson(result['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Crear horario
  Future<HorarioMaestro> create(Map<String, dynamic> data) async {
    try {
      print('=== CREATE HORARIO ===');
      print('Data enviado: $data');

      final headers = await _authService.getAuthHeaders();
      print('Headers: $headers');

      final body = jsonEncode(data);
      print('Body JSON: $body');

      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/horarios'),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final result = jsonDecode(response.body);

      // Aceptar tanto 200 como 201 (Created)
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          result['success']) {
        return HorarioMaestro.fromJson(result['data']);
      }

      final errorMsg =
          result['error'] ?? result['message'] ?? 'Error al crear horario';
      print('Error message: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('Exception en create: $e');
      throw Exception(e.toString());
    }
  }

  // Actualizar horario
  Future<HorarioMaestro> update(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/horarios/$id'),
        headers: headers,
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return HorarioMaestro.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al actualizar horario');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Eliminar horario
  Future<void> delete(int id) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${Environment.apiUrl}/horarios/$id'),
        headers: headers,
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final result = jsonDecode(response.body);

        // Detectar error de foreign key constraint
        if (result['error'] != null &&
            result['error'].toString().contains('foreign key constraint')) {
          throw Exception(
              'No se puede eliminar este horario porque tiene registros de asistencia asociados. '
              'Por favor, elimine primero las asistencias relacionadas o contacte al administrador del sistema.');
        }

        throw Exception(result['message'] ??
            result['error'] ??
            'Error al eliminar horario');
      }
    } catch (e) {
      print('Error en delete: $e');

      // Si ya es un Exception con nuestro mensaje, re-lanzarlo tal cual
      if (e is Exception && e.toString().contains('registros de asistencia')) {
        rethrow;
      }

      throw Exception(e.toString());
    }
  }

  // Buscar horarios con filtros
  Future<List<HorarioMaestro>> searchHorarios(
      Map<String, dynamic> filters) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final params = <String, String>{};

      if (filters['carrera_id'] != null) {
        params['carrera_id'] = filters['carrera_id'].toString();
      }
      if (filters['maestro_id'] != null) {
        params['maestro_id'] = filters['maestro_id'].toString();
      }
      if (filters['grupo_id'] != null) {
        params['grupo_id'] = filters['grupo_id'].toString();
      }

      final uri = Uri.parse('${Environment.apiUrl}/horarios')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => HorarioMaestro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
