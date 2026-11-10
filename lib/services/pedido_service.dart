import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_service.dart';
import 'api_config.dart';

enum TipoEntregaApi { restaurante, domicilio }

extension TipoEntregaApiX on TipoEntregaApi {
  String get codigo {
    switch (this) {
      case TipoEntregaApi.restaurante: return 'restaurante';
      case TipoEntregaApi.domicilio:   return 'domicilio';
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoEntregaApi.restaurante: return 'En restaurante';
      case TipoEntregaApi.domicilio:   return 'A domicilio';
    }
  }

  static TipoEntregaApi desdeCodigo(String? codigo) {
    if (codigo == 'domicilio') return TipoEntregaApi.domicilio;
    return TipoEntregaApi.restaurante;
  }
}

enum EstadoPedidoApi {
  pendiente,
  en_preparacion,
  listo,
  entregado,
  cancelado,
}

extension EstadoPedidoApiX on EstadoPedidoApi {
  String get codigo {
    switch (this) {
      case EstadoPedidoApi.pendiente:      return 'pendiente';
      case EstadoPedidoApi.en_preparacion: return 'en_preparacion';
      case EstadoPedidoApi.listo:          return 'listo';
      case EstadoPedidoApi.entregado:      return 'entregado';
      case EstadoPedidoApi.cancelado:      return 'cancelado';
    }
  }

  String get etiqueta {
    switch (this) {
      case EstadoPedidoApi.pendiente:      return 'Pendiente';
      case EstadoPedidoApi.en_preparacion: return 'En cocina';
      case EstadoPedidoApi.listo:          return 'Listo';
      case EstadoPedidoApi.entregado:      return 'Entregado';
      case EstadoPedidoApi.cancelado:      return 'Cancelado';
    }
  }

  /// En domicilio, "listo" significa que el pedido va en camino.
  String etiquetaPara({required bool domicilio}) =>
      (domicilio && this == EstadoPedidoApi.listo) ? 'En camino' : etiqueta;

  double get progreso {
    switch (this) {
      case EstadoPedidoApi.pendiente:      return 0.15;
      case EstadoPedidoApi.en_preparacion: return 0.5;
      case EstadoPedidoApi.listo:          return 0.85;
      case EstadoPedidoApi.entregado:      return 1.0;
      case EstadoPedidoApi.cancelado:      return 0.0;
    }
  }

  static EstadoPedidoApi desdeCodigo(String codigo) {
    switch (codigo) {
      case 'en_preparacion': return EstadoPedidoApi.en_preparacion;
      case 'listo':          return EstadoPedidoApi.listo;
      case 'entregado':      return EstadoPedidoApi.entregado;
      case 'cancelado':      return EstadoPedidoApi.cancelado;
      default:               return EstadoPedidoApi.pendiente;
    }
  }
}

class ItemPedidoApi {
  final int id;
  final int productoId;
  final String? nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? notas;

  const ItemPedidoApi({
    required this.id,
    required this.productoId,
    this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.notas,
  });

  factory ItemPedidoApi.fromJson(Map<String, dynamic> json) => ItemPedidoApi(
        id: json['id'] as int,
        productoId: json['producto_id'] as int,
        nombreProducto: json['nombre_producto'] as String?,
        cantidad: json['cantidad'] as int,
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        notas: json['notas'] as String?,
      );
}

class PedidoApi {
  final int id;
  final int usuarioId;
  final int? mesaId;
  final int? reservaId;
  final EstadoPedidoApi estado;
  final String? notas;
  final double total;
  final List<ItemPedidoApi> items;
  final DateTime creadoEn;
  final TipoEntregaApi tipoEntrega;
  final String? direccionDomicilio;
  final String? telefonoContacto;
  final String? indicacionesDomicilio;
  final double costoEnvio;
  final int? restauranteId;
  final String? restauranteNombre;
  final int? mesaNumero;

  /// Tiempo que la IA estimó para este pedido (minutos). Puede ser null en pedidos viejos.
  final int? minutosEstimados;

  bool get esDomicilio => tipoEntrega == TipoEntregaApi.domicilio;

  /// Número de mesa que ve el cliente (no el id interno). Null en domicilio.
  int? get mesaVisible => mesaNumero ?? mesaId;

  /// "Mesa 4" o "Domicilio" según el tipo de pedido.
  String get lugar => esDomicilio ? 'Domicilio' : 'Mesa ${mesaVisible ?? '-'}';

  /// Estado con el nombre correcto según el tipo (en domicilio: "En camino").
  String get estadoEtiqueta => estado.etiquetaPara(domicilio: esDomicilio);

  double get subtotalPlatos => total - costoEnvio;

  const PedidoApi({
    required this.id,
    required this.usuarioId,
    this.mesaId,
    this.reservaId,
    required this.estado,
    this.notas,
    required this.total,
    required this.items,
    required this.creadoEn,
    this.tipoEntrega = TipoEntregaApi.restaurante,
    this.direccionDomicilio,
    this.telefonoContacto,
    this.indicacionesDomicilio,
    this.costoEnvio = 0,
    this.restauranteId,
    this.restauranteNombre,
    this.mesaNumero,
    this.minutosEstimados,
  });

