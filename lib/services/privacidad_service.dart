import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Derechos del titular de datos (Ley 1581 de 2012): ver mis datos y eliminar mi cuenta.
class PrivacidadService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String _detalle(String body, String porDefecto) {
    try {
      final d = jsonDecode(body)['detail'];
      if (d is String) return d;
    } catch (_) {}
    return porDefecto;
  }

  /// Devuelve el JSON con todo lo que el sistema guarda de la persona, ya formateado.
  static Future<String> misDatos() async {
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/privacidad/mis-datos'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(utf8.decode(r.bodyBytes)));
    }
    throw Exception(_detalle(r.body, 'No se pudieron obtener tus datos'));
  }

  static Future<void> eliminarCuenta(String password, String confirmacion) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/privacidad/eliminar-cuenta'),
      headers: await _headers(),
      body: jsonEncode({'password': password, 'confirmacion': confirmacion}),
    );
    if (r.statusCode != 200) {
      throw Exception(_detalle(r.body, 'No se pudo eliminar la cuenta'));
    }
  }
}
