import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

// ───────────────────────── Modelos ─────────────────────────
class InsumoApi {
  final int id;
  final String nombre;
  final String categoria;
  final String unidad;
  final String emoji;
  final double stockActual;
  final double stockMinimo;
  final double costoUnitario;
  final double valor;
  final String estado; // ok | bajo | agotado
  final int? proveedorId;
  final String? proveedorNombre;

  const InsumoApi({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.emoji,
    required this.stockActual,
    required this.stockMinimo,
    required this.costoUnitario,
    required this.valor,
    required this.estado,
    this.proveedorId,
    this.proveedorNombre,
  });

  factory InsumoApi.fromJson(Map<String, dynamic> j) => InsumoApi(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        categoria: j['categoria'] as String,
        unidad: j['unidad'] as String,
        emoji: (j['emoji'] as String?)?.isNotEmpty == true
            ? j['emoji'] as String
            : '📦',
        stockActual: (j['stock_actual'] as num).toDouble(),
        stockMinimo: (j['stock_minimo'] as num).toDouble(),
        costoUnitario: (j['costo_unitario'] as num).toDouble(),
        valor: (j['valor'] as num).toDouble(),
        estado: j['estado'] as String,
        proveedorId: j['proveedor_id'] as int?,
        proveedorNombre: j['proveedor_nombre'] as String?,
      );
}

class ProveedorApi {
  final int id;
  final String nombre;
  const ProveedorApi({required this.id, required this.nombre});

  factory ProveedorApi.fromJson(Map<String, dynamic> j) =>
      ProveedorApi(id: j['id'] as int, nombre: j['nombre'] as String);
}

class MovimientoApi {
  final int id;
  final int insumoId;
  final String insumoNombre;
  final String unidad;
  final bool esEntrada;
  final double cantidad;
  final String? motivo;
  final double stockResultante;
  final String? usuarioEmail;
  final DateTime? creadoEn;

  const MovimientoApi({
    required this.id,
    required this.insumoId,
    required this.insumoNombre,
    required this.unidad,
    required this.esEntrada,
    required this.cantidad,
    this.motivo,
    required this.stockResultante,
    this.usuarioEmail,
    this.creadoEn,
  });

  factory MovimientoApi.fromJson(Map<String, dynamic> j) => MovimientoApi(
        id: j['id'] as int,
        insumoId: j['insumo_id'] as int,
        insumoNombre: (j['insumo_nombre'] as String?) ?? 'Insumo',
        unidad: (j['unidad'] as String?) ?? '',
        esEntrada: j['tipo'] == 'entrada',
        cantidad: (j['cantidad'] as num).toDouble(),
        motivo: j['motivo'] as String?,
        stockResultante: (j['stock_resultante'] as num).toDouble(),
        usuarioEmail: j['usuario_email'] as String?,
        // El servidor guarda la hora en UTC (sin zona): la convertimos a hora local.
        creadoEn: j['creado_en'] == null
            ? null
            : DateTime.parse('${j['creado_en']}Z').toLocal(),
      );
}

// ───────────────────────── Resultado ─────────────────────────
sealed class InvResultado<T> {
  const InvResultado();
}

class InvExito<T> extends InvResultado<T> {
  final T datos;
  const InvExito(this.datos);
}

class InvError<T> extends InvResultado<T> {
  final String mensaje;
  const InvError(this.mensaje);
}

// ───────────────────────── Servicio ─────────────────────────
class InventarioService {
  static String get _base => '${ApiConfig.baseUrl}/inventario';

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Saca un mensaje legible del error que manda el servidor.
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

  static String _errorRed(Object e) =>
      'No se pudo conectar con el servidor. Revisa tu conexión.';

  static Future<InvResultado<List<InsumoApi>>> insumos() async {
    try {
      final r = await http
          .get(Uri.parse('$_base/insumos'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(r.bodyBytes));
        return InvExito(data.map((j) => InsumoApi.fromJson(j)).toList());
      }
      return InvError(_detalle(r, 'Error ${r.statusCode} al cargar el inventario'));
    } catch (e) {
      return InvError(_errorRed(e));
    }
  }

  static Future<InvResultado<List<ProveedorApi>>> proveedores() async {
    try {
      final r = await http
          .get(Uri.parse('$_base/proveedores'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(r.bodyBytes));
        return InvExito(data.map((j) => ProveedorApi.fromJson(j)).toList());
      }
      return InvError(_detalle(r, 'Error al cargar proveedores'));
    } catch (e) {
      return InvError(_errorRed(e));
    }
  }

  static Future<InvResultado<InsumoApi>> crearInsumo({
    required String nombre,
    required String categoria,
    required String unidad,
    required double stockInicial,
    required double stockMinimo,
    required double costoUnitario,
    int? proveedorId,
    String? emoji,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_base/insumos'),
            headers: await _headers(),
            body: jsonEncode({
              'nombre': nombre,
              'categoria': categoria,
              'unidad': unidad,
              'stock_inicial': stockInicial,
              'stock_minimo': stockMinimo,
              'costo_unitario': costoUnitario,
              if (proveedorId != null) 'proveedor_id': proveedorId,
              if (emoji != null && emoji.isNotEmpty) 'emoji': emoji,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        return InvExito(InsumoApi.fromJson(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, 'No se pudo crear el producto'));
    } catch (e) {
      return InvError(_errorRed(e));
    }
  }

  static Future<InvResultado<MovimientoApi>> registrarMovimiento({
    required int insumoId,
    required bool esEntrada,
    required double cantidad,
    String? motivo,
  }) async {
    try {
      final r = await http
          .post(
            Uri.parse('$_base/movimientos'),
            headers: await _headers(),
            body: jsonEncode({
              'insumo_id': insumoId,
              'tipo': esEntrada ? 'entrada' : 'salida',
              'cantidad': cantidad,
              if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        return InvExito(MovimientoApi.fromJson(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, 'No se pudo registrar el movimiento'));
    } catch (e) {
      return InvError(_errorRed(e));
    }
  }

  static Future<InvResultado<List<MovimientoApi>>> movimientos({
    int? insumoId,
    bool? soloEntradas, // true = entradas, false = salidas, null = todos
    DateTime? desde,
    DateTime? hasta,
    int limite = 100,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limite',
        if (insumoId != null) 'insumo_id': '$insumoId',
        if (soloEntradas != null) 'tipo': soloEntradas ? 'entrada' : 'salida',
        // Convertimos a UTC porque así guarda las horas el servidor.
        if (desde != null) 'desde': desde.toUtc().toIso8601String().replaceAll('Z', ''),
        if (hasta != null) 'hasta': hasta.toUtc().toIso8601String().replaceAll('Z', ''),
      };
      final uri = Uri.parse('$_base/movimientos').replace(queryParameters: params);
      final r = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(r.bodyBytes));
        return InvExito(data.map((j) => MovimientoApi.fromJson(j)).toList());
      }
      return InvError(_detalle(r, 'No se pudo cargar el historial'));
    } catch (e) {
      return InvError(_errorRed(e));
    }
  }
}
