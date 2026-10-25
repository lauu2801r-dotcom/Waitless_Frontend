import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;

// ───────────────────────── Modelos ─────────────────────────
DateTime? _fechaUtc(dynamic v) =>
    v == null ? null : DateTime.parse('${v}Z').toLocal();

class ProveedorFullApi {
  final int id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? productosOfrecidos;
  final String? condiciones;

  const ProveedorFullApi({
    required this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.email,
    this.productosOfrecidos,
    this.condiciones,
  });

  factory ProveedorFullApi.fromJson(Map<String, dynamic> j) => ProveedorFullApi(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        contacto: j['contacto'] as String?,
        telefono: j['telefono'] as String?,
        email: j['email'] as String?,
        productosOfrecidos: j['productos_ofrecidos'] as String?,
        condiciones: j['condiciones'] as String?,
      );
}

class MetricasApi {
  final int proveedorId;
  final int totalOrdenes;
  final int completas;
  final int parciales;
  final int pendientes;
  final int canceladas;
  final double cumplimientoPct;
  final double? puntualidadPct;
  final double? diasPromedio;

  const MetricasApi({
    required this.proveedorId,
    required this.totalOrdenes,
    required this.completas,
    required this.parciales,
    required this.pendientes,
    required this.canceladas,
    required this.cumplimientoPct,
    this.puntualidadPct,
    this.diasPromedio,
  });

  factory MetricasApi.fromJson(Map<String, dynamic> j) => MetricasApi(
        proveedorId: j['proveedor_id'] as int,
        totalOrdenes: j['total_ordenes'] as int,
        completas: j['completas'] as int,
        parciales: j['parciales'] as int,
        pendientes: j['pendientes'] as int,
        canceladas: j['canceladas'] as int,
        cumplimientoPct: (j['cumplimiento_pct'] as num).toDouble(),
        puntualidadPct: (j['puntualidad_pct'] as num?)?.toDouble(),
        diasPromedio: (j['dias_promedio_entrega'] as num?)?.toDouble(),
      );
}

class ItemOrdenApi {
  final int id;
  final int insumoId;
  final String insumoNombre;
  final String unidad;
  final double pedida;
  final double recibida;
  final double costo;
  final double subtotal;

  const ItemOrdenApi({
    required this.id,
    required this.insumoId,
    required this.insumoNombre,
    required this.unidad,
    required this.pedida,
    required this.recibida,
    required this.costo,
    required this.subtotal,
  });

  double get falta => (pedida - recibida) < 0 ? 0 : pedida - recibida;

  factory ItemOrdenApi.fromJson(Map<String, dynamic> j) => ItemOrdenApi(
        id: j['id'] as int,
        insumoId: j['insumo_id'] as int,
        insumoNombre: (j['insumo_nombre'] as String?) ?? 'Insumo',
        unidad: (j['unidad'] as String?) ?? '',
        pedida: (j['cantidad_pedida'] as num).toDouble(),
        recibida: (j['cantidad_recibida'] as num).toDouble(),
        costo: (j['costo_unitario'] as num).toDouble(),
        subtotal: (j['subtotal'] as num).toDouble(),
      );
}

class HistorialOrdenApi {
  final String estado;
  final String detalle;
  final String? usuarioEmail;
  final DateTime? creadoEn;

  const HistorialOrdenApi({
    required this.estado,
    required this.detalle,
    this.usuarioEmail,
    this.creadoEn,
  });

  factory HistorialOrdenApi.fromJson(Map<String, dynamic> j) => HistorialOrdenApi(
        estado: j['estado'] as String,
        detalle: (j['detalle'] as String?) ?? '',
        usuarioEmail: j['usuario_email'] as String?,
        creadoEn: _fechaUtc(j['creado_en']),
      );
}

class OrdenApi {
  final int id;
  final int proveedorId;
  final String proveedorNombre;
  final String estado; // pendiente | parcial | completa | cancelada
  final DateTime? fechaEsperada;
  final DateTime? fechaCumplimiento;
  final String? notas;
  final double total;
  final String? creadoPorEmail;
  final DateTime? creadoEn;
  final List<ItemOrdenApi> items;
  final List<HistorialOrdenApi> historial;

  const OrdenApi({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.estado,
    this.fechaEsperada,
    this.fechaCumplimiento,
    this.notas,
    required this.total,
    this.creadoPorEmail,
    this.creadoEn,
    this.items = const [],
    this.historial = const [],
  });

  bool get sePuedeRecibir => estado == 'pendiente' || estado == 'parcial';

