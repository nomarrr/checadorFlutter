class Materia {
  final int? id;
  final String name;
  final int? carreraId;
  final int? semestre;
  final Map<String, dynamic>? carrera;
  final String? createdAt;

  Materia({
    this.id,
    required this.name,
    this.carreraId,
    this.semestre,
    this.carrera,
    this.createdAt,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'],
      name: json['name'] ?? '',
      carreraId: json['carrera_id'],
      semestre: json['semestre'],
      carrera: json['carrera'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'carrera_id': carreraId,
      'semestre': semestre,
      'carrera': carrera,
      'created_at': createdAt,
    };
  }
}
