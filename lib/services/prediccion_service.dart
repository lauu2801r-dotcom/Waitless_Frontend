import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

// ─────────────────────────────────────────────────────────────
//  MODELOS DE RESPUESTA
// ─────────────────────────────────────────────────────────────

double? _d(dynamic v) => (v as num?)?.toDouble();

/// El servidor guarda la hora en UTC sin zona → se le agrega la 'Z'.
DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse('${v}Z')?.toLocal();

class PrediccionTiempo {
  final int minutosEstimados;
  final int rangoMin;
  final int rangoMax;
  final String nivelOcupacion; // "bajo" | "medio" | "alto"
  final String recomendacion;
  final String horaConsulta;
  final int confianza; // 0-100
  final int? versionModelo;
  final String fuente; // "modelo" | "reglas"

  const PrediccionTiempo({
    required this.minutosEstimados,
    required this.rangoMin,
    required this.rangoMax,
    required this.nivelOcupacion,
    required this.recomendacion,
    required this.horaConsulta,
    this.confianza = 0,
    this.versionModelo,
    this.fuente = 'modelo',
  });

  factory PrediccionTiempo.fromJson(Map<String, dynamic> json) =>
      PrediccionTiempo(
        minutosEstimados: json['minutos_estimados'] as int,
        rangoMin: json['rango_min'] as int,
        rangoMax: json['rango_max'] as int,
        nivelOcupacion: json['nivel_ocupacion'] as String,
        recomendacion: json['recomendacion'] as String,
        horaConsulta: json['hora_consulta'] as String,
        confianza: json['confianza'] as int? ?? 0,
        versionModelo: json['version_modelo'] as int?,
        fuente: json['fuente'] as String? ?? 'modelo',
      );
}

class DatoAfluenciaHora {
  final String hora; // "14:00"
  final String horaLabel; // "2pm"
  final int ocupacionPct; // 0-100
  final bool esPico;

  /// "historial" = sale de los pedidos reales del restaurante;
  /// "modelo" = curva estimada por el modelo (cuando aún hay pocos datos).
  final String fuente;

  const DatoAfluenciaHora({
    required this.hora,
    required this.horaLabel,
    required this.ocupacionPct,
    required this.esPico,
    this.fuente = 'modelo',
  });

  factory DatoAfluenciaHora.fromJson(Map<String, dynamic> json) =>
      DatoAfluenciaHora(
        hora: json['hora'] as String,
        horaLabel: json['hora_label'] as String,
        ocupacionPct: json['ocupacion_pct'] as int,
        esPico: json['es_pico'] as bool,
        fuente: json['fuente'] as String? ?? 'modelo',
      );
}

/// Un día de la semana en la gráfica de tendencia (GET /ia/afluencia-semanal).
class DatoDiaSemana {
  final int diaSemana; // 0 = lunes … 6 = domingo
  final double? pedidosPromedio;
  final int ocupacionPct;

  /// "historial" = pedidos reales del restaurante; "estimada" = patrón típico.
  final String fuente;

  const DatoDiaSemana({
    required this.diaSemana,
    this.pedidosPromedio,
    required this.ocupacionPct,
    required this.fuente,
  });

  factory DatoDiaSemana.fromJson(Map<String, dynamic> j) => DatoDiaSemana(
        diaSemana: j['dia_semana'] as int,
        pedidosPromedio: _d(j['pedidos_promedio']),
        ocupacionPct: (j['ocupacion_pct'] as num).toInt(),
        fuente: j['fuente'] as String? ?? 'estimada',
      );
}

/// Cómo está el restaurante ahora mismo (GET /ia/contexto).
class ContextoRestaurante {
  final int mesasTotales;
  final int mesasOcupadas;
  final int mesasLibres;
  final int pedidosEnCocina;
  final String nivelCocina; // bajo | medio | alto

  const ContextoRestaurante({
    required this.mesasTotales,
    required this.mesasOcupadas,
    required this.mesasLibres,
    required this.pedidosEnCocina,
    required this.nivelCocina,
  });

