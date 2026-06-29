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

abstract class AuthRepository {
  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String? telefono,
  });

  Future<AuthResultado<String>> registrarAdministrador({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String nombreRestaurante,
    required String codigoNegocio,
  });

  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  });

  Future<AuthResultado<String>> reenviarCodigo(String correo);

  Future<AuthResultado<Usuario>> iniciarSesion({
    required String correo,
    required String password,
  });

  Future<void> cerrarSesion();

  Future<Usuario?> usuarioActual();
}