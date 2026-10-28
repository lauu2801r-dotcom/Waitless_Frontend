import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_controller.dart';
import '../../../services/prediccion_service.dart';
import '../../../theme/app_theme.dart';
import 'admin_ia_sheets.dart';

/// Pantalla "Análisis" del administrador: afluencia, rendimiento real de la IA,
/// alertas, versiones del modelo e historial de predicciones.
class AdminPrediccionScreen extends StatefulWidget {
  const AdminPrediccionScreen({super.key});

  @override
  State<AdminPrediccionScreen> createState() => _AdminPrediccionScreenState();
}

class _AdminPrediccionScreenState extends State<AdminPrediccionScreen> {
  List<DatoAfluenciaHora> _afluencia = [];
  MetricasModelo? _metricas;
  ContextoRestaurante? _contexto;
  bool _cargando = true;
  String? _error;
  int _diaSeleccionado = 0; // 0=lun…6=dom
  int _periodoDias = 0; // 0 = todo el historial

  static const _diasNombre = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _periodos = <int, String>{
    0: 'Todo',
    7: '7 días',
    30: '30 días',
  };

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = DateTime.now().weekday - 1;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final fAfluencia =
        PrediccionService.afluenciaPorHora(diaSemana: _diaSeleccionado);
    final fMetricas = PrediccionService.obtenerMetricas(
      desde: _periodoDias == 0
          ? null
          : DateTime.now().subtract(Duration(days: _periodoDias)),
    );
    final fContexto = PrediccionService.contexto();

    final resAfluencia = await fAfluencia;
    final resMetricas = await fMetricas;
    final resContexto = await fContexto;

    if (!mounted) return;
    setState(() {
      _cargando = false;
      switch (resAfluencia) {
        case IaExito(:final datos):
          _afluencia = datos;
        case IaError():
          _error = 'No se pudo cargar la afluencia';
      }
      switch (resMetricas) {
        case IaExito(:final datos):
          _metricas = datos;
        case IaError(:final mensaje):
          _error ??= mensaje;
      }
      if (resContexto case IaExito(:final datos)) {
        _contexto = datos;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conDatos = AuthScope.of(context).usuario?.conDatos ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarDatos,
          color: AppColors.terracota,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Análisis', style: AppTheme.titulo(size: 30)),
                const SizedBox(height: 4),
                Text('INTELIGENCIA ARTIFICIAL', style: AppTheme.etiqueta()),
                const SizedBox(height: 20),
                if (!conDatos)
                  _tarjetaSinDatos()
                else if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child:
                          CircularProgressIndicator(color: AppColors.terracota),
                    ),
                  )
                else ...[
                  if (_error != null) _bannerError(),
                  _estadoActual(),
                  const SizedBox(height: 18),
                  if (_afluencia.isNotEmpty) _tarjetaHoraPico(),
                  const SizedBox(height: 14),
                  _selectorDia(),
                  const SizedBox(height: 12),
                  _graficaOcupacion(),
                  const SizedBox(height: 24),
                  _seccionModelo(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Estado actual ──────────────────────────────────────────

  Widget _estadoActual() {
    final c = _contexto;
    return Row(
      children: [
        Expanded(
          child: _MetricaCard(
            icono: Icons.table_restaurant,
            valor: c == null ? '--' : '${c.mesasOcupadas}/${c.mesasTotales}',
            etiqueta: 'MESAS OCUPADAS',
            color: AppColors.cremaOscura,
            iconColor: AppColors.terracota,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricaCard(
            icono: Icons.soup_kitchen_outlined,
            valor: c == null ? '--' : '${c.pedidosEnCocina}',
            etiqueta: 'PEDIDOS EN COCINA',
            color: AppColors.infoFondo,
            iconColor: AppColors.infoTexto,
          ),
        ),
      ],
    );
  }

  Widget _bannerError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_error!,
          style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.terracotaOscuro)),
    );
  }

  // ── Hora pico ──────────────────────────────────────────────

