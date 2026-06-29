import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────────────
//  MODELOS
// ─────────────────────────────────────────────────────────────

class TopPlatoApi {
  final int productoId;
  final String nombre;
  final int vendidos;
  final double ingresos;

  const TopPlatoApi({
    required this.productoId,
    required this.nombre,
    required this.vendidos,
    required this.ingresos,
  });

  factory TopPlatoApi.fromJson(Map<String, dynamic> json) => TopPlatoApi(
        productoId: json['producto_id'] as int,
        nombre: json['nombre'] as String,
        vendidos: json['vendidos'] as int,
        ingresos: (json['ingresos'] as num).toDouble(),
      );

  String get ingresosFormateado {
    final i = ingresos.toInt();
    return '\$${i.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

class PedidoRecienteApi {
  final int id;
  final int mesaId;
  final double total;
  final String estado;
  final int haceMinutos;

  const PedidoRecienteApi({
    required this.id,
    required this.mesaId,
    required this.total,
    required this.estado,
    required this.haceMinutos,
  });

  factory PedidoRecienteApi.fromJson(Map<String, dynamic> json) =>
      PedidoRecienteApi(
        id: json['id'] as int,
        mesaId: json['mesa_id'] as int,
        total: (json['total'] as num).toDouble(),
        estado: json['estado'] as String,
        haceMinutos: json['hace_minutos'] as int,
      );

  String get tiempoFormateado {
    if (haceMinutos < 1) return 'ahora';
    if (haceMinutos < 60) return 'hace $haceMinutos min';
    final h = haceMinutos ~/ 60;
    return 'hace ${h}h';
  }

  String get etiquetaEstado {
    switch (estado) {
      case 'pendiente':      return 'Nuevo';
      case 'en_preparacion': return 'Preparando';
      case 'listo':          return 'Listo';
      case 'entregado':      return 'Entregado';
      default:               return estado;
    }
  }
}

class DashboardApi {
  final double ventasHoy;
  final int pedidosActivos;
  final int mesasOcupadas;
  final int totalMesas;
  final int clientesHoy;
  final List<PedidoRecienteApi> pedidosRecientes;
  final List<TopPlatoApi> topPlatos;

  const DashboardApi({
    required this.ventasHoy,
    required this.pedidosActivos,
    required this.mesasOcupadas,
    required this.totalMesas,
    required this.clientesHoy,
    required this.pedidosRecientes,
    required this.topPlatos,
  });

  factory DashboardApi.fromJson(Map<String, dynamic> json) => DashboardApi(
        ventasHoy: (json['ventas_hoy'] as num).toDouble(),
        pedidosActivos: json['pedidos_activos'] as int,
        mesasOcupadas: json['mesas_ocupadas'] as int,
        totalMesas: json['total_mesas'] as int,
        clientesHoy: json['clientes_hoy'] as int,
        pedidosRecientes: (json['pedidos_recientes'] as List<dynamic>)
            .map((j) => PedidoRecienteApi.fromJson(j as Map<String, dynamic>))
            .toList(),
        topPlatos: (json['top_platos'] as List<dynamic>)
            .map((j) => TopPlatoApi.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

  String get ventasFormateado {
    final v = ventasHoy.toInt();
    return '\$${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String get mesasFormateado => '$mesasOcupadas/$totalMesas';

  String get porcentajeMesas {
    if (totalMesas == 0) return '0%';
    return '${((mesasOcupadas / totalMesas) * 100).toStringAsFixed(0)}%';
  }
}

// ─────────────────────────────────────────────────────────────
//  SERVICIO
// ─────────────────────────────────────────────────────────────

sealed class DashboardResultado {}

class DashboardExito extends DashboardResultado {
  final DashboardApi datos;
  DashboardExito(this.datos);
}

class DashboardError extends DashboardResultado {
  final String mensaje;
  DashboardError(this.mensaje);
}

class DashboardService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<DashboardResultado> obtenerDashboard() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/reportes/dashboard'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DashboardExito(DashboardApi.fromJson(data));
      }
      return DashboardError('Error ${response.statusCode}');
    } catch (e) {
      final s = e.toString();
      if (s.contains('SocketException') || s.contains('Connection refused')) {
        return DashboardError('Sin conexión con el servidor');
      }
      if (s.contains('TimeoutException')) {
        return DashboardError('El servidor tardó demasiado');
      }
      return DashboardError('Error inesperado');
    }
  }
}