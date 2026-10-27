import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;

class CalifItem {
  final int productoId;
  final String productoNombre;
  final int estrellas;
  const CalifItem(this.productoId, this.productoNombre, this.estrellas);

  factory CalifItem.fromJson(Map<String, dynamic> j) => CalifItem(
        j['producto_id'] as int,
        (j['producto_nombre'] as String?) ?? '',
        (j['estrellas'] as num).toInt(),
      );
}

/// Estado de la calificación de UN pedido del cliente.
class EstadoCalificacion {
  final int pedidoId;
  final bool pagado;
  final bool calificado;
  final String? comentario;
  final List<CalifItem> items;
  const EstadoCalificacion({
    required this.pedidoId,
    required this.pagado,
    required this.calificado,
    this.comentario,
    this.items = const [],
  });

  factory EstadoCalificacion.fromJson(Map<String, dynamic> j) =>
      EstadoCalificacion(
        pedidoId: j['pedido_id'] as int,
        pagado: j['pagado'] as bool? ?? false,
        calificado: j['calificado'] as bool? ?? false,
        comentario: j['comentario'] as String?,
        items: ((j['items'] as List<dynamic>?) ?? const [])
            .map((e) => CalifItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PlatoCalificado {
  final int productoId;
  final String nombre;
  final double promedio;
  final int total;
  const PlatoCalificado(this.productoId, this.nombre, this.promedio, this.total);

  factory PlatoCalificado.fromJson(Map<String, dynamic> j) => PlatoCalificado(
        j['producto_id'] as int,
        j['nombre'] as String,
        (j['promedio'] as num).toDouble(),
        (j['total'] as num).toInt(),
      );
}

class CalifReciente {
  final int pedidoId;
  final String cliente;
  final String plato;
  final int estrellas;
  final String? comentario;
  final DateTime? creadoEn;
  const CalifReciente(this.pedidoId, this.cliente, this.plato, this.estrellas,
      this.comentario, this.creadoEn);

  factory CalifReciente.fromJson(Map<String, dynamic> j) => CalifReciente(
        j['pedido_id'] as int,
        (j['cliente'] as String?) ?? 'Cliente',
        (j['plato'] as String?) ?? '',
        (j['estrellas'] as num).toInt(),
        j['comentario'] as String?,
        j['creado_en'] == null
            ? null
            : DateTime.tryParse('${j['creado_en']}Z')?.toLocal(),
      );
}

/// Resumen de calificaciones del restaurante (vista del administrador).
class ResumenCalificaciones {
  final double promedio;
  final int total;
  final Map<int, int> distribucion; // estrellas → cantidad
  final List<PlatoCalificado> mejores;
  final List<PlatoCalificado> porMejorar;
  final List<CalifReciente> recientes;
  const ResumenCalificaciones({
    required this.promedio,
    required this.total,
    required this.distribucion,
    required this.mejores,
    required this.porMejorar,
    required this.recientes,
  });

  factory ResumenCalificaciones.fromJson(Map<String, dynamic> j) {
    List<T> lista<T>(String k, T Function(Map<String, dynamic>) f) =>
        ((j[k] as List<dynamic>?) ?? const [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    final dist = <int, int>{};
    (j['distribucion'] as Map<String, dynamic>? ?? const {}).forEach((k, v) {
      dist[int.tryParse(k) ?? 0] = (v as num).toInt();
    });
    return ResumenCalificaciones(
      promedio: (j['promedio'] as num).toDouble(),
      total: (j['total'] as num).toInt(),
      distribucion: dist,
      mejores: lista('mejores', PlatoCalificado.fromJson),
      porMejorar: lista('por_mejorar', PlatoCalificado.fromJson),
      recientes: lista('recientes', CalifReciente.fromJson),
    );
  }
}

class CalificacionesService {
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
      final h = await _headers();
      final r = metodo == 'POST'
          ? await http.post(uri, headers: h, body: jsonEncode(cuerpo))
          : await http.get(uri, headers: h);
      if (r.statusCode == 200) {
        return InvExito(convertir(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, errorPorDefecto));
    } catch (_) {
      return const InvError(
          'No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  static Future<InvResultado<EstadoCalificacion>> deUnPedido(int pedidoId) =>
      _pedir('GET', '/calificaciones/pedido/$pedidoId',
          (j) => EstadoCalificacion.fromJson(j as Map<String, dynamic>));

  /// [estrellasPorPlato]: id del plato → estrellas (1 a 5).
  static Future<InvResultado<EstadoCalificacion>> calificar({
    required int pedidoId,
    required Map<int, int> estrellasPorPlato,
    String? comentario,
  }) =>
      _pedir(
        'POST',
        '/calificaciones/',
        (j) => EstadoCalificacion.fromJson(j as Map<String, dynamic>),
        cuerpo: {
          'pedido_id': pedidoId,
          'items': [
            for (final e in estrellasPorPlato.entries)
              {'producto_id': e.key, 'estrellas': e.value}
          ],
          if (comentario != null && comentario.trim().isNotEmpty)
            'comentario': comentario.trim(),
        },
        errorPorDefecto: 'No se pudo enviar tu calificación',
      );

  static Future<InvResultado<ResumenCalificaciones>> resumen() => _pedir(
        'GET',
        '/calificaciones/resumen',
        (j) => ResumenCalificaciones.fromJson(j as Map<String, dynamic>),
        errorPorDefecto: 'No se pudieron cargar las calificaciones',
      );
}