  Widget _tarjetaHoraPico() {
    final pico =
        _afluencia.reduce((a, b) => a.ocupacionPct > b.ocupacionPct ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up,
                color: AppColors.terracota, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HORA PICO ${_diasNombre[_diaSeleccionado].toUpperCase()}',
                    style: AppTheme.etiqueta(
                        size: 10, color: AppColors.terracota)),
                const SizedBox(height: 2),
                Text('${pico.hora} · ${pico.ocupacionPct}% de la demanda máx.',
                    style: AppTheme.titulo(
                        size: 16, color: AppColors.terracotaOscuro)),
                const SizedBox(height: 2),
                Text('Considera tener más personal listo',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.terracotaOscuro)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de día ────────────────────────────────────────

  Widget _selectorDia() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final seleccionado = i == _diaSeleccionado;
          return GestureDetector(
            onTap: () {
              setState(() => _diaSeleccionado = i);
              _cargarDatos();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.terracota : AppColors.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: seleccionado ? AppColors.terracota : AppColors.borde,
                ),
              ),
              child: Text(
                _diasNombre[i],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.white : AppColors.cafeMedio,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Gráfica de barras ──────────────────────────────────────

  Widget _graficaOcupacion() {
    final ahoraH = DateTime.now().hour;
    final delHistorial =
        _afluencia.isNotEmpty && _afluencia.first.fuente == 'historial';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.terracota, size: 18),
              const SizedBox(width: 6),
              Text('AFLUENCIA POR HORA', style: AppTheme.etiqueta()),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            delHistorial
                ? 'Calculada con los pedidos reales de tu restaurante'
                : 'Estimada por el modelo (aún hay pocos pedidos reales)',
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.cafeMedio),
          ),
          const SizedBox(height: 16),
          if (_afluencia.isEmpty)
            const Center(child: Text('Sin datos'))
          else
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.cafeOscuro,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${rod.toY.round()}%',
                        GoogleFonts.inter(
                            color: AppColors.crema,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= _afluencia.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_afluencia[i].horaLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 9, color: AppColors.cafeMedio)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _afluencia.asMap().entries.map((e) {
                    final d = e.value;
                    final esAhora =
                        int.parse(d.hora.split(':')[0]) == ahoraH &&
                            _diaSeleccionado == DateTime.now().weekday - 1;
                    final color = esAhora
                        ? AppColors.oliva
                        : d.ocupacionPct > 70
                            ? AppColors.terracota.withValues(alpha: 0.55)
                            : d.ocupacionPct > 40
                                ? const Color(0xFFD9B896)
                                : AppColors.cremaOscura;
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: d.ocupacionPct.toDouble(),
                          color: color,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _Leyenda(color: AppColors.oliva, label: 'Ahora'),
              const SizedBox(width: 14),
              const _Leyenda(color: AppColors.cremaOscura, label: 'Tranquilo'),
              const SizedBox(width: 14),
              _Leyenda(
                  color: AppColors.terracota.withValues(alpha: 0.55),
                  label: 'Lleno'),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MODELO DE IA
  // ══════════════════════════════════════════════════════════

  Widget _seccionModelo() {
    final m = _metricas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('MODELO DE IA', style: AppTheme.etiqueta())),
            if (m != null && m.modeloDisponible)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.olivaFondo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Versión ${m.versionActiva} activa',
                    style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.infoTexto)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mide qué tan bien acertó el tiempo de espera que le mostró a tus clientes.',
          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.cafeMedio),
        ),
        const SizedBox(height: 12),
        _selectorPeriodo(),
        const SizedBox(height: 12),
        if (m == null || !m.modeloDisponible)
          _avisoSinModelo(m?.mensaje)
        else if (m.totalPedidosEvaluados == 0) ...[
          _alertas(m.alertas),
          _avisoSinEvaluar(),
        ] else ...[
          _alertas(m.alertas),
          _kpis(m),
          const SizedBox(height: 14),
          _tarjetaPorCarga(m),
          const SizedBox(height: 14),
          _tarjetaDistribucion(m),
          if (m.porVersion.isNotEmpty) ...[
            const SizedBox(height: 14),
            _tarjetaPorVersion(m),
          ],
          if (m.anomalias.isNotEmpty) ...[
            const SizedBox(height: 14),
            _tarjetaAnomalias(m),
          ],
        ],
        const SizedBox(height: 18),
        _acciones(),
      ],
    );
  }

  Widget _selectorPeriodo() {
    return Row(
      children: [
        for (final e in _periodos.entries) ...[
          GestureDetector(
            onTap: () {
              if (_periodoDias == e.key) return;
              setState(() => _periodoDias = e.key);
              _cargarDatos();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _periodoDias == e.key
                    ? AppColors.cafeOscuro
                    : AppColors.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _periodoDias == e.key
                        ? AppColors.cafeOscuro
                        : AppColors.borde),
              ),
              child: Text(e.value,
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _periodoDias == e.key
                          ? Colors.white
                          : AppColors.cafeMedio)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _avisoSinModelo(String? mensaje) {
    return _tarjetaSimple(
      icono: Icons.psychology_alt_outlined,
      titulo: 'El modelo aún no está entrenado',
      texto: mensaje ?? 'Entrénalo desde "Versiones y entrenamiento".',
    );
  }

  Widget _avisoSinEvaluar() {
    return _tarjetaSimple(
      icono: Icons.hourglass_empty,
      titulo: 'Aún no hay pedidos para evaluar',
      texto: 'Cuando tus pedidos pasen a "Listo", la app compara lo que '
          'estimó la IA con lo que de verdad tardó la cocina y aquí '
          'aparecerán las métricas.',
    );
  }

  Widget _tarjetaSimple(
      {required IconData icono,
      required String titulo,
      required String texto}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.terracota, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTheme.titulo(size: 16)),
                const SizedBox(height: 4),
                Text(texto,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.cafeMedio, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Alertas ────────────────────────────────────────────────

  Widget _alertas(List<AlertaIa> alertas) {
    if (alertas.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final a in alertas)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: a.nivel == 'alta'
                  ? AppColors.alertaFondo
                  : a.nivel == 'media'
                      ? const Color(0xFFFFF1D6)
                      : AppColors.infoFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  a.nivel == 'info'
                      ? Icons.info_outline
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: a.nivel == 'alta'
                      ? AppColors.terracotaOscuro
                      : a.nivel == 'media'
                          ? const Color(0xFF8A6A1C)
                          : AppColors.infoTexto,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.mensaje,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: a.nivel == 'alta'
                          ? AppColors.terracotaOscuro
                          : a.nivel == 'media'
                              ? const Color(0xFF6B5214)
                              : AppColors.infoTexto,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── KPIs ───────────────────────────────────────────────────

  Widget _kpis(MetricasModelo m) {
    String pct(double? v) => v == null ? '--' : '${v.toStringAsFixed(0)}%';
    final sesgo = m.sesgoMinutos;
    final maeMalo = m.maeMinutos != null && m.maeMinutos! > m.umbralMae;
    final precMala = m.precision5minPct != null &&
        m.precision5minPct! < m.umbralPrecision;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricaCard(
                icono: Icons.straighten,
                valor: m.maeMinutos == null
                    ? '--'
                    : '${m.maeMinutos!.toStringAsFixed(1)} min',
                etiqueta: 'ERROR PROMEDIO',
                color: maeMalo ? AppColors.alertaFondo : AppColors.olivaFondo,
                iconColor:
                    maeMalo ? AppColors.terracotaOscuro : AppColors.oliva,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricaCard(
                icono: Icons.check_circle_outline,
                valor: pct(m.precision5minPct),
                etiqueta: 'ACIERTO ±5 MIN',
                color: precMala ? AppColors.alertaFondo : AppColors.olivaFondo,
                iconColor:
                    precMala ? AppColors.terracotaOscuro : AppColors.oliva,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricaCard(
                icono: Icons.swap_horiz,
                valor: pct(m.aciertoRangoPct),
                etiqueta: 'REAL DENTRO DEL RANGO',
                color: AppColors.infoFondo,
                iconColor: AppColors.infoTexto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricaCard(
                icono: Icons.trending_up,
                valor: m.mejoraVsBaselinePct == null
                    ? '--'
                    : '${m.mejoraVsBaselinePct!.toStringAsFixed(0)}%',
                etiqueta: 'MEJOR QUE PROMEDIAR',
                color: AppColors.cremaOscura,
                iconColor: AppColors.terracota,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            children: [
              _filaDato('Pedidos evaluados', '${m.totalPedidosEvaluados}'),
              _filaDato(
                  'Tiempo real promedio',
                  m.tiempoPromedioReal == null
                      ? '--'
                      : '${m.tiempoPromedioReal!.toStringAsFixed(1)} min'),
              _filaDato(
                  'Tiempo estimado promedio',
                  m.tiempoPromedioPredicho == null
                      ? '--'
                      : '${m.tiempoPromedioPredicho!.toStringAsFixed(1)} min'),
              _filaDato(
                  'Acierto ±10 min',
                  m.precision10minPct == null
                      ? '--'
                      : '${m.precision10minPct!.toStringAsFixed(1)}%'),
              _filaDato(
                  'Error si siempre dijera el promedio',
                  m.maeBaseline == null
                      ? '--'
                      : '${m.maeBaseline!.toStringAsFixed(1)} min'),
              _filaDato(
                'Tendencia',
                sesgo == null
                    ? '--'
                    : sesgo.abs() < 1
                        ? 'Equilibrada'
                        : sesgo > 0
                            ? 'Sobreestima ${sesgo.toStringAsFixed(1)} min'
                            : 'Subestima ${sesgo.abs().toStringAsFixed(1)} min',
                ultima: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filaDato(String k, String v, {bool ultima = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.cafeMedio)),
          ),
          Text(v,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro)),
        ],
      ),
    );
  }

  // ── Acierto según la carga de cocina ───────────────────────

  Widget _tarjetaPorCarga(MetricasModelo m) {
    const nombres = {
      'bajo': 'Cocina tranquila',
      'medio': 'Cocina con carga media',
      'alto': 'Cocina saturada',
    };
    return _tarjeta(
      icono: Icons.local_fire_department_outlined,
      titulo: 'ACIERTO SEGÚN LA CARGA',
      hijo: Column(
        children: [
          for (final c in m.porCategoria)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nombres[c.nivel] ?? c.nivel,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cafeOscuro)),
                      ),
                      Text(
                        c.n == 0
                            ? 'sin pedidos'
                            : '${c.aciertoPct?.toStringAsFixed(0) ?? '--'}% · '
                                '${c.mae?.toStringAsFixed(1) ?? '--'} min · ${c.n} ped.',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.cafeMedio),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((c.aciertoPct ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: AppColors.cremaOscura,
                      color: c.nivel == 'alto'
                          ? AppColors.terracota
                          : c.nivel == 'medio'
                              ? const Color(0xFFD9B896)
                              : AppColors.oliva,
                    ),
                  ),
                ],
              ),
            ),
          Text('Acierto = la predicción quedó a ±5 min de lo real.',
              style:
                  GoogleFonts.inter(fontSize: 10.5, color: AppColors.cafeMedio)),
        ],
      ),
    );
  }

  // ── Distribución del error ─────────────────────────────────

  Widget _tarjetaDistribucion(MetricasModelo m) {
    const filas = [
      ('0_a_5_min', '0 – 5 min', AppColors.oliva),
      ('5_a_10_min', '5 – 10 min', Color(0xFFD9B896)),
      ('10_a_20_min', '10 – 20 min', AppColors.terracota),
      ('mas_de_20_min', 'Más de 20 min', AppColors.terracotaOscuro),
    ];
    final total = m.distribucionErrores.values.fold<int>(0, (a, b) => a + b);

    return _tarjeta(
      icono: Icons.stacked_bar_chart,
      titulo: 'CUÁNTO SE EQUIVOCÓ',
      hijo: Column(
        children: [
          for (final f in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(f.$2,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, color: AppColors.cafeMedio)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0
                            ? 0
                            : (m.distribucionErrores[f.$1] ?? 0) / total,
                        minHeight: 9,
                        backgroundColor: AppColors.cremaOscura,
                        color: f.$3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text('${m.distribucionErrores[f.$1] ?? 0}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Comparación entre versiones ────────────────────────────

  Widget _tarjetaPorVersion(MetricasModelo m) {
    return _tarjeta(
      icono: Icons.compare_arrows,
      titulo: 'COMPARACIÓN POR VERSIÓN',
      hijo: Column(
        children: [
          Row(
            children: [
              _celda('Versión', flex: 3, cabecera: true),
              _celda('Pedidos', flex: 3, cabecera: true),
              _celda('Error', flex: 3, cabecera: true),
              _celda('±5 min', flex: 3, cabecera: true),
            ],
          ),
          const Divider(height: 14, color: AppColors.borde),
          for (final v in m.porVersion)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _celda('v${v.version}'
                      '${v.version == m.versionActiva ? ' ●' : ''}',
                      flex: 3, negrita: true),
                  _celda('${v.n}', flex: 3),
                  _celda(
                      v.mae == null ? '--' : '${v.mae!.toStringAsFixed(1)} min',
                      flex: 3),
                  _celda(
                      v.precision5Pct == null
                          ? '--'
                          : '${v.precision5Pct!.toStringAsFixed(0)}%',
                      flex: 3),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('● = versión activa',
                style: GoogleFonts.inter(
                    fontSize: 10.5, color: AppColors.cafeMedio)),
          ),
        ],
      ),
    );
  }

  Widget _celda(String t,
      {int flex = 1, bool cabecera = false, bool negrita = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        style: cabecera
            ? AppTheme.etiqueta(size: 9)
            : GoogleFonts.inter(
                fontSize: 12,
                fontWeight: negrita ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.cafeOscuro),
      ),
    );
  }

  // ── Predicciones que fallaron mucho ────────────────────────

  Widget _tarjetaAnomalias(MetricasModelo m) {
    return _tarjeta(
      icono: Icons.report_gmailerrorred_outlined,
      titulo: 'DESVIACIONES > 15 MIN',
      hijo: Column(
        children: [
          for (final a in m.anomalias.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pedido #${a.pedidoId}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro)),
                  ),
                  Text(
                      'estimó ${a.estimado} · tardó ${a.real.toStringAsFixed(0)} min',
                      style: GoogleFonts.inter(
                          fontSize: 11.5, color: AppColors.cafeMedio)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjeta(
      {required IconData icono,
      required String titulo,
      required Widget hijo}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppColors.terracota, size: 17),
              const SizedBox(width: 6),
              Text(titulo, style: AppTheme.etiqueta()),
            ],
          ),
          const SizedBox(height: 14),
          hijo,
        ],
      ),
    );
  }

  // ── Botones de acción ──────────────────────────────────────

  Widget _acciones() {
    return Column(
      children: [
        _botonAccion(
          icono: Icons.model_training,
          titulo: 'Versiones y entrenamiento',
          detalle: 'Reentrena, compara y vuelve a una versión anterior',
          onTap: () => mostrarVersionesIa(context, onCambio: _cargarDatos),
        ),
        const SizedBox(height: 10),
        _botonAccion(
          icono: Icons.history,
          titulo: 'Historial de predicciones',
          detalle: 'Cada estimación frente al tiempo real · copiar CSV',
          onTap: () => mostrarHistorialIa(context),
        ),
      ],
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String titulo,
    required String detalle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: AppColors.terracota, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro)),
                  const SizedBox(height: 2),
                  Text(detalle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cafeMedio),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaSinDatos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart,
                color: AppColors.terracota, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Aún sin datos suficientes', style: AppTheme.titulo(size: 18)),
          const SizedBox(height: 6),
          Text(
            'A medida que recibas pedidos, aquí verás\nlas predicciones de afluencia y el rendimiento de la IA.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.cafeMedio, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 10, color: AppColors.cafeMedio)),
      ],
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final Color iconColor;

  const _MetricaCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.superficie.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(valor, style: AppTheme.titulo(size: 22)),
          const SizedBox(height: 2),
          Text(etiqueta, style: AppTheme.etiqueta(size: 9)),
        ],
      ),
    );
  }
}
