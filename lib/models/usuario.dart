class Usuario {
  final int? id;
  final String? authId;
  final String name;
  final String? email;
  final String? password;
  final String? role;
  final String? numeroCuenta;
  final bool? activo;
  final String? createdAt;

  Usuario({
    this.id,
    this.authId,
    required this.name,
    this.email,
    this.password,
    this.role,
    this.numeroCuenta,
    this.activo,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      authId: json['auth_id'],
      name: json['name'] ?? '',
      email: json['email'],
      password: json['password'],
      role: json['role'],
      numeroCuenta: json['numero_cuenta'],
      activo: json['activo'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
      'role': role,
      'numero_cuenta': numeroCuenta,
      'activo': activo,
      'created_at': createdAt,
    };
    // Solo incluir password si no es null
    if (password != null) {
      json['password'] = password;
    }
    return json;
  }

  Usuario copyWith({
    int? id,
    String? authId,
    String? name,
    String? email,
    String? password,
    String? role,
    String? numeroCuenta,
    bool? activo,
    String? createdAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