  factory OrdenApi.fromJson(Map<String, dynamic> j) => OrdenApi(
        id: j['id'] as int,
        proveedorId: j['proveedor_id'] as int,
        proveedorNombre: (j['proveedor_nombre'] as String?) ?? 'Proveedor',
        estado: j['estado'] as String,
        fechaEsperada: j['fecha_entrega_esperada'] == null
            ? null
            : DateTime.parse(j['fecha_entrega_esperada'] as String),
        fechaCumplimiento: _fechaUtc(j['fecha_cumplimiento']),
        notas: j['notas'] as String?,
        total: (j['total'] as num).toDouble(),
        creadoPorEmail: j['creado_por_email'] as String?,
        creadoEn: _fechaUtc(j['creado_en']),
        items: ((j['items'] as List?) ?? [])
            .map((e) => ItemOrdenApi.fromJson(e as Map<String, dynamic>))
            .toList(),
        historial: ((j['historial'] as List?) ?? [])
            .map((e) => HistorialOrdenApi.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ───────────────────────── Servicio ─────────────────────────
class ComprasService {
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

  /// Hace la petición y convierte la respuesta con [convertir].
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
      late http.Response r;
      switch (metodo) {
        case 'POST':
          r = await http.post(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          r = await http.patch(uri, headers: headers, body: body);
          break;
        default:
          r = await http.get(uri, headers: headers);
      }
      if (r.statusCode == 200) {
        return InvExito(convertir(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, errorPorDefecto));
    } catch (_) {
      return const InvError('No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  static Future<InvResultado<List<OrdenApi>>> ordenes() => _pedir(
        'GET',
        '/compras/ordenes?limit=200',
        (j) => (j as List).map((e) => OrdenApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar las órdenes',
      );

  static Future<InvResultado<OrdenApi>> orden(int id) => _pedir(
        'GET',
        '/compras/ordenes/$id',
        (j) => OrdenApi.fromJson(j),
        errorPorDefecto: 'No se pudo cargar la orden',
      );

  static Future<InvResultado<OrdenApi>> crearOrden({
    required int proveedorId,
    DateTime? fechaEsperada,
    String? notas,
    required List<({int insumoId, double cantidad, double costo})> items,
  }) =>
      _pedir(
        'POST',
        '/compras/ordenes',
        (j) => OrdenApi.fromJson(j),
        cuerpo: {
          'proveedor_id': proveedorId,
          if (fechaEsperada != null)
            'fecha_entrega_esperada':
                '${fechaEsperada.year}-${fechaEsperada.month.toString().padLeft(2, '0')}-${fechaEsperada.day.toString().padLeft(2, '0')}',
          if (notas != null && notas.trim().isNotEmpty) 'notas': notas.trim(),
          'items': items
              .map((i) => {
                    'insumo_id': i.insumoId,
                    'cantidad': i.cantidad,
                    'costo_unitario': i.costo,
                  })
              .toList(),
        },
        errorPorDefecto: 'No se pudo crear la orden',
      );

  static Future<InvResultado<OrdenApi>> recibir(
    int ordenId,
    List<({int itemId, double cantidad})> items,
  ) =>
      _pedir(
        'POST',
        '/compras/ordenes/$ordenId/recibir',
        (j) => OrdenApi.fromJson(j),
        cuerpo: {
          'items': items
              .map((i) => {'item_id': i.itemId, 'cantidad': i.cantidad})
              .toList(),
        },
        errorPorDefecto: 'No se pudo registrar la recepción',
      );

  static Future<InvResultado<OrdenApi>> cancelar(int ordenId) => _pedir(
        'POST',
        '/compras/ordenes/$ordenId/cancelar',
        (j) => OrdenApi.fromJson(j),
        errorPorDefecto: 'No se pudo cancelar la orden',
      );

  static Future<InvResultado<List<ProveedorFullApi>>> proveedores() => _pedir(
        'GET',
        '/inventario/proveedores',
        (j) => (j as List).map((e) => ProveedorFullApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar los proveedores',
      );

  static Future<InvResultado<ProveedorFullApi>> crearProveedor({
    required String nombre,
    String? contacto,
    String? telefono,
    String? email,
    String? productosOfrecidos,
    String? condiciones,
  }) {
    String? limpio(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return _pedir(
      'POST',
      '/inventario/proveedores',
      (j) => ProveedorFullApi.fromJson(j),
      cuerpo: {
        'nombre': nombre.trim(),
        if (limpio(contacto) != null) 'contacto': limpio(contacto),
        if (limpio(telefono) != null) 'telefono': limpio(telefono),
        if (limpio(email) != null) 'email': limpio(email),
        if (limpio(productosOfrecidos) != null)
          'productos_ofrecidos': limpio(productosOfrecidos),
        if (limpio(condiciones) != null) 'condiciones': limpio(condiciones),
      },
      errorPorDefecto: 'No se pudo crear el proveedor',
    );
  }

  static Future<InvResultado<ProveedorFullApi>> desactivarProveedor(int id) => _pedir(
        'PATCH',
        '/inventario/proveedores/$id',
        (j) => ProveedorFullApi.fromJson(j),
        cuerpo: {'activo': false},
        errorPorDefecto: 'No se pudo desactivar el proveedor',
      );

  static Future<InvResultado<List<MetricasApi>>> metricas() => _pedir(
        'GET',
        '/compras/metricas',
        (j) => (j as List).map((e) => MetricasApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar las métricas',
      );
}
