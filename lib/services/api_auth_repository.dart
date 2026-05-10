import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _kClaveSesion = 'waitless.sesion_actual';
  static const String _kClaveToken = 'waitless.token';

  Future<void> _guardarSesion(Usuario usuario, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClaveSesion, usuario.toJsonString());
    await prefs.setString(_kClaveToken, token);
  }

  Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kClaveToken);
  }

  Usuario _mapearUsuario(Map<String, dynamic> json) {
    final u = json['usuario'] as Map<String, dynamic>;
    return Usuario(
      id: u['id'].toString(),
      nombreCompleto: '${u['nombre']} ${u['apellido']}',
      correo: u['email'] as String,
      passwordHash: '',
      correoVerificado: u['verificado'] as bool,
      fechaRegistro: DateTime.parse(u['creado_en'] as String),
      rol: RolUsuarioX.desdeCodigo(u['rol'] as String),
      conDatos: true,
    );
  }

  @override
  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) async {
    try {
      final partes = nombreCompleto.trim().split(' ');
      final nombre = partes.first;
      final apellido = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': correo,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código enviado a tu correo');
      } else {
        final error = jsonDecode(response.body);
        return AuthError(error['detail'] ?? 'Error al registrar');
      }
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<String>> registrarAdministrador({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String nombreRestaurante,
    required String codigoNegocio,
  }) async {
    try {
      final partes = nombreCompleto.trim().split(' ');
      final nombre = partes.first;
      final apellido = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': correo,
          'password': password,
          'rol': 'administrador',
        }),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código enviado a tu correo');
      } else {
        final error = jsonDecode(response.body);
        return AuthError(error['detail'] ?? 'Error al registrar');
      }
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': correo,
          'otp': codigo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final usuario = _mapearUsuario(data);
        await _guardarSesion(usuario, token);
        return AuthExito(usuario);
      } else {
        final error = jsonDecode(response.body);
        return AuthError(error['detail'] ?? 'Código incorrecto');
      }
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<String>> reenviarCodigo(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': correo}),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código reenviado a tu correo');
      } else {
        final error = jsonDecode(response.body);
        return AuthError(error['detail'] ?? 'Error al reenviar');
      }
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<Usuario>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': correo,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] as String;
        final usuario = _mapearUsuario(data);
        await _guardarSesion(usuario, token);
        return AuthExito(usuario);
      } else {
        final error = jsonDecode(response.body);
        return AuthError(error['detail'] ?? 'Credenciales incorrectas');
      }
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kClaveSesion);
    await prefs.remove(_kClaveToken);
  }

  @override
  Future<Usuario?> usuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kClaveSesion);
    if (raw == null) return null;
    try {
      return Usuario.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }
}