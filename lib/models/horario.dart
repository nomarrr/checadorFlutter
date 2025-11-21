class HorarioMaestro {
  final int? id;
  final int? maestroId;
  final int? materiaId;
  final int? grupoId;
  final String? dias;
  final String? horaInicio;
  final String? horaFin;
  final bool? asistencia;
  final Map<String, dynamic>? maestro;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? materia;
  final Map<String, dynamic>? grupo;
  final String? createdAt;

  HorarioMaestro({
    this.id,
    this.maestroId,
    this.materiaId,
    this.grupoId,
    this.dias,
    this.horaInicio,
    this.horaFin,
    this.asistencia,
    this.maestro,
    this.usuario,
    this.materia,
    this.grupo,
    this.createdAt,
  });

  factory HorarioMaestro.fromJson(Map<String, dynamic> json) {
    return HorarioMaestro(
      id: json['id'],
      maestroId: json['maestro_id'],
      materiaId: json['materia_id'],
      grupoId: json['grupo_id'],
      dias: json['dias'],
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      asistencia: json['asistencia'],
      maestro: json['maestro'],
      usuario: json['usuario'],
      materia: json['materia'],
      grupo: json['grupo'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maestro_id': maestroId,
      'materia_id': materiaId,
      'grupo_id': grupoId,
      'dias': dias,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'asistencia': asistencia,
      'maestro': maestro,
      'usuario': usuario,
      'materia': materia,
      'grupo': grupo,
      'created_at': createdAt,
    };
  }

  String get nombreMaestro => maestro?['name'] ?? usuario?['name'] ?? 'Sin maestro';
  String get nombreMateria => materia?['name'] ?? 'Sin materia';
  String get nombreGrupo => grupo?['name'] ?? 'Sin grupo';
  String get nombreAula => grupo?['aula']?['numero'] ?? 'Sin aula';
  String get nombreEdificio => grupo?['aula']?['edificio']?['nombre'] ?? 'Sin edificio';
}