  factory ContextoRestaurante.fromJson(Map<String, dynamic> j) =>
      ContextoRestaurante(
        mesasTotales: j['mesas_totales'] as int? ?? 0,
        mesasOcupadas: j['mesas_ocupadas'] as int? ?? 0,
        mesasLibres: j['mesas_libres'] as int? ?? 0,
        pedidosEnCocina: j['pedidos_en_cocina'] as int? ?? 0,
        nivelCocina: j['nivel_cocina'] as String? ?? 'bajo',
      );
}

class AlertaIa {
  final String nivel; // alta | media | info
  final String codigo;
  final String mensaje;
  const AlertaIa(
      {required this.nivel, required this.codigo, required this.mensaje});

  factory AlertaIa.fromJson(Map<String, dynamic> j) => AlertaIa(
        nivel: j['nivel'] as String? ?? 'info',
        codigo: j['codigo'] as String? ?? '',
        mensaje: j['mensaje'] as String? ?? '',
      );
}

/// Resultado por nivel de carga (bajo / medio / alto).
class MetricaCategoria {
  final String nivel;
  final int n;
  final double? mae;
  final double? aciertoPct;
  const MetricaCategoria(
      {required this.nivel, required this.n, this.mae, this.aciertoPct});
}

/// Rendimiento real de una versión del modelo.
class MetricaVersion {
  final int version;
  final int n;
  final double? mae;
  final double? precision5Pct;
  final double? aciertoRangoPct;
  const MetricaVersion({
    required this.version,
    required this.n,
    this.mae,
    this.precision5Pct,
    this.aciertoRangoPct,
  });
}

class AnomaliaIa {
  final int pedidoId;
  final num estimado;
  final num real;
  final num error;
  const AnomaliaIa(
      {required this.pedidoId,
      required this.estimado,
      required this.real,
      required this.error});
}

class MetricasModelo {
  final bool modeloDisponible;
  final int versionActiva;
  final int totalPedidosEvaluados;
  final double? maeMinutos;
  final double? precision5minPct;
  final double? precision10minPct;
  final double? aciertoRangoPct;
  final double? tiempoPromedioReal;
  final double? tiempoPromedioPredicho;
  final double? maeBaseline;
  final double? mejoraVsBaselinePct;
  final double? sesgoMinutos;
  final double umbralMae;
  final double umbralPrecision;
  final Map<String, int> distribucionErrores;
  final List<MetricaCategoria> porCategoria;
  final List<MetricaVersion> porVersion;
  final List<AnomaliaIa> anomalias;
  final List<AlertaIa> alertas;
  final String? mensaje;

  const MetricasModelo({
    required this.modeloDisponible,
    required this.totalPedidosEvaluados,
    this.versionActiva = 0,
    this.maeMinutos,
    this.precision5minPct,
    this.precision10minPct,
    this.aciertoRangoPct,
    this.tiempoPromedioReal,
    this.tiempoPromedioPredicho,
    this.maeBaseline,
    this.mejoraVsBaselinePct,
    this.sesgoMinutos,
    this.umbralMae = 8,
    this.umbralPrecision = 50,
    this.distribucionErrores = const {},
    this.porCategoria = const [],
    this.porVersion = const [],
    this.anomalias = const [],
    this.alertas = const [],
    this.mensaje,
  });

