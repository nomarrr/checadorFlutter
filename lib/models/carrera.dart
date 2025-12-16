class Carrera {
  final int? id;
  final String nombre;
  final int? semestres;
  final String? createdAt;

  Carrera({
    this.id,
    required this.nombre,
    this.semestres,
    this.createdAt,
  });

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      semestres: json['semestres'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'semestres': semestres,
      'created_at': createdAt,
    };
  }
}
