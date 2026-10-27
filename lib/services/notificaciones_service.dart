import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'inventario_service.dart' show InvResultado, InvExito, InvError;
import 'tiempo_real_service.dart';

/// Una notificación del usuario (viene del backend: /notificaciones/).
class NotificacionApi {
  final int id;
  final String tipo; // pedido | pago | reserva | calificacion | promo | sistema
  final String titulo;
  final String? detalle;
  final int? referenciaId;
  final bool leida;
  final DateTime? creadoEn;

  const NotificacionApi({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.detalle,
    this.referenciaId,
    required this.leida,
    this.creadoEn,
  });

  factory NotificacionApi.fromJson(Map<String, dynamic> j) => NotificacionApi(
        id: j['id'] as int,
        tipo: (j['tipo'] as String?) ?? 'sistema',
        titulo: j['titulo'] as String,
        detalle: j['detalle'] as String?,
        referenciaId: j['referencia_id'] as int?,
        leida: j['leida'] as bool? ?? false,
        // el servidor guarda la hora en UTC sin zona → se le agrega la 'Z'
        creadoEn: j['creado_en'] == null
            ? null
            : DateTime.tryParse('${j['creado_en']}Z')?.toLocal(),
      );
}

class NotificacionesService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<InvResultado<T>> _pedir<T>(
    String metodo,
    String ruta,
    T Function(dynamic json) convertir,
  ) async {
    try {
      final uri = Uri.parse('$_base$ruta');
      final h = await _headers();
      final r = switch (metodo) {
        'POST' => await http.post(uri, headers: h),
        'PATCH' => await http.patch(uri, headers: h),
        'DELETE' => await http.delete(uri, headers: h),
        _ => await http.get(uri, headers: h),
      };
      if (r.statusCode == 200) {
        return InvExito(convertir(jsonDecode(utf8.decode(r.bodyBytes))));
      }
      return const InvError('No se pudo cargar tus notificaciones');
    } catch (_) {
      return const InvError(
          'No se pudo conectar con el servidor. Revisa tu conexión.');
    }
  }

  static Future<InvResultado<List<NotificacionApi>>> listar() => _pedir(
        'GET',
        '/notificaciones/',
        (j) => (j as List)
            .map((e) => NotificacionApi.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Future<InvResultado<int>> contador() => _pedir(
        'GET',
        '/notificaciones/contador',
        (j) => (j['no_leidas'] as num).toInt(),
      );

  static Future<InvResultado<int>> leerTodas() => _pedir(
        'POST',
        '/notificaciones/leer-todas',
        (j) => (j['no_leidas'] as num).toInt(),
      );

  static Future<InvResultado<bool>> eliminar(int id) =>
      _pedir('DELETE', '/notificaciones/$id', (_) => true);
}

/// Estado global de las notificaciones del cliente (campana de Inicio).
/// Se enciende al entrar a la app (MainShell) y se apaga al salir.
/// Cuando el backend crea una notificación llega por WebSocket
/// ('mis-eventos') y aquí se refresca la lista y se avisa con un toast.
class NotificacionesCenter extends ChangeNotifier {
  NotificacionesCenter._();
  static final NotificacionesCenter instancia = NotificacionesCenter._();

  List<NotificacionApi> items = [];
  int noLeidas = 0;
  bool cargando = false;
  String? error;

  TiempoRealConexion? _tr;
  StreamSubscription? _sub;
  final StreamController<String> _avisos = StreamController<String>.broadcast();

  /// Títulos de notificaciones nuevas que llegan en vivo (para mostrar un toast).
  Stream<String> get avisos => _avisos.stream;

  void iniciar() {
    if (_tr != null) return;
    _tr = TiempoRealConexion('mis-eventos')..conectar();
    _sub = _tr!.eventos.listen((e) {
      if (e['tipo'] == 'notificacion') {
        final titulo = (e['titulo'] ?? e['mensaje'] ?? '').toString();
        refrescar();
        if (titulo.isNotEmpty) _avisos.add(titulo);
      }
    });
    refrescar();
  }

  void detener() {
    _sub?.cancel();
    _sub = null;
    _tr?.cerrar();
    _tr = null;
    items = [];
    noLeidas = 0;
    notifyListeners();
  }

  Future<void> refrescar() async {
    cargando = true;
    final r = await NotificacionesService.listar();
    cargando = false;
    switch (r) {
      case InvExito(:final datos):
        items = datos;
        noLeidas = datos.where((n) => !n.leida).length;
        error = null;
      case InvError(:final mensaje):
        error = mensaje;
        debugPrint('Notificaciones: $mensaje');
    }
    notifyListeners();
  }

  Future<void> marcarTodasLeidas() async {
    if (noLeidas == 0) return;
    final r = await NotificacionesService.leerTodas();
    if (r is InvExito<int>) {
      items = items
          .map((n) => n.leida
              ? n
              : NotificacionApi(
                  id: n.id,
                  tipo: n.tipo,
                  titulo: n.titulo,
                  detalle: n.detalle,
                  referenciaId: n.referenciaId,
                  leida: true,
                  creadoEn: n.creadoEn))
          .toList();
      noLeidas = 0;
      notifyListeners();
    }
  }

  Future<void> eliminar(int id) async {
    final antes = items;
    items = items.where((n) => n.id != id).toList();
    noLeidas = items.where((n) => !n.leida).length;
    notifyListeners();
    final r = await NotificacionesService.eliminar(id);
    if (r is InvError<bool>) {
      items = antes; // no se pudo borrar → se restaura
      noLeidas = items.where((n) => !n.leida).length;
      notifyListeners();
    }
  }
}