  factory PedidoApi.fromJson(Map<String, dynamic> json) => PedidoApi(
        id: json['id'] as int,
        usuarioId: json['usuario_id'] as int,
        mesaId: json['mesa_id'] as int?,
        reservaId: json['reserva_id'] as int?,
        estado: EstadoPedidoApiX.desdeCodigo(json['estado'] as String),
        notas: json['notas'] as String?,
        total: (json['total'] as num).toDouble(),
        items: (json['items'] as List<dynamic>)
            .map((i) => ItemPedidoApi.fromJson(i as Map<String, dynamic>))
            .toList(),
        creadoEn: DateTime.parse(json['creado_en'] as String),
        tipoEntrega: TipoEntregaApiX.desdeCodigo(json['tipo_entrega'] as String?),
        direccionDomicilio: json['direccion_domicilio'] as String?,
        telefonoContacto: json['telefono_contacto'] as String?,
        indicacionesDomicilio: json['indicaciones_domicilio'] as String?,
        costoEnvio: (json['costo_envio'] as num?)?.toDouble() ?? 0,
        restauranteId: json['restaurante_id'] as int?,
        restauranteNombre: json['restaurante_nombre'] as String?,
        mesaNumero: json['mesa_numero'] as int?,
        minutosEstimados: (json['minutos_estimados'] as num?)?.toInt(),
      );

  String get totalFormateado {
    final t = total.toInt();
    return '\$${t.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String get horaFormateada {
    final h = creadoEn.toLocal();
    final hora = h.hour.toString().padLeft(2, '0');
    final min  = h.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }
}

class ItemCarrito {
  final Producto producto;
  int cantidad;
  String? notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.notas,
  });

  double get subtotal => producto.precio * cantidad;
}

