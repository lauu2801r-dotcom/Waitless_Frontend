import '../models/usuario.dart';

sealed class AuthResultado<T> {
  const AuthResultado();
}

class AuthExito<T> extends AuthResultado<T> {
  final T datos;
  const AuthExito(this.datos);
}

class AuthError<T> extends AuthResultado<T> {
  final String mensaje;
  const AuthError(this.mensaje);
}

/// Política de tratamiento de datos personales (Ley 1581 de 2012).
class PoliticaPrivacidad {
  final String version;
  final String titulo;
  final String texto;
  const PoliticaPrivacidad({
    required this.version,
    required this.titulo,
    required this.texto,
  });
}

abstract class AuthRepository {
  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String? telefono,
    required bool aceptaPolitica,
  });

  Future<AuthResultado<String>> registrarAdministrador({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String nombreRestaurante,
    required String codigoNegocio,
    required bool aceptaPolitica,
  });

  Future<AuthResultado<PoliticaPrivacidad>> obtenerPolitica();

  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  });

  Future<AuthResultado<String>> reenviarCodigo(String correo);

  /// Envía un código al correo para recuperar la contraseña.
  Future<AuthResultado<String>> solicitarRecuperacion(String correo);

  /// Cambia la contraseña usando el código recibido por correo.
  Future<AuthResultado<String>> restablecerPassword({
    required String correo,
    required String codigo,
    required String nuevaPassword,
  });

  Future<AuthResultado<Usuario>> iniciarSesion({
    required String correo,
    required String password,
  });

  Future<void> cerrarSesion();

  Future<Usuario?> usuarioActual();
}