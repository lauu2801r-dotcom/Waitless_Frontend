import 'dart:convert';

/// Roles disponibles en el sistema.
enum RolUsuario { cliente, administrador }

extension RolUsuarioX on RolUsuario {
  String get etiqueta {
    switch (this) {
      case RolUsuario.cliente:
        return 'Cliente';
      case RolUsuario.administrador:
        return 'Administrador';
    }
  }

  String get codigo {
    switch (this) {
      case RolUsuario.cliente:
        return 'cliente';
      case RolUsuario.administrador:
        return 'administrador';
    }
  }

  static RolUsuario desdeCodigo(String codigo) {
    switch (codigo) {
      case 'administrador':
        return RolUsuario.administrador;
      default:
        return RolUsuario.cliente;
    }
  }
}

class Usuario {
  final String id;
  final String nombreCompleto;
  final String correo;
  final String passwordHash;
  final bool correoVerificado;
  final DateTime fechaRegistro;
  final RolUsuario rol;
  final String? restauranteId;
  final String? nombreRestaurante;

  /// `true` solo después de iniciar sesión por primera vez tras el registro.
  /// Usamos esta bandera para mostrar pantallas vacías a usuarios recién
  /// registrados y datos completos cuando vuelven a iniciar sesión.
  final bool conDatos;

  const Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.passwordHash,
    required this.correoVerificado,
    required this.fechaRegistro,
    required this.rol,
    this.restauranteId,
    this.nombreRestaurante,
    this.conDatos = false,
  });

  String get inicial =>
      nombreCompleto.trim().isEmpty ? '?' : nombreCompleto.trim()[0].toUpperCase();

  String get primerNombre => nombreCompleto.trim().split(' ').first;

  bool get esAdministrador => rol == RolUsuario.administrador;
  bool get esCliente => rol == RolUsuario.cliente;

  Usuario copyWith({
    String? nombreCompleto,
    String? correo,
    String? passwordHash,
    bool? correoVerificado,
    RolUsuario? rol,
    String? restauranteId,
    String? nombreRestaurante,
    bool? conDatos,
  }) {
    return Usuario(
      id: id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      passwordHash: passwordHash ?? this.passwordHash,
      correoVerificado: correoVerificado ?? this.correoVerificado,
      fechaRegistro: fechaRegistro,
      rol: rol ?? this.rol,
      restauranteId: restauranteId ?? this.restauranteId,
      nombreRestaurante: nombreRestaurante ?? this.nombreRestaurante,
      conDatos: conDatos ?? this.conDatos,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombreCompleto': nombreCompleto,
        'correo': correo,
        'passwordHash': passwordHash,
        'correoVerificado': correoVerificado,
        'fechaRegistro': fechaRegistro.toIso8601String(),
        'rol': rol.codigo,
        'restauranteId': restauranteId,
        'nombreRestaurante': nombreRestaurante,
        'conDatos': conDatos,
      };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        nombreCompleto: json['nombreCompleto'] as String,
        correo: json['correo'] as String,
        passwordHash: json['passwordHash'] as String,
        correoVerificado: json['correoVerificado'] as bool,
        fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
        rol: RolUsuarioX.desdeCodigo(json['rol'] as String? ?? 'cliente'),
        restauranteId: json['restauranteId'] as String?,
        nombreRestaurante: json['nombreRestaurante'] as String?,
        conDatos: json['conDatos'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory Usuario.fromJsonString(String s) =>
      Usuario.fromJson(jsonDecode(s) as Map<String, dynamic>);
}