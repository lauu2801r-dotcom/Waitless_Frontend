import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_config.dart';

/// Conexión WebSocket a un canal del backend, con reconexión automática.
///
/// Canales:
///  - 'pedidos'     (admin / empleado)
///  - 'dashboard'   (admin / empleado)
///  - 'mesas'       (cualquier usuario)
///  - 'mis-eventos' (avisos personales del cliente)
///
/// Uso:
///   final tr = TiempoRealConexion('pedidos')..conectar();
///   _sub = tr.eventos.listen((e) { ... });
///   // en dispose(): _sub.cancel(); tr.cerrar();
class TiempoRealConexion {
  final String canal;
  TiempoRealConexion(this.canal);

  final StreamController<Map<String, dynamic>> _controlador =
      StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _canal;
  StreamSubscription? _sub;
  Timer? _reintento;
  bool _cerrado = false;
  int _intentos = 0;

  /// Eventos JSON que llegan del servidor (ya decodificados).
  Stream<Map<String, dynamic>> get eventos => _controlador.stream;

  static String _urlWs(String canal, String token) {
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/ws/$canal?token=${Uri.encodeQueryComponent(token)}';
  }

  Future<void> conectar() async {
    if (_cerrado) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    if (token == null) return; // sin sesión no hay tiempo real

    try {
      final canal = WebSocketChannel.connect(Uri.parse(_urlWs(this.canal, token)));
      _canal = canal;
      _sub = canal.stream.listen(
        (dato) {
          _intentos = 0;
          try {
            final json = jsonDecode(dato as String);
            if (json is Map<String, dynamic>) _controlador.add(json);
          } catch (_) {}
        },
        onDone: _programarReintento,
        onError: (_) => _programarReintento(),
        cancelOnError: true,
      );
    } catch (_) {
      _programarReintento();
    }
  }

  void _programarReintento() {
    if (_cerrado) return;
    _sub?.cancel();
    _sub = null;
    _reintento?.cancel();
    // 2s, 4s, 8s... hasta máximo 30s
    final espera = Duration(seconds: (2 << (_intentos < 4 ? _intentos : 4)).clamp(2, 30).toInt());
    _intentos++;
    _reintento = Timer(espera, conectar);
  }

  void cerrar() {
    _cerrado = true;
    _reintento?.cancel();
    _sub?.cancel();
    _canal?.sink.close();
    _controlador.close();
  }
}