  factory MetricasModelo.fromJson(Map<String, dynamic> json) {
    final umbrales = json['umbrales'] as Map<String, dynamic>? ?? {};
    final dist = json['distribucion_errores'] as Map<String, dynamic>? ?? {};
    final cat = json['por_categoria'] as Map<String, dynamic>? ?? {};

    return MetricasModelo(
      modeloDisponible: json['modelo_disponible'] as bool? ?? false,
      versionActiva: json['version_activa'] as int? ?? 0,
      totalPedidosEvaluados: json['total_pedidos_evaluados'] as int? ?? 0,
      maeMinutos: _d(json['mae_minutos']),
      precision5minPct: _d(json['precision_5min_pct']),
      precision10minPct: _d(json['precision_10min_pct']),
      aciertoRangoPct: _d(json['acierto_rango_pct']),
      tiempoPromedioReal: _d(json['tiempo_promedio_real_min']),
      tiempoPromedioPredicho: _d(json['tiempo_promedio_predicho_min']),
      maeBaseline: _d(json['mae_baseline_minutos']),
      mejoraVsBaselinePct: _d(json['mejora_vs_baseline_pct']),
      sesgoMinutos: _d(json['sesgo_minutos']),
      umbralMae: _d(umbrales['mae_max_min']) ?? 8,
      umbralPrecision: _d(umbrales['precision_min_pct']) ?? 50,
      distribucionErrores:
          dist.map((k, v) => MapEntry(k, (v as num).toInt())),
      porCategoria: [
        for (final nivel in const ['bajo', 'medio', 'alto'])
          if (cat[nivel] != null)
            MetricaCategoria(
              nivel: nivel,
              n: (cat[nivel]['n'] as num?)?.toInt() ?? 0,
              mae: _d(cat[nivel]['mae']),
              aciertoPct: _d(cat[nivel]['acierto_pct']),
            ),
      ],
      porVersion: [
        for (final v in (json['por_version'] as List<dynamic>? ?? []))
          MetricaVersion(
            version: (v['version'] as num).toInt(),
            n: (v['n'] as num?)?.toInt() ?? 0,
            mae: _d(v['mae']),
            precision5Pct: _d(v['precision_5min_pct']),
            aciertoRangoPct: _d(v['acierto_rango_pct']),
          ),
      ],
      anomalias: [
        for (final a in (json['anomalias'] as List<dynamic>? ?? []))
          AnomaliaIa(
            pedidoId: (a['pedido_id'] as num?)?.toInt() ?? 0,
            estimado: a['estimado'] as num? ?? 0,
            real: a['real'] as num? ?? 0,
            error: a['error'] as num? ?? 0,
          ),
      ],
      alertas: [
        for (final a in (json['alertas'] as List<dynamic>? ?? []))
          AlertaIa.fromJson(a as Map<String, dynamic>),
      ],
      mensaje: json['mensaje'] as String?,
    );
  }
}

/// Una versión entrenada del modelo (GET /ia/versiones).
class VersionModelo {
  final int id;
  final int version;
  final bool activo;
  final String motivo; // manual | automatico | arranque
  final DateTime? entrenadoEn;
  final int muestrasReales;
  final int muestrasSinteticas;
  final double? maeEntrenamiento;
  final double? maeBaseline;
  final double? r2;
  final int prediccionesEvaluadas;
  final double? maeProduccion;

  const VersionModelo({
    required this.id,
    required this.version,
    required this.activo,
    required this.motivo,
    this.entrenadoEn,
    required this.muestrasReales,
    required this.muestrasSinteticas,
    this.maeEntrenamiento,
    this.maeBaseline,
    this.r2,
    required this.prediccionesEvaluadas,
    this.maeProduccion,
  });

  factory VersionModelo.fromJson(Map<String, dynamic> j) => VersionModelo(
        id: j['id'] as int,
        version: j['version'] as int,
        activo: j['activo'] as bool? ?? false,
        motivo: j['motivo'] as String? ?? 'manual',
        entrenadoEn: _fecha(j['entrenado_en']),
        muestrasReales: (j['muestras_reales'] as num?)?.toInt() ?? 0,
        muestrasSinteticas: (j['muestras_sinteticas'] as num?)?.toInt() ?? 0,
        maeEntrenamiento: _d(j['mae_entrenamiento']),
        maeBaseline: _d(j['mae_baseline']),
        r2: _d(j['r2']),
        prediccionesEvaluadas:
            (j['predicciones_evaluadas'] as num?)?.toInt() ?? 0,
        maeProduccion: _d(j['mae_produccion']),
      );

  String get motivoTexto {
    switch (motivo) {
      case 'automatico':
        return 'Automático';
      case 'arranque':
        return 'Arranque';
      default:
        return 'Manual';
    }
  }
}

/// Una predicción ya hecha (GET /ia/historial).
class PrediccionHistorial {
  final int id;
  final int? pedidoId;
  final int minutosEstimados;
  final int rangoMin;
  final int rangoMax;
  final int? confianza;
  final int? versionModelo;
  final String nivel;
  final double? tiempoReal;
  final DateTime? creadoEn;

