enum TipoAsistencia {
  presente,
  falta,
  retardado,
}

extension TipoAsistenciaExtension on TipoAsistencia {
  String get value {
    switch (this) {
      case TipoAsistencia.presente:
        return 'Presente';
      case TipoAsistencia.falta:
        return 'Falta';
      case TipoAsistencia.retardado:
        return 'Retardo';
    }
  }

  static TipoAsistencia fromString(String value) {
    switch (value.toLowerCase()) {
      case 'presente':
        return TipoAsistencia.presente;
      case 'falta':
        return TipoAsistencia.falta;
      case 'retardo':
      case 'retardado':
        return TipoAsistencia.retardado;
      default:
        return TipoAsistencia.falta;
    }
  }
}

class AsistenciaChecador {
  final int? id;
  final int? horarioId;
  final String fecha;
  final TipoAsistencia asistencia;
  final int checadorId;
  final String? createdAt;

  AsistenciaChecador({
    this.id,
    this.horarioId,
    required this.fecha,
    required this.asistencia,
    required this.checadorId,
    this.createdAt,
  });

  factory AsistenciaChecador.fromJson(Map<String, dynamic> json) {
    return AsistenciaChecador(
      id: json['id'],
      horarioId: json['horario_id'],
      fecha: json['fecha'] ?? '',
      asistencia: TipoAsistenciaExtension.fromString(json['asistencia'] ?? 'Falta'),
      checadorId: json['checador_id'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horario_id': horarioId,
      'fecha': fecha,
      'asistencia': asistencia.value,
      'checador_id': checadorId,
      'created_at': createdAt,
    };
  }
}

class AsistenciaJefe {
  final int? id;
  final int? horarioId;
  final String fecha;
  final TipoAsistencia asistencia;
  final int jefeId;
  final String? createdAt;

  AsistenciaJefe({
    this.id,
    this.horarioId,
    required this.fecha,
    required this.asistencia,
    required this.jefeId,
    this.createdAt,
  });

  factory AsistenciaJefe.fromJson(Map<String, dynamic> json) {
    return AsistenciaJefe(
      id: json['id'],
      horarioId: json['horario_id'],
      fecha: json['fecha'] ?? '',
      asistencia: TipoAsistenciaExtension.fromString(json['asistencia'] ?? 'Falta'),
      jefeId: json['jefe_id'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horario_id': horarioId,
      'fecha': fecha,
      'asistencia': asistencia.value,
      'jefe_id': jefeId,
      'created_at': createdAt,
    };
  }
}

class AsistenciaMaestro {
  final int? id;
  final int? horarioId;
  final String fecha;
  final TipoAsistencia asistencia;
  final int maestroId;
  final String? createdAt;

  AsistenciaMaestro({
    this.id,
    this.horarioId,
    required this.fecha,
    required this.asistencia,
    required this.maestroId,
    this.createdAt,
  });

  factory AsistenciaMaestro.fromJson(Map<String, dynamic> json) {
    return AsistenciaMaestro(
      id: json['id'],
      horarioId: json['horario_id'],
      fecha: json['fecha'] ?? '',
      asistencia: TipoAsistenciaExtension.fromString(json['asistencia'] ?? 'Falta'),
      maestroId: json['maestro_id'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'horario_id': horarioId,
      'fecha': fecha,
      'asistencia': asistencia.value,
      'maestro_id': maestroId,
      'created_at': createdAt,
    };
  }
}

