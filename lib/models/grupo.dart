class Grupo {
  final int? id;
  final String name;
  final int? carreraId;
  final int? jefeId;
  final int? aulaId;
  final Map<String, dynamic>? carrera;
  final Map<String, dynamic>? jefe;
  final Map<String, dynamic>? aula;
  final String? createdAt;

  Grupo({
    this.id,
    required this.name,
    this.carreraId,
    this.jefeId,
    this.aulaId,
    this.carrera,
    this.jefe,
    this.aula,
    this.createdAt,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'],
      name: json['name'] ?? '',
      carreraId: json['carrera_id'],
      jefeId: json['jefe_id'],
      aulaId: json['aula_id'],
      carrera: json['carrera'],
      jefe: json['jefe'],
      aula: json['aula'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'carrera_id': carreraId,
      'jefe_id': jefeId,
      'aula_id': aulaId,
      'carrera': carrera,
      'jefe': jefe,
      'aula': aula,
      'created_at': createdAt,
    };
  }

  String get nombreAula => aula?['numero'] ?? 'N/A';
  String get nombreEdificio => aula?['edificio']?['nombre'] ?? 'N/A';
}