  const PrediccionHistorial({
    required this.id,
    this.pedidoId,
    required this.minutosEstimados,
    required this.rangoMin,
    required this.rangoMax,
    this.confianza,
    this.versionModelo,
    required this.nivel,
    this.tiempoReal,
    this.creadoEn,
  });

  factory PrediccionHistorial.fromJson(Map<String, dynamic> j) =>
      PrediccionHistorial(
        id: j['id'] as int,
        pedidoId: j['pedido_id'] as int?,
        minutosEstimados: (j['minutos_estimados'] as num).toInt(),
        rangoMin: (j['rango_min'] as num?)?.toInt() ?? 0,
        rangoMax: (j['rango_max'] as num?)?.toInt() ?? 0,
        confianza: (j['confianza'] as num?)?.toInt(),
        versionModelo: (j['version_modelo'] as num?)?.toInt(),
        nivel: j['nivel_ocupacion'] as String? ?? 'bajo',
        tiempoReal: _d(j['tiempo_real_minutos']),
        creadoEn: _fecha(j['creado_en']),
      );

  /// Diferencia absoluta entre lo estimado y lo que de verdad tardó.
  double? get error =>
      tiempoReal == null ? null : (minutosEstimados - tiempoReal!).abs();
}

/// Resultado de entrenar una versión nueva (POST /ia/entrenar).
class ResultadoEntrenamiento {
  final int version;
  final bool activo;
  final int muestrasReales;
  final int muestrasSinteticas;
  final double? mae;
  final double? maeBaseline;
  final double? r2;
  final String mensaje;

  const ResultadoEntrenamiento({
    required this.version,
    required this.activo,
    required this.muestrasReales,
    required this.muestrasSinteticas,
    this.mae,
    this.maeBaseline,
    this.r2,
    required this.mensaje,
  });

