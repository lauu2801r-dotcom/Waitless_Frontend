import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;

/// Empleado del restaurante (meseros, cocineros, cajeros).
class EmpleadoApi {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String? cargo; // mesero | cocinero | cajero
  final bool activo;
  final DateTime? creadoEn;

  const EmpleadoApi({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.telefono,
    this.cargo,
    required this.activo,
    this.creadoEn,
  });

  factory EmpleadoApi.fromJson(Map<String, dynamic> j) => EmpleadoApi(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        apellido: (j['apellido'] as String?) ?? '',
        email: j['email'] as String,
        telefono: j['telefono'] as String?,
        cargo: j['cargo'] as String?,
        activo: j['activo'] as bool? ?? true,
        creadoEn: j['creado_en'] == null
            ? null
            : DateTime.tryParse('${j['creado_en']}Z')?.toLocal(),
      );

  String get nombreCompleto => '$nombre $apellido'.trim();
  String get cargoEtiqueta => switch (cargo) {
        'mesero' => 'Mesero',
        'cocinero' => 'Cocinero',
        'cajero' => 'Cajero',
        _ => 'Empleado',
      };

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
}

class PersonalService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String _detalle(http.Response r, String porDefecto) {
    try {
      final d = jsonDecode(utf8.decode(r.bodyBytes))['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        return (d.first['msg'] ?? porDefecto).toString();
      }
    } catch (_) {}
    if (r.statusCode == 401) return 'Tu sesión venció. Vuelve a iniciar sesión.';
    if (r.statusCode == 403) return 'No tienes permiso para hacer esto.';
    return porDefecto;
  }

  static Future<InvResultado<T>> _pedir<T>(
    String metodo,
    String ruta,
    T Function(dynamic json) convertir, {
    Map<String, dynamic>? cuerpo,
    String errorPorDefecto = 'No se pudo completar la acción',
  }) async {
    try {
      final uri = Uri.parse('$_base$ruta');
      final headers = await _headers();
      final body = cuerpo == null ? null : jsonEncode(cuerpo);
      final r = switch (metodo) {
        'POST' => await http.post(uri, headers: headers, body: body),
        'PATCH' => await http.patch(uri, headers: headers, body: body),
        _ => await http.get(uri, headers: headers),
      };
      if (r.statusCode == 200) {
        return InvExito(convertir(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, errorPorDefecto));
    } catch (_) {
      return const InvError(
          'No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  static Future<InvResultado<List<EmpleadoApi>>> listar() => _pedir(
        'GET',
        '/usuarios/',
        (j) => (j as List).map((e) => EmpleadoApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudo cargar el personal',
      );

  static Future<InvResultado<EmpleadoApi>> crear({
    required String nombre,
    required String apellido,
    required String email,
    String? telefono,
    required String cargo,
    required String password,
  }) =>
      _pedir(
        'POST',
        '/usuarios/empleados',
        (j) => EmpleadoApi.fromJson(j),
        cuerpo: {
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'cargo': cargo,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
          'password': password,
        },
        errorPorDefecto: 'No se pudo crear el empleado',
      );

  static Future<InvResultado<EmpleadoApi>> cambiarActivo(int id, bool activo) =>
      _pedir(
        'PATCH',
        '/usuarios/$id',
        (j) => EmpleadoApi.fromJson(j),
        cuerpo: {'activo': activo},
        errorPorDefecto: 'No se pudo actualizar el empleado',
      );
}
