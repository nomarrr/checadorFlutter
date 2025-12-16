import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/asistencia.dart';
import 'auth_service.dart';

class AsistenciaService {
  final AuthService _authService = AuthService();

  // ==================== ASISTENCIAS CHECADOR ====================
  Future<List<AsistenciaChecador>> getAsistenciasChecador({
    int? horarioId,
    String? fecha,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final params = <String, String>{};
      if (horarioId != null) params['horario_id'] = horarioId.toString();
      if (fecha != null) params['fecha'] = fecha;

      final uri = Uri.parse('${Environment.apiUrl}/asistencias/checador')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => AsistenciaChecador.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AsistenciaChecador> createAsistenciaChecador(
      AsistenciaChecador asistencia) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/asistencias/checador'),
        headers: headers,
        body: jsonEncode(asistencia.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return AsistenciaChecador.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear asistencia');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateAsistenciaChecador(
      int id, TipoAsistencia nuevoEstado) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/asistencias/checador/$id'),
        headers: headers,
        body: jsonEncode({'asistencia': nuevoEstado.value}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al actualizar asistencia');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==================== ASISTENCIAS JEFE ====================
  Future<List<AsistenciaJefe>> getAsistenciasJefe({
    int? horarioId,
    String? fecha,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final params = <String, String>{};
      if (horarioId != null) params['horario_id'] = horarioId.toString();
      if (fecha != null) params['fecha'] = fecha;

      final uri = Uri.parse('${Environment.apiUrl}/asistencias/jefe')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => AsistenciaJefe.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AsistenciaJefe> createAsistenciaJefe(AsistenciaJefe asistencia) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/asistencias/jefe'),
        headers: headers,
        body: jsonEncode(asistencia.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return AsistenciaJefe.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear asistencia');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateAsistenciaJefe(int id, TipoAsistencia nuevoEstado) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiUrl}/asistencias/jefe/$id'),
        headers: headers,
        body: jsonEncode({'asistencia': nuevoEstado.value}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode != 200 || !result['success']) {
        throw Exception(result['error'] ?? 'Error al actualizar asistencia');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==================== ASISTENCIAS MAESTRO ====================
  Future<List<AsistenciaMaestro>> getAsistenciasMaestro({
    int? horarioId,
    String? fecha,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final params = <String, String>{};
      if (horarioId != null) params['horario_id'] = horarioId.toString();
      if (fecha != null) params['fecha'] = fecha;

      final uri = Uri.parse('${Environment.apiUrl}/asistencias/maestro')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        return data.map((json) => AsistenciaMaestro.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AsistenciaMaestro> createAsistenciaMaestro(
      AsistenciaMaestro asistencia) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/asistencias/maestro'),
        headers: headers,
        body: jsonEncode(asistencia.toJson()),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return AsistenciaMaestro.fromJson(result['data']);
      }
      throw Exception(result['error'] ?? 'Error al crear asistencia');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Obtener resumen de asistencias
  Future<Map<String, dynamic>?> getResumenAsistencias(
      int maestroId, String fecha) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(
            '${Environment.apiUrl}/asistencias/resumen/$maestroId/$fecha'),
        headers: headers,
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        return result['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Obtener todas las asistencias de todas las fuentes para un rango de fechas
  Future<Map<String, List<dynamic>>> getAsistenciasPorSemana({
    required int maestroId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();

      // Obtener asistencias de las tres fuentes en paralelo
      final results = await Future.wait([
        http.get(
          Uri.parse('${Environment.apiUrl}/asistencias/checador'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${Environment.apiUrl}/asistencias/jefe'),
          headers: headers,
        ),
        http.get(
          Uri.parse('${Environment.apiUrl}/asistencias/maestro'),
          headers: headers,
        ),
      ]);

      final checadorData = jsonDecode(results[0].body);
      final jefeData = jsonDecode(results[1].body);
      final maestroData = jsonDecode(results[2].body);

      // Filtrar por rango de fechas
      final checadorList = (checadorData['data'] as List? ?? [])
          .where((a) => _estaEnRango(a['fecha'], fechaInicio, fechaFin))
          .map((a) => {...a, 'tipo': 'checador'})
          .toList();

      final jefeList = (jefeData['data'] as List? ?? [])
          .where((a) => _estaEnRango(a['fecha'], fechaInicio, fechaFin))
          .map((a) => {...a, 'tipo': 'jefe'})
          .toList();

      final maestroList = (maestroData['data'] as List? ?? [])
          .where((a) => _estaEnRango(a['fecha'], fechaInicio, fechaFin))
          .map((a) => {...a, 'tipo': 'maestro'})
          .toList();

      return {
        'checador': checadorList,
        'jefe': jefeList,
        'maestro': maestroList,
      };
    } catch (e) {
      print('Error en getAsistenciasPorSemana: $e');
      return {
        'checador': [],
        'jefe': [],
        'maestro': [],
      };
    }
  }

  bool _estaEnRango(String? fecha, String inicio, String fin) {
    if (fecha == null) return false;
    try {
      final fechaDate = DateTime.parse(fecha);
      final inicioDate = DateTime.parse(inicio);
      final finDate = DateTime.parse(fin);
      return !fechaDate.isBefore(inicioDate) && !fechaDate.isAfter(finDate);
    } catch (e) {
      return false;
    }
  }
}
