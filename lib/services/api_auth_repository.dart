import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _kClaveSesion = 'waitless.sesion_actual';
  static const String _kClaveToken = 'waitless.token';
  static const Map<String, String> _headersJson = {
    'Content-Type': 'application/json',
  };

  // ── Utilidades ──────────────────────────────────────────

  /// Decodifica siempre como UTF-8 (para que las tildes no se dañen).
  dynamic _decodificar(http.Response r) =>
      jsonDecode(utf8.decode(r.bodyBytes));

  /// Saca un mensaje legible del error del backend. FastAPI puede devolver
  /// `detail` como texto (errores nuestros) o como lista (errores 422).
  String _mensajeError(http.Response r, String porDefecto) {
    try {
      final data = _decodificar(r);
      final detalle = data is Map ? data['detail'] : null;
      if (detalle is String) return detalle;
      if (detalle is List && detalle.isNotEmpty) {
        final primero = detalle.first;
        if (primero is Map && primero['msg'] is String) {
          return primero['msg'] as String;
        }
      }
    } catch (_) {}
    return porDefecto;
  }

  (String, String) _dividirNombre(String nombreCompleto) {
    final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
    final nombre = partes.first;
    final apellido = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    return (nombre, apellido);
  }

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
      nombreRestaurante: u['nombre_restaurante'] as String?,
      conDatos: true,
    );
  }

  // ── Registro ────────────────────────────────────────────

  @override
  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String? telefono,
    required bool aceptaPolitica,
  }) async {
    try {
      final (nombre, apellido) = _dividirNombre(nombreCompleto);

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headersJson,
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': correo.trim(),
          'password': password,
          'telefono': telefono,
          'rol': 'cliente',
          'acepta_politica': aceptaPolitica,
        }),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código enviado a tu correo');
      }
      return AuthError(_mensajeError(response, 'Error al registrar'));
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
    required bool aceptaPolitica,
  }) async {
    try {
      final (nombre, apellido) = _dividirNombre(nombreCompleto);

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headersJson,
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': correo.trim(),
          'password': password,
          'rol': 'administrador',
          'nombre_restaurante': nombreRestaurante.trim(),
          'codigo_negocio': codigoNegocio.trim(),
          'acepta_politica': aceptaPolitica,
        }),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código enviado a tu correo');
      }
      return AuthError(_mensajeError(response, 'Error al registrar'));
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<PoliticaPrivacidad>> obtenerPolitica() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/politica-privacidad'),
      );
      if (response.statusCode == 200) {
        final data = _decodificar(response) as Map<String, dynamic>;
        return AuthExito(
          PoliticaPrivacidad(
            version: data['version'] as String,
            titulo: data['titulo'] as String,
            texto: data['texto'] as String,
          ),
        );
      }
      return AuthError(
          _mensajeError(response, 'No se pudo cargar la política'));
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  // ── Verificación y sesión ───────────────────────────────

  @override
  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: _headersJson,
        body: jsonEncode({'email': correo, 'otp': codigo}),
      );

      if (response.statusCode == 200) {
        final data = _decodificar(response) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final usuario = _mapearUsuario(data);
        await _guardarSesion(usuario, token);
        return AuthExito(usuario);
      }
      return AuthError(_mensajeError(response, 'Código incorrecto'));
    } catch (e) {
      return AuthError('Error de conexión: $e');
    }
  }

  @override
  Future<AuthResultado<String>> reenviarCodigo(String correo) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: _headersJson,
        body: jsonEncode({'email': correo}),
      );

      if (response.statusCode == 200) {
        return const AuthExito('Código reenviado a tu correo');
      }
      return AuthError(_mensajeError(response, 'Error al reenviar'));
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
        headers: _headersJson,
        body: jsonEncode({'email': correo.trim(), 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = _decodificar(response) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final usuario = _mapearUsuario(data);
        await _guardarSesion(usuario, token);
        return AuthExito(usuario);
      }
      return AuthError(_mensajeError(response, 'Credenciales incorrectas'));
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