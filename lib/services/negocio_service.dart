import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Perfil de mi restaurante: contacto, horarios (con días especiales) y galería.
class NegocioPerfil {
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? instagram;
  final Map<String, dynamic>? horarios; // {"semana": {...}, "especiales": [...]}
  final List<String> galeria;
  final bool? abiertoAhora;
  final int minutosAlertaMesa;
  final bool domicilioActivo;
  final int costoDomicilio;
  final int pedidoMinimoDomicilio;

  const NegocioPerfil({
    required this.nombre,
    this.direccion,
    this.telefono,
    this.instagram,
    this.horarios,
    this.galeria = const [],
    this.abiertoAhora,
    this.minutosAlertaMesa = 90,
    this.domicilioActivo = true,
    this.costoDomicilio = 5000,
    this.pedidoMinimoDomicilio = 0,
  });

  factory NegocioPerfil.fromJson(Map<String, dynamic> j) => NegocioPerfil(
        nombre: (j['nombre'] ?? '') as String,
        direccion: j['direccion'] as String?,
        telefono: j['telefono'] as String?,
        instagram: j['instagram'] as String?,
        horarios: j['horarios'] is Map
            ? Map<String, dynamic>.from(j['horarios'] as Map)
            : null,
        galeria: ((j['galeria'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        abiertoAhora: j['abierto_ahora'] as bool?,
        minutosAlertaMesa: (j['minutos_alerta_mesa'] as num?)?.toInt() ?? 90,
        domicilioActivo: j['domicilio_activo'] as bool? ?? true,
        costoDomicilio: (j['costo_domicilio'] as num?)?.toInt() ?? 5000,
        pedidoMinimoDomicilio: (j['pedido_minimo_domicilio'] as num?)?.toInt() ?? 0,
      );
}

class NegocioService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Saca el mensaje de error del backend ({"detail": "..."} o lista de validación).
  static String _detalle(String body, String porDefecto) {
    try {
      final d = jsonDecode(body)['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        final msg = (d.first['msg'] ?? porDefecto).toString();
        return msg.replaceFirst('Value error, ', '');
      }
    } catch (_) {}
    return porDefecto;
  }

  static Future<NegocioPerfil> obtener() async {
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/restaurantes/mi-restaurante/datos'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) {
      return NegocioPerfil.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_detalle(r.body, 'No se pudieron cargar los datos del restaurante'));
  }

  /// Guarda solo los campos que se envían (contacto, horarios, galería...).
  static Future<NegocioPerfil> guardar(Map<String, dynamic> cambios) async {
    final r = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/restaurantes/mi-restaurante/datos'),
      headers: await _headers(),
      body: jsonEncode(cambios),
    );
    if (r.statusCode == 200) {
      return NegocioPerfil.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    }
    throw Exception(_detalle(r.body, 'No se pudieron guardar los cambios'));
  }

  static Future<void> cambiarPassword(String actual, String nueva) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
      headers: await _headers(),
      body: jsonEncode({'password_actual': actual, 'nueva_password': nueva}),
    );
    if (r.statusCode != 200) {
      throw Exception(_detalle(r.body, 'No se pudo cambiar la contraseña'));
    }
  }
}
