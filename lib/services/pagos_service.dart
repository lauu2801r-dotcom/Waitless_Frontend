import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;

// ───────────────────────── Modelos ─────────────────────────
DateTime? _fechaUtc(dynamic v) =>
    v == null ? null : DateTime.parse('${v}Z').toLocal();

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

class ItemFacturaApi {
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const ItemFacturaApi({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ItemFacturaApi.fromJson(Map<String, dynamic> j) => ItemFacturaApi(
        nombre: j['nombre'] as String,
        cantidad: j['cantidad'] as int,
        precioUnitario: _num(j['precio_unitario']),
        subtotal: _num(j['subtotal']),
      );
}

class FacturaApi {
  final int id;
  final String numero;
  final int pedidoId;
  final String concepto;
  final double total;
  final String metodo; // efectivo | tarjeta | billetera | transferencia
  final String estado; // pagada | anulada
  final DateTime? pagadoEn;
  // Solo vienen en el detalle
  final String? clienteEmail;
  final double subtotal;
  final double impuestoPct;
  final double impuesto;
  final double propina;
  final List<ItemFacturaApi> items;
  final String? anuladaMotivo;
  final String? anuladaPorEmail;

  const FacturaApi({
    required this.id,
    required this.numero,
    required this.pedidoId,
    required this.concepto,
    required this.total,
    required this.metodo,
    required this.estado,
    this.pagadoEn,
    this.clienteEmail,
    this.subtotal = 0,
    this.impuestoPct = 0,
    this.impuesto = 0,
    this.propina = 0,
    this.items = const [],
    this.anuladaMotivo,
    this.anuladaPorEmail,
  });

  bool get anulada => estado == 'anulada';

  factory FacturaApi.fromJson(Map<String, dynamic> j) => FacturaApi(
        id: j['id'] as int,
        numero: (j['numero'] ?? 'F-${j['id']}') as String,
        pedidoId: j['pedido_id'] as int,
        concepto: (j['concepto'] ?? '') as String,
        total: _num(j['total']),
        metodo: j['metodo'] as String,
        estado: j['estado'] as String,
        pagadoEn: _fechaUtc(j['pagado_en']),
        clienteEmail: j['cliente_email'] as String?,
        subtotal: _num(j['subtotal']),
        impuestoPct: _num(j['impuesto_pct']),
        impuesto: _num(j['impuesto']),
        propina: _num(j['propina']),
        items: ((j['items'] as List?) ?? [])
            .map((e) => ItemFacturaApi.fromJson(e as Map<String, dynamic>))
            .toList(),
        anuladaMotivo: j['anulada_motivo'] as String?,
        anuladaPorEmail: j['anulada_por_email'] as String?,
      );
}

class PagoApi {
  final int id;
  final int pedidoId;
  final String metodo;
  final double monto;
  final String estado; // aprobado | rechazado
  final String? referencia;
  final String? motivoRechazo;
  final FacturaApi? factura;

  const PagoApi({
    required this.id,
    required this.pedidoId,
    required this.metodo,
    required this.monto,
    required this.estado,
    this.referencia,
    this.motivoRechazo,
    this.factura,
  });

  bool get aprobado => estado == 'aprobado';

  factory PagoApi.fromJson(Map<String, dynamic> j) => PagoApi(
        id: j['id'] as int,
        pedidoId: j['pedido_id'] as int,
        metodo: j['metodo'] as String,
        monto: _num(j['monto']),
        estado: j['estado'] as String,
        referencia: j['referencia'] as String?,
        motivoRechazo: j['motivo_rechazo'] as String?,
        factura: j['factura'] == null
            ? null
            : FacturaApi.fromJson(j['factura'] as Map<String, dynamic>),
      );
}

class ResumenApi {
  final double totalVentas;
  final int totalFacturas;
  final double ticketPromedio;
  final int anuladas;
  final int porCobrar;
  final Map<String, double> totalPorMetodo;

  const ResumenApi({
    required this.totalVentas,
    required this.totalFacturas,
    required this.ticketPromedio,
    required this.anuladas,
    required this.porCobrar,
    required this.totalPorMetodo,
  });

  factory ResumenApi.fromJson(Map<String, dynamic> j) {
    final m = (j['por_metodo'] as Map<String, dynamic>? ?? {});
    return ResumenApi(
      totalVentas: _num(j['total_ventas']),
      totalFacturas: j['total_facturas'] as int,
      ticketPromedio: _num(j['ticket_promedio']),
      anuladas: j['anuladas'] as int,
      porCobrar: j['por_cobrar'] as int,
      totalPorMetodo: {
        for (final e in m.entries) e.key: _num((e.value as Map)['total']),
      },
    );
  }
}

class PorCobrarApi {
  final int pedidoId;
  final String concepto;
  final String estado;
  final double subtotal;
  final double impuesto;
  final double totalEstimado;

  const PorCobrarApi({
    required this.pedidoId,
    required this.concepto,
    required this.estado,
    required this.subtotal,
    required this.impuesto,
    required this.totalEstimado,
  });

  factory PorCobrarApi.fromJson(Map<String, dynamic> j) => PorCobrarApi(
        pedidoId: j['pedido_id'] as int,
        concepto: j['concepto'] as String,
        estado: j['estado'] as String,
        subtotal: _num(j['subtotal']),
        impuesto: _num(j['impuesto']),
        totalEstimado: _num(j['total_estimado']),
      );
}

// ───────────────────────── Servicio ─────────────────────────
class PagosService {
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
      final r = metodo == 'POST'
          ? await http.post(uri, headers: headers, body: body)
          : await http.get(uri, headers: headers);
      if (r.statusCode == 200) {
        return InvExito(convertir(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return InvError(_detalle(r, errorPorDefecto));
    } catch (_) {
      return const InvError('No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  /// periodo: hoy | semana | mes | anio
  static Future<InvResultado<ResumenApi>> resumen(String periodo) => _pedir(
        'GET',
        '/pagos/resumen?periodo=$periodo',
        (j) => ResumenApi.fromJson(j),
        errorPorDefecto: 'No se pudo cargar el resumen',
      );

  static Future<InvResultado<List<FacturaApi>>> facturas({String? desdeIso}) =>
      _pedir(
        'GET',
        '/pagos/facturas?limit=100${desdeIso != null ? '&desde=$desdeIso' : ''}',
        (j) => (j as List).map((e) => FacturaApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar las facturas',
      );

  static Future<InvResultado<List<FacturaApi>>> misFacturas() => _pedir(
        'GET',
        '/pagos/mis-facturas',
        (j) => (j as List).map((e) => FacturaApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar tus facturas',
      );

  static Future<InvResultado<FacturaApi>> factura(int id) => _pedir(
        'GET',
        '/pagos/facturas/$id',
        (j) => FacturaApi.fromJson(j),
        errorPorDefecto: 'No se pudo cargar la factura',
      );

  static Future<InvResultado<List<PorCobrarApi>>> porCobrar() => _pedir(
        'GET',
        '/pagos/por-cobrar',
        (j) => (j as List).map((e) => PorCobrarApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudieron cargar los pedidos por cobrar',
      );

  static Future<InvResultado<PagoApi>> pagar({
    required int pedidoId,
    required String metodo,
    double propina = 0,
    bool simularRechazo = false,
  }) =>
      _pedir(
        'POST',
        '/pagos/',
        (j) => PagoApi.fromJson(j),
        cuerpo: {
          'pedido_id': pedidoId,
          'metodo': metodo,
          'propina': propina,
          'simular_rechazo': simularRechazo,
        },
        errorPorDefecto: 'No se pudo procesar el pago',
      );


  static Future<InvResultado<List<PagoApi>>> pagosDePedido(int pedidoId) =>
      _pedir(
        'GET',
        '/pagos/pedido/$pedidoId',
        (j) => (j as List).map((e) => PagoApi.fromJson(e)).toList(),
        errorPorDefecto: 'No se pudo consultar el pago',
      );

  static Future<InvResultado<FacturaApi>> anular(int id, String motivo) =>
      _pedir(
        'POST',
        '/pagos/facturas/$id/anular',
        (j) => FacturaApi.fromJson(j),
        cuerpo: {'motivo': motivo},
        errorPorDefecto: 'No se pudo anular la factura',
      );
}

// ───────────────────────── Ayudas de presentación ─────────────────────────
const metodosPago = ['tarjeta', 'billetera', 'transferencia', 'efectivo'];

String nombreMetodo(String m) => switch (m) {
      'tarjeta' => 'Tarjeta',
      'billetera' => 'Billetera digital',
      'transferencia' => 'Transferencia',
      'efectivo' => 'Efectivo',
      _ => m,
    };
