import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  static const _kClaveUsuarios = 'sabor_datos.usuarios';
  static const _kClaveSesion = 'sabor_datos.sesion_actual';
  static const _kClaveCodigosPendientes = 'sabor_datos.codigos_verificacion';

  /// Código fijo de validación de negocio para crear cuentas administrador
  /// en este demo. En producción, lo emitiría el backend.
  static const String codigoNegocioValido = 'RESTO2026';

  Future<List<Usuario>> _leerUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kClaveUsuarios) ?? [];
    return raw.map((s) => Usuario.fromJsonString(s)).toList();
  }

  Future<void> _guardarUsuarios(List<Usuario> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kClaveUsuarios,
      usuarios.map((u) => u.toJsonString()).toList(),
    );
  }

  Future<Map<String, String>> _leerCodigosPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kClaveCodigosPendientes) ?? '{}';
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _guardarCodigosPendientes(Map<String, String> codigos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClaveCodigosPendientes, jsonEncode(codigos));
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode('sabor_datos_salt::$password');
    var hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash) + b;
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  String _generarCodigo() {
    final r = Random();
    return (r.nextInt(900000) + 100000).toString();
  }

  String _generarId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  @override
  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) async {
    return _registrarUsuario(
      nombreCompleto: nombreCompleto,
      correo: correo,
      password: password,
      rol: RolUsuario.cliente,
    );
  }

  @override
  Future<AuthResultado<String>> registrarAdministrador({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String nombreRestaurante,
    required String codigoNegocio,
  }) async {
    if (codigoNegocio.trim().toUpperCase() != codigoNegocioValido) {
      return const AuthError(
          'Código de negocio inválido. Verifica con tu proveedor.');
    }
    return _registrarUsuario(
      nombreCompleto: nombreCompleto,
      correo: correo,
      password: password,
      rol: RolUsuario.administrador,
      nombreRestaurante: nombreRestaurante,
    );
  }

  Future<AuthResultado<String>> _registrarUsuario({
    required String nombreCompleto,
    required String correo,
    required String password,
    required RolUsuario rol,
    String? nombreRestaurante,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final correoNormalizado = correo.trim().toLowerCase();
    final usuarios = await _leerUsuarios();

    final existe = usuarios.any((u) => u.correo == correoNormalizado);
    if (existe) {
      return const AuthError('Ya existe una cuenta con este correo');
    }

    // Para administradores, crear un restauranteId único.
    // Para el demo, usamos rest_001 para que coincidan con los pedidos mock.
    final restauranteId = rol == RolUsuario.administrador
        ? 'rest_001'
        : null;

    final nuevo = Usuario(
      id: _generarId(),
      nombreCompleto: nombreCompleto.trim(),
      correo: correoNormalizado,
      passwordHash: _hashPassword(password),
      correoVerificado: false,
      fechaRegistro: DateTime.now(),
      rol: rol,
      restauranteId: restauranteId,
      nombreRestaurante: nombreRestaurante?.trim(),
    );

    usuarios.add(nuevo);
    await _guardarUsuarios(usuarios);

    final codigo = _generarCodigo();
    final codigos = await _leerCodigosPendientes();
    codigos[correoNormalizado] = codigo;
    await _guardarCodigosPendientes(codigos);

    return AuthExito(codigo);
  }

  @override
  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final correoNormalizado = correo.trim().toLowerCase();
    final codigos = await _leerCodigosPendientes();
    final codigoEsperado = codigos[correoNormalizado];

    if (codigoEsperado == null) {
      return const AuthError('No hay código pendiente para este correo');
    }
    if (codigoEsperado != codigo.trim()) {
      return const AuthError('Código incorrecto');
    }

    final usuarios = await _leerUsuarios();
    final idx = usuarios.indexWhere((u) => u.correo == correoNormalizado);
    if (idx == -1) {
      return const AuthError('Usuario no encontrado');
    }

    final verificado = usuarios[idx].copyWith(correoVerificado: true);
    usuarios[idx] = verificado;
    await _guardarUsuarios(usuarios);

    codigos.remove(correoNormalizado);
    await _guardarCodigosPendientes(codigos);

    await _guardarSesion(verificado);
    return AuthExito(verificado);
  }

  @override
  Future<AuthResultado<String>> reenviarCodigo(String correo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final correoNormalizado = correo.trim().toLowerCase();
    final usuarios = await _leerUsuarios();
    final existe = usuarios.any((u) => u.correo == correoNormalizado);
    if (!existe) {
      return const AuthError('No hay cuenta registrada con este correo');
    }
    final codigo = _generarCodigo();
    final codigos = await _leerCodigosPendientes();
    codigos[correoNormalizado] = codigo;
    await _guardarCodigosPendientes(codigos);
    return AuthExito(codigo);
  }

  @override
  Future<AuthResultado<Usuario>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final correoNormalizado = correo.trim().toLowerCase();
    final usuarios = await _leerUsuarios();

    Usuario? usuario;
    for (final u in usuarios) {
      if (u.correo == correoNormalizado) {
        usuario = u;
        break;
      }
    }

    if (usuario == null) {
      return const AuthError('No hay cuenta con este correo');
    }
    if (usuario.passwordHash != _hashPassword(password)) {
      return const AuthError('Contraseña incorrecta');
    }
    if (!usuario.correoVerificado) {
      return const AuthError(
          'Tu correo aún no ha sido verificado. Revisa tu código.');
    }

    // Marcar la cuenta como con datos al iniciar sesión por primera vez
    // tras el registro. A partir de aquí ya no se considera recién
    // registrada y las pantallas mostrarán el contenido completo.
    if (!usuario.conDatos) {
      final idx = usuarios.indexWhere((u) => u.correo == correoNormalizado);
      if (idx != -1) {
        usuario = usuarios[idx].copyWith(conDatos: true);
        usuarios[idx] = usuario;
        await _guardarUsuarios(usuarios);
      }
    }

    await _guardarSesion(usuario);
    return AuthExito(usuario);
  }

  @override
  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kClaveSesion);
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

  Future<void> _guardarSesion(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClaveSesion, u.toJsonString());
  }
}