class Carrito extends ChangeNotifier {
  static final Carrito _instance = Carrito._();
  factory Carrito() => _instance;
  Carrito._();

  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.cantidad);
  double get total => _items.fold(0.0, (s, i) => s + i.subtotal);
  bool get estaVacio => _items.isEmpty;

  String get totalFormateado {
    final t = total.toInt();
    return '\$${t.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Restaurante del carrito (null si está vacío). Cada pedido es de un solo restaurante.
  int? get restauranteId =>
      _items.isEmpty ? null : _items.first.producto.restauranteId;
  String? get restauranteNombre =>
      _items.isEmpty ? null : _items.first.producto.restauranteNombre;

  bool aceptaProducto(Producto p) =>
      _items.isEmpty || _items.first.producto.restauranteId == p.restauranteId;

  /// Devuelve false (sin agregar) si el plato es de otro restaurante.
  bool agregar(Producto producto, {int cantidad = 1}) {
    if (!aceptaProducto(producto)) return false;
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    if (idx >= 0) {
      _items[idx].cantidad += cantidad;
    } else {
      _items.add(ItemCarrito(producto: producto, cantidad: cantidad));
    }
    notifyListeners();
    return true;
  }

  void quitar(int productoId) {
    _items.removeWhere((i) => i.producto.id == productoId);
    notifyListeners();
  }

  void decrementar(int productoId) {
    final idx = _items.indexWhere((i) => i.producto.id == productoId);
    if (idx < 0) return;
    if (_items[idx].cantidad <= 1) {
      _items.removeAt(idx);
    } else {
      _items[idx].cantidad--;
    }
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  int cantidadDe(int productoId) {
    final idx = _items.indexWhere((i) => i.producto.id == productoId);
    return idx >= 0 ? _items[idx].cantidad : 0;
  }
}

sealed class PedidoResultado<T> {
  const PedidoResultado();
}

class PedidoExito<T> extends PedidoResultado<T> {
  final T datos;
  const PedidoExito(this.datos);
}

class PedidoError<T> extends PedidoResultado<T> {
  final String mensaje;
  const PedidoError(this.mensaje);
}

class PedidoService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<PedidoResultado<PedidoApi>> crearPedido({
    int? mesaId,
    required List<ItemCarrito> items,
    String? notas,
    TipoEntregaApi tipoEntrega = TipoEntregaApi.restaurante,
    String? direccionDomicilio,
    String? telefonoContacto,
    String? indicacionesDomicilio,
  }) async {
    try {
      final headers = await _headers();
      final esDomicilio = tipoEntrega == TipoEntregaApi.domicilio;
      final body = jsonEncode({
        if (!esDomicilio && mesaId != null) 'mesa_id': mesaId,
        'items': items
            .map((i) => {
                  'producto_id': i.producto.id,
                  'cantidad': i.cantidad,
                  if (i.notas != null) 'notas': i.notas,
                })
            .toList(),
        if (notas != null && notas.isNotEmpty) 'notas': notas,
        'tipo_entrega': tipoEntrega.codigo,
        if (esDomicilio && direccionDomicilio != null && direccionDomicilio.isNotEmpty)
          'direccion_domicilio': direccionDomicilio,
        if (esDomicilio && telefonoContacto != null && telefonoContacto.isNotEmpty)
          'telefono_contacto': telefonoContacto,
        if (esDomicilio && indicacionesDomicilio != null && indicacionesDomicilio.isNotEmpty)
          'indicaciones_domicilio': indicacionesDomicilio,
      });

      debugPrint('📦 PedidoService.crearPedido → POST $_base/pedidos/');
      debugPrint('📦 body: $body');

      final response = await http
          .post(Uri.parse('$_base/pedidos/'), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('📦 ← status ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoExito(PedidoApi.fromJson(data));
      }
      return PedidoError(_detalleError(response.body, 'Error al crear pedido'));
    } catch (e) {
      debugPrint('📦 PedidoService.crearPedido ERROR: $e');
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<List<PedidoApi>>> misPedidos() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/pedidos/mis-pedidos'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return PedidoExito(data.map((j) => PedidoApi.fromJson(j)).toList());
      }
      return PedidoError('Error ${response.statusCode}');
    } catch (e) {
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<List<PedidoApi>>> todosPedidos() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/pedidos/todos'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return PedidoExito(data.map((j) => PedidoApi.fromJson(j)).toList());
      }
      return PedidoError('Error ${response.statusCode}');
    } catch (e) {
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<List<PedidoApi>>> pedidosActivos() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/pedidos/activos'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return PedidoExito(data.map((j) => PedidoApi.fromJson(j)).toList());
      }
      return PedidoError('Error ${response.statusCode}');
    } catch (e) {
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<PedidoApi>> actualizarEstado({
    required int pedidoId,
    required EstadoPedidoApi nuevoEstado,
  }) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({'estado': nuevoEstado.codigo});
      final response = await http
          .patch(Uri.parse('$_base/pedidos/$pedidoId'),
              headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoExito(PedidoApi.fromJson(data));
      }
      final error = jsonDecode(response.body);
      return PedidoError(error['detail'] ?? 'Error al actualizar');
    } catch (e) {
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<String>> cancelarPedido(int pedidoId) async {
    try {
      final headers = await _headers();
      final response = await http
          .delete(Uri.parse('$_base/pedidos/$pedidoId'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return const PedidoExito('Pedido cancelado');
      }
      final error = jsonDecode(response.body);
      return PedidoError(error['detail'] ?? 'Error al cancelar');
    } catch (e) {
      return PedidoError(_mensajeError(e));
    }
  }

  static Future<PedidoResultado<PedidoApi>> editarItemsPedido({
    required int pedidoId,
    int? mesaId,
    required List<ItemCarrito> items,
    String? notas,
    TipoEntregaApi tipoEntrega = TipoEntregaApi.restaurante,
    String? direccionDomicilio,
  }) async {
    try {
      final headers = await _headers();
      final body = jsonEncode({
        'items': items
            .map((i) => {
                  'producto_id': i.producto.id,
                  'cantidad': i.cantidad,
                  if (i.notas != null) 'notas': i.notas,
                })
            .toList(),
        if (notas != null && notas.isNotEmpty) 'notas': notas,
        'tipo_entrega': tipoEntrega.codigo,
        if (tipoEntrega == TipoEntregaApi.domicilio &&
            direccionDomicilio != null &&
            direccionDomicilio.isNotEmpty)
          'direccion_domicilio': direccionDomicilio,
      });

      debugPrint('✏️ editarItemsPedido → PUT $_base/pedidos/$pedidoId/items');
      debugPrint('✏️ body: $body');

      final response = await http
          .put(Uri.parse('$_base/pedidos/$pedidoId/items'),
              headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('✏️ ← status ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PedidoExito(PedidoApi.fromJson(data));
      }
      return PedidoError(_detalleError(response.body, 'Error al editar pedido'));
    } catch (e) {
      debugPrint('✏️ editarItemsPedido ERROR: $e');
      return PedidoError(_mensajeError(e));
    }
  }

  /// Lee el mensaje del servidor (texto o lista de validaciones de FastAPI).
  static String _detalleError(String cuerpo, String porDefecto) {
    try {
      final d = jsonDecode(cuerpo);
      final detalle = d is Map ? d['detail'] : null;
      if (detalle is String && detalle.isNotEmpty) return detalle;
      if (detalle is List && detalle.isNotEmpty) {
        final primero = detalle.first;
        final msg = primero is Map ? (primero['msg'] ?? '').toString() : primero.toString();
        return msg.replaceFirst('Value error, ', '');
      }
    } catch (_) {}
    return porDefecto;
  }

  static String _mensajeError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Connection refused')) {
      return 'Sin conexión con el servidor';
    }
    if (s.contains('TimeoutException')) return 'El servidor tardó demasiado';
    return 'Error inesperado';
  }
}