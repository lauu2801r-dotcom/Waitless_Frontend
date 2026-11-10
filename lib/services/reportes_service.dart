import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Descarga los reportes (CSV / PDF) del restaurante del administrador.
class ReportesService {
  ReportesService._();

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// [archivo]: 'ventas.csv', 'inventario.csv', 'calificaciones.csv' o 'resumen.pdf'.
  /// Devuelve la ruta del archivo guardado, o un mensaje de error.
  static Future<({String? ruta, String? error})> descargar(
    String archivo, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('waitless.token');
      if (token == null) return (ruta: null, error: 'Inicia sesión de nuevo');

      final params = <String, String>{
        if (desde != null) 'desde': _fecha(desde),
        if (hasta != null) 'hasta': _fecha(hasta),
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}/reportes/$archivo')
          .replace(queryParameters: params.isEmpty ? null : params);

      final r = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 40));

      if (r.statusCode != 200) {
        String mensaje = 'No se pudo generar el reporte (${r.statusCode})';
        try {
          final data = jsonDecode(utf8.decode(r.bodyBytes));
          if (data is Map && data['detail'] is String) {
            mensaje = data['detail'] as String;
          }
        } catch (_) {}
        return (ruta: null, error: mensaje);
      }

      // Nombre que sugiere el servidor (waitless_ventas_2026-11-09.csv)
      var nombre = 'waitless_$archivo';
      final cd = r.headers['content-disposition'] ?? '';
      final m = RegExp(r'filename="([^"]+)"').firstMatch(cd);
      if (m != null) nombre = m.group(1)!;

      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$nombre');
      await f.writeAsBytes(r.bodyBytes, flush: true);
      return (ruta: f.path, error: null);
    } catch (e) {
      return (ruta: null, error: 'Error de conexión: $e');
    }
  }
}