  factory ResultadoEntrenamiento.fromJson(Map<String, dynamic> j) =>
      ResultadoEntrenamiento(
        version: j['version'] as int? ?? 0,
        activo: j['activo'] as bool? ?? false,
        muestrasReales: (j['muestras_reales'] as num?)?.toInt() ?? 0,
        muestrasSinteticas: (j['muestras_sinteticas'] as num?)?.toInt() ?? 0,
        mae: _d(j['mae_minutos']),
        maeBaseline: _d(j['mae_baseline_minutos']),
        r2: _d(j['r2_score']),
        mensaje: j['mensaje'] as String? ?? '',
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

  static Future<http.Response> _get(String ruta,
      [Map<String, String>? query, int segundos = 12]) async {
    final uri = Uri.parse('$_base$ruta').replace(queryParameters: query);
    return http
        .get(uri, headers: await _headers())
        .timeout(Duration(seconds: segundos));
  }

  /// Predice el tiempo de espera de un pedido.
  /// Si no se manda [mesasOcupadas], el servidor calcula la carga con los
  /// pedidos que la cocina del restaurante tiene en curso.
  static Future<IaResultado<PrediccionTiempo>> predecirTiempoEspera({
    required int hora,
    required int diaSemana,
    int? mesasOcupadas,
    required int totalItems,
    required double totalPedido,
    int? restauranteId,
  }) async {
    try {
      final r = await _get('/ia/predecir', {
        'hora': '$hora',
        'dia_semana': '$diaSemana',
        if (mesasOcupadas != null) 'mesas_ocupadas': '$mesasOcupadas',
        'total_items': '$totalItems',
        'total_pedido': '$totalPedido',
        if (restauranteId != null) 'restaurante_id': '$restauranteId',
      }, 10);
      debugPrint('🤖 predecir ← ${r.statusCode}');
      if (r.statusCode == 200) {
        return IaExito(PrediccionTiempo.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>));
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Curva de afluencia por hora. [diaSemana]: 0 = lunes … 6 = domingo.
  static Future<IaResultado<List<DatoAfluenciaHora>>> afluenciaPorHora({
    int diaSemana = 0,
    int? restauranteId,
  }) async {
    try {
      final r = await _get('/ia/afluencia', {
        'dia_semana': '$diaSemana',
        if (restauranteId != null) 'restaurante_id': '$restauranteId',
      }, 10);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List<dynamic>;
        return IaExito(data
            .map((j) => DatoAfluenciaHora.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Qué días de la semana se llena más el restaurante.
  static Future<IaResultado<List<DatoDiaSemana>>> afluenciaSemanal(
      {int? restauranteId}) async {
    try {
      final r = await _get('/ia/afluencia-semanal', {
        if (restauranteId != null) 'restaurante_id': '$restauranteId',
      }, 10);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List<dynamic>;
        return IaExito(data
            .map((j) => DatoDiaSemana.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Mesas y cocina del restaurante en este momento.
  static Future<IaResultado<ContextoRestaurante>> contexto(
      {int? restauranteId}) async {
    try {
      final r = await _get('/ia/contexto', {
        if (restauranteId != null) 'restaurante_id': '$restauranteId',
      }, 10);
      if (r.statusCode == 200) {
        return IaExito(ContextoRestaurante.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>));
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Métricas reales del modelo en TU restaurante (solo admin).
  static Future<IaResultado<MetricasModelo>> obtenerMetricas({
    int? version,
    DateTime? desde,
    DateTime? hasta,
    double? umbralMae,
    double? umbralPrecision,
  }) async {
    try {
      String utc(DateTime d) =>
          d.toUtc().toIso8601String().replaceAll('Z', '');
      final r = await _get('/ia/metricas', {
        if (version != null) 'version': '$version',
        if (desde != null) 'desde': utc(desde),
        if (hasta != null) 'hasta': utc(hasta),
        if (umbralMae != null) 'umbral_mae': '$umbralMae',
        if (umbralPrecision != null) 'umbral_precision': '$umbralPrecision',
      });
      if (r.statusCode == 200) {
        return IaExito(MetricasModelo.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>));
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Versiones del modelo y cómo rinde cada una (solo admin).
  static Future<IaResultado<List<VersionModelo>>> versiones() async {
    try {
      final r = await _get('/ia/versiones');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List<dynamic>;
        return IaExito(data
            .map((j) => VersionModelo.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Entrena una versión nueva (solo admin). Puede tardar.
  static Future<IaResultado<ResultadoEntrenamiento>> entrenarModelo() async {
    try {
      final r = await http
          .post(Uri.parse('$_base/ia/entrenar'), headers: await _headers())
          .timeout(const Duration(seconds: 90));
      if (r.statusCode == 200) {
        return IaExito(ResultadoEntrenamiento.fromJson(
            jsonDecode(r.body) as Map<String, dynamic>));
      }
      return IaError(_detalle(r) ?? 'Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Activa una versión anterior (rollback).
  static Future<IaResultado<int>> activarVersion(int versionId) async {
    try {
      final r = await http
          .post(Uri.parse('$_base/ia/versiones/$versionId/activar'),
              headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        return IaExito(j['version'] as int? ?? 0);
      }
      return IaError(_detalle(r) ?? 'Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// Últimas predicciones de tu restaurante, con el tiempo real si ya se cerró.
  static Future<IaResultado<List<PrediccionHistorial>>> historial(
      {int limite = 40}) async {
    try {
      final r = await _get('/ia/historial', {'limite': '$limite'});
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as List<dynamic>;
        return IaExito(data
            .map((j) => PrediccionHistorial.fromJson(j as Map<String, dynamic>))
            .toList());
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  /// CSV completo de predicciones (texto), para copiarlo y pegarlo en Excel.
  static Future<IaResultado<String>> exportarCsv({int? version}) async {
    try {
      final r = await _get('/ia/exportar', {
        if (version != null) 'version': '$version',
      }, 30);
      if (r.statusCode == 200) {
        return IaExito(utf8.decode(r.bodyBytes));
      }
      return IaError('Error ${r.statusCode}');
    } catch (e) {
      return IaError(_mensajeError(e));
    }
  }

  static String? _detalle(http.Response r) {
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (j is Map && j['detail'] is String) return j['detail'] as String;
    } catch (_) {}
    return null;
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
