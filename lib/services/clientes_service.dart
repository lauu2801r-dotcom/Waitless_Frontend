import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;

// ───────────────────────── Modelos ─────────────────────────
class ResumenClienteApi {
  final int visitas;
  final String nivel;
  final String? siguienteNivel;
  final int? visitasSiguiente;
  final int facturas;
  final int favoritos;
  final double? calificacionPromedio;
  final double totalGastado;

  const ResumenClienteApi({
    required this.visitas,
    required this.nivel,
    this.siguienteNivel,
    this.visitasSiguiente,
    required this.facturas,
    required this.favoritos,
    this.calificacionPromedio,
    required this.totalGastado,
  });

  factory ResumenClienteApi.fromJson(Map<String, dynamic> j) =>
      ResumenClienteApi(
        visitas: j['visitas'] as int,
        nivel: j['nivel'] as String,
        siguienteNivel: j['siguiente_nivel'] as String?,
        visitasSiguiente: j['visitas_siguiente'] as int?,
        facturas: j['facturas'] as int,
        favoritos: j['favoritos'] as int,
        calificacionPromedio: (j['calificacion_promedio'] as num?)?.toDouble(),
        totalGastado: (j['total_gastado'] as num?)?.toDouble() ?? 0,
      );
}

class FavoritoApi {
  final int productoId;
  final String nombre;
  final double precio;
  final String? categoria;
  final bool disponible;

  const FavoritoApi({
    required this.productoId,
    required this.nombre,
    required this.precio,
    this.categoria,
    required this.disponible,
  });

  factory FavoritoApi.fromJson(Map<String, dynamic> j) => FavoritoApi(
        productoId: j['producto_id'] as int,
        nombre: j['nombre'] as String,
        precio: (j['precio'] as num).toDouble(),
        categoria: j['categoria'] as String?,
        disponible: j['disponible'] as bool? ?? true,
      );

  String get emoji {
    switch (categoria?.toLowerCase()) {
      case 'entradas':
        return '🥗';
      case 'principales':
        return '🍽️';
      case 'postres':
        return '🍰';
      case 'bebidas':
        return '🍹';
      default:
        return '🍴';
    }
  }
}

// ───────────────────────── Servicio ─────────────────────────
class ClientesService {
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
    } catch (_) {}
    if (r.statusCode == 401) return 'Tu sesión venció. Vuelve a iniciar sesión.';
    return porDefecto;
  }

  static Future<InvResultado<T>> _pedir<T>(
    String metodo,
    String ruta,
    T Function(dynamic json) convertir, {
    String errorPorDefecto = 'No se pudo completar la acción',
  }) async {
    try {
      final uri = Uri.parse('$_base$ruta');
      final h = await _headers();
      late http.Response r;
      switch (metodo) {
        case 'PUT':
          r = await http.put(uri, headers: h);
          break;
        case 'DELETE':
          r = await http.delete(uri, headers: h);
          break;
        default:
          r = await http.get(uri, headers: h);
      }
      if (r.statusCode == 200 || r.statusCode == 204) {
        final cuerpo = r.statusCode == 204 || r.bodyBytes.isEmpty
            ? null
            : jsonDecode(utf8.decode(r.bodyBytes));
        return InvExito(convertir(cuerpo));
      }
      return InvError(_detalle(r, errorPorDefecto));
    } catch (_) {
      return const InvError(
          'No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  static Future<InvResultado<ResumenClienteApi>> resumen() => _pedir(
        'GET',
        '/clientes/resumen',
        (j) => ResumenClienteApi.fromJson(j),
        errorPorDefecto: 'No se pudo cargar tu perfil',
      );

  static Future<InvResultado<List<FavoritoApi>>> favoritos() => _pedir(
        'GET',
        '/clientes/favoritos',
        (j) => (j as List).map((e) => FavoritoApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar tus favoritos',
      );

  static Future<InvResultado<bool>> marcarFavorito(int productoId) => _pedir(
        'PUT',
        '/clientes/favoritos/$productoId',
        (_) => true,
        errorPorDefecto: 'No se pudo guardar el favorito',
      );

  static Future<InvResultado<bool>> quitarFavorito(int productoId) => _pedir(
        'DELETE',
        '/clientes/favoritos/$productoId',
        (_) => true,
        errorPorDefecto: 'No se pudo quitar el favorito',
      );
}
