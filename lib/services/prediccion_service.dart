import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────────────
//  MODELOS DE RESPUESTA
// ─────────────────────────────────────────────────────────────

class PrediccionTiempo {
  final int minutosEstimados;
  final int rangoMin;
  final int rangoMax;
  final String nivelOcupacion; // "bajo" | "medio" | "alto"
  final String recomendacion;
  final String horaConsulta;

  const PrediccionTiempo({
    required this.minutosEstimados,
    required this.rangoMin,
    required this.rangoMax,
    required this.nivelOcupacion,
    required this.recomendacion,
    required this.horaConsulta,
  });

  factory PrediccionTiempo.fromJson(Map<String, dynamic> json) =>
      PrediccionTiempo(
        minutosEstimados: json['minutos_estimados'] as int,
        rangoMin: json['rango_min'] as int,
        rangoMax: json['rango_max'] as int,
        nivelOcupacion: json['nivel_ocupacion'] as String,
        recomendacion: json['recomendacion'] as String,
        horaConsulta: json['hora_consulta'] as String,
      );
}

class DatoAfluenciaHora {
  final String hora;       // "14:00"
  final String horaLabel;  // "2pm"
  final int ocupacionPct;  // 0-100
  final bool esPico;

  const DatoAfluenciaHora({
    required this.hora,
    required this.horaLabel,
    required this.ocupacionPct,
    required this.esPico,
  });

  factory DatoAfluenciaHora.fromJson(Map<String, dynamic> json) =>
      DatoAfluenciaHora(
        hora: json['hora'] as String,
        horaLabel: json['hora_label'] as String,
        ocupacionPct: json['ocupacion_pct'] as int,
        esPico: json['es_pico'] as bool,
      );
}

class MetricasModelo {
  final bool modeloDisponible;
  final int totalPedidosEvaluados;
  final double? maeMinutos;
  final double? precision5minPct;
  final double? precision10minPct;
  final double? tiempoPromedioReal;
  final double? tiempoPromedioPredicho;
  final String? mensaje;

  const MetricasModelo({
    required this.modeloDisponible,
    required this.totalPedidosEvaluados,
    this.maeMinutos,
    this.precision5minPct,
    this.precision10minPct,
    this.tiempoPromedioReal,
    this.tiempoPromedioPredicho,
    this.mensaje,
  });

  factory MetricasModelo.fromJson(Map<String, dynamic> json) => MetricasModelo(
        modeloDisponible: json['modelo_disponible'] as bool? ?? false,
        totalPedidosEvaluados: json['total_pedidos_evaluados'] as int? ?? 0,
        maeMinutos: (json['mae_minutos'] as num?)?.toDouble(),
        precision5minPct: (json['precision_5min_pct'] as num?)?.toDouble(),
        precision10minPct: (json['precision_10min_pct'] as num?)?.toDouble(),
        tiempoPromedioReal:
            (json['tiempo_promedio_real_min'] as num?)?.toDouble(),
        tiempoPromedioPredicho:
            (json['tiempo_promedio_predicho_min'] as num?)?.toDouble(),
        mensaje: json['mensaje'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────
//  RESULTADO TIPADO (mismo patrón que el resto del proyecto)
// ─────────────────────────────────────────────────────────────

sealed class IaResultado<T> {
  const IaResultado();
}

class IaExito<T> extends IaResultado<T> {
  final T datos;
  const IaExito(this.datos);
}

class IaError<T> extends IaResultado<T> {
  final String mensaje;
  const IaError(this.mensaje);
}

// ─────────────────────────────────────────────────────────────
//  SERVICIO
// ─────────────────────────────────────────────────────────────

class PrediccionService {
  static String get _base => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('waitless.token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Predice el tiempo de espera de un pedido nuevo.
  /// [mesas_ocupadas] se puede obtener del MesaService.
  static Future<IaResultado<PrediccionTiempo>> predecirTiempoEspera({
    required int hora,
    required int diaSemana,
    required int mesasOcupadas,
    required int totalItems,
    required double totalPedido,
  }) async {
    try {
      final headers = await _headers();
      final uri = Uri.parse('$_base/ia/predecir').replace(queryParameters: {
        'hora': hora.toString(),
        'dia_semana': diaSemana.toString(),
        'mesas_ocupadas': mesasOcupadas.toString(),
        'total_items': totalItems.toString(),
        'total_pedido': totalPedido.toString(),
      });

      debugPrint('🤖 PrediccionService.predecir → GET $uri');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🤖 ← status ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return IaExito(PrediccionTiempo.fromJson(data));
      }
      return IaError('Error ${response.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Obtiene la curva de afluencia por hora para un día de la semana.
  /// [diaSemana]: 0 = lunes … 6 = domingo.
  static Future<IaResultado<List<DatoAfluenciaHora>>> afluenciaPorHora({
    int diaSemana = 0,
  }) async {
    try {
      final headers = await _headers();
      final uri = Uri.parse('$_base/ia/afluencia').replace(
        queryParameters: {'dia_semana': diaSemana.toString()},
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return IaExito(
          data.map((j) => DatoAfluenciaHora.fromJson(j)).toList(),
        );
      }
      return IaError('Error ${response.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Métricas de precisión del modelo (solo admin).
  static Future<IaResultado<MetricasModelo>> obtenerMetricas() async {
    try {
      final headers = await _headers();
      final response = await http
          .get(Uri.parse('$_base/ia/metricas'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return IaExito(MetricasModelo.fromJson(data));
      }
      return IaError('Error ${response.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Dispara el (re-)entrenamiento del modelo (solo admin).
  static Future<IaResultado<Map<String, dynamic>>> entrenarModelo() async {
    try {
      final headers = await _headers();
      final response = await http
          .post(Uri.parse('$_base/ia/entrenar'), headers: headers)
          .timeout(const Duration(seconds: 60)); // entrenamiento puede tardar

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return IaExito(data);
      }
      return IaError('Error ${response.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
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