import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/prediccion_service.dart';
import '../services/restaurantes_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../widgets/common_widgets.dart';

class PrediccionScreen extends StatefulWidget {
  const PrediccionScreen({super.key});

  @override
  State<PrediccionScreen> createState() => _PrediccionScreenState();
}

class _PrediccionScreenState extends State<PrediccionScreen> {
  // ── Datos de afluencia ──
  List<DatoAfluenciaHora> _afluencia = [];
  List<DatoDiaSemana> _semana = [];
  List<RestauranteApi> _restaurantes = [];
  RestauranteApi? _restaurante;
  ContextoRestaurante? _contexto;
  bool _cargando = true;
  String? _error;
  PrediccionTiempo? _prediccionAhora;

  // ── Simulador de pedido ──
  int _itemsSimulados = 3;
  double _totalSimulado = 45000;
  PrediccionTiempo? _prediccionSimulada;
  bool _cargandoSimulacion = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  int get _mesasTotales => _contexto?.mesasTotales ?? 0;
  int get _mesasLibres => _contexto?.mesasLibres ?? 0;

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    // 1. Restaurantes (la primera vez) y cuál está elegido
    if (_restaurantes.isEmpty) {
      try {
        _restaurantes = await RestaurantesService.listar();
      } catch (_) {}
    }
    if (_restaurante == null && _restaurantes.isNotEmpty) {
      _restaurante = _restaurantes.first;
    }
    final rid = _restaurante?.id;
    final ahora = DateTime.now();

    // 2. Todo lo que depende de ese restaurante
    final fAfluencia = PrediccionService.afluenciaPorHora(
      diaSemana: ahora.weekday - 1,
      restauranteId: rid,
    );
    final fSemana = PrediccionService.afluenciaSemanal(restauranteId: rid);
    final fContexto = PrediccionService.contexto(restauranteId: rid);
    final fPrediccion = PrediccionService.predecirTiempoEspera(
      hora: ahora.hour,
      diaSemana: ahora.weekday - 1,
      totalItems: _itemsSimulados,
      totalPedido: _totalSimulado,
      restauranteId: rid,
    );

    final resAfluencia = await fAfluencia;
    final resSemana = await fSemana;
    final resContexto = await fContexto;
    final resPrediccion = await fPrediccion;

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resAfluencia case IaExito(:final datos)) _afluencia = datos;
      if (resSemana case IaExito(:final datos)) _semana = datos;
      if (resContexto case IaExito(:final datos)) _contexto = datos;
      switch (resPrediccion) {
        case IaExito(:final datos):
          _prediccionAhora = datos;
          _prediccionSimulada = datos;
        case IaError(:final mensaje):
          _error = mensaje;
      }
    });
  }

  void _elegirRestaurante(RestauranteApi r) {
    if (_restaurante?.id == r.id) return;
    setState(() => _restaurante = r);
    _cargarDatos();
  }

  Future<void> _simularPedido() async {
    setState(() => _cargandoSimulacion = true);
    final ahora = DateTime.now();
    final result = await PrediccionService.predecirTiempoEspera(
      hora: ahora.hour,
      diaSemana: ahora.weekday - 1,
      totalItems: _itemsSimulados,
      totalPedido: _totalSimulado,
      restauranteId: _restaurante?.id,
    );
    if (!mounted) return;
    setState(() {
      _cargandoSimulacion = false;
      if (result is IaExito<PrediccionTiempo>) {
        _prediccionSimulada = result.datos;
      }
    });
  }

  Color get _colorNivel {
    final nivel = _prediccionAhora?.nivelOcupacion ?? 'bajo';
    if (nivel == 'alto') return AppColors.terracota;
    if (nivel == 'medio') return const Color(0xFFD9B896);
    return AppColors.oliva;
  }

  String get _textoNivel {
    final nivel = _prediccionAhora?.nivelOcupacion ?? 'bajo';
    if (nivel == 'alto') return '🔴 Alta demanda ahora';
    if (nivel == 'medio') return '🟡 Demanda moderada';
    return '🟢 Tranquilo ahora';
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Text('Momento ideal', style: AppTheme.titulo(size: 30)),
                const SizedBox(height: 4),
                Text('PREDICCIÓN DE AFLUENCIA · HOY',
                    style: AppTheme.etiqueta()),
                const SizedBox(height: 14),
                if (_restaurantes.length > 1) ...[
                  _selectorRestaurante(),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 6),

                if (!conDatos) ...[
                  _tarjetaSinDatos(context),
                ] else if (_cargando) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(
                          color: AppColors.terracota),
                    ),
                  ),
                ] else if (_error != null) ...[
                  _tarjetaError(),
                ] else ...[

                  // ══════════════════════════════════════════
                  // SECCIÓN 1 — ¿Es buen momento para ir?
                  // ══════════════════════════════════════════
                  _encabezadoSeccion(
                    icono: Icons.storefront_outlined,
                    titulo: '¿Es buen momento para ir?',
                  ),
                  const SizedBox(height: 12),

                  // Banner de nivel actual
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _colorNivel.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _colorNivel.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _textoNivel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _colorNivel,
                            ),
                          ),
                        ),
                        Text(
                          '$_mesasLibres mesas libres',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.cafeMedio),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Métricas rápidas
                  Row(
                    children: [
                      Expanded(
                        child: TarjetaMetrica(
                          etiqueta: 'ESPERA ESTIMADA',
                          valor: _prediccionAhora != null
                              ? '${_prediccionAhora!.minutosEstimados} min'
                              : '-- min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TarjetaMetrica(
                          etiqueta: 'MESAS LIBRES',
                          valor:
                              '$_mesasLibres / $_mesasTotales',
                          colorFondo: AppColors.olivaFondo,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta mejor hora + gráfica
                  _tarjetaMejorHora(),

                  const SizedBox(height: 24),

                  // Tendencia semanal
                  _encabezadoSeccion(
                    icono: Icons.calendar_today_outlined,
                    titulo: 'Tendencia semanal',
                  ),
                  const SizedBox(height: 12),
                  _graficaTendenciaSemanal(),

                  const SizedBox(height: 28),

                  // ══════════════════════════════════════════
                  // SECCIÓN 2 — ¿Cuánto tarda mi pedido?
                  // ══════════════════════════════════════════
                  _encabezadoSeccion(
                    icono: Icons.timer_outlined,
                    titulo: '¿Cuánto tarda mi pedido?',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ajusta los parámetros para simular tu pedido',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.cafeMedio),
                  ),
                  const SizedBox(height: 14),

                  _tarjetaSimulador(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Selector de restaurante ─────────────────────────────────

  Widget _selectorRestaurante() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _restaurantes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = _restaurantes[i];
          final sel = r.id == _restaurante?.id;
          return GestureDetector(
            onTap: () => _elegirRestaurante(r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? AppColors.terracota : AppColors.superficie,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppColors.terracota : AppColors.borde),
              ),
              child: Text(
                '${r.emoji} ${r.nombre}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.cafeMedio,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Encabezado de sección ───────────────────────────────────

  Widget _encabezadoSeccion(
      {required IconData icono, required String titulo}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.terracota.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: AppColors.terracota, size: 17),
        ),
        const SizedBox(width: 10),
        Text(titulo,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro)),
      ],
    );
  }

  // ── Mejor hora + gráfica ────────────────────────────────────

  Widget _tarjetaMejorHora() {
    DatoAfluenciaHora? masTransquila;
    final ahoraH = DateTime.now().hour;

    if (_afluencia.isNotEmpty) {
      masTransquila =
          _afluencia.reduce((a, b) => a.ocupacionPct < b.ocupacionPct ? a : b);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.trending_down,
                  color: AppColors.oliva, size: 16),
              const SizedBox(width: 6),
              Text('MEJOR HORA SUGERIDA', style: AppTheme.etiqueta()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                masTransquila?.horaLabel
                        .replaceAll('am', '')
                        .replaceAll('pm', '') ??
                    '--',
                style: AppTheme.titulo(size: 44, color: AppColors.terracota),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  masTransquila?.horaLabel.contains('pm') == true
                      ? 'pm'
                      : 'am',
                  style:
                      AppTheme.titulo(size: 18, color: AppColors.terracota),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.oliva.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  masTransquila != null
                      ? '${masTransquila.ocupacionPct}% ocupación'
                      : '--',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.oliva),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Gráfica de barras
          if (_afluencia.isNotEmpty)
            SizedBox(
              height: 150,
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
                            child: Text(
                              _afluencia[i].horaLabel,
                              style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  color: AppColors.cafeMedio),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _afluencia.asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final esAhora =
                        int.parse(d.hora.split(':')[0]) == ahoraH;
                    final esMejor = d == masTransquila;
                    final color = esAhora
                        ? AppColors.oliva
                        : esMejor
                            ? AppColors.oliva.withValues(alpha: 0.5)
                            : d.ocupacionPct > 70
                                ? AppColors.terracota.withValues(alpha: 0.6)
                                : d.ocupacionPct > 40
                                    ? const Color(0xFFD9B896)
                                    : AppColors.cremaOscura;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: d.ocupacionPct.toDouble(),
                          color: color,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              const _Leyenda(color: AppColors.oliva, label: 'Ahora'),
              const SizedBox(width: 12),
              const _Leyenda(
                  color: AppColors.cremaOscura, label: 'Tranquilo'),
              const SizedBox(width: 12),
              _Leyenda(
                  color: AppColors.terracota.withValues(alpha: 0.6),
                  label: 'Lleno'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tendencia semanal ───────────────────────────────────────

  Widget _graficaTendenciaSemanal() {
    final spots = [
      for (final d in _semana)
        FlSpot(d.diaSemana.toDouble(), d.ocupacionPct.toDouble()),
    ];
    final esReal = _semana.isNotEmpty && _semana.first.fuente == 'historial';

    final hoy = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              esReal
                  ? 'Con los pedidos reales de las últimas 8 semanas'
                  : 'Patrón típico (aún hay pocos pedidos en este restaurante)',
              style: GoogleFonts.inter(
                  fontSize: 10.5, color: AppColors.cafeMedio),
            ),
          ),
          SizedBox(
        height: 140,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.bordeSuave,
                strokeWidth: 1,
                dashArray: [4, 4],
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
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                    final i = value.toInt();
                    if (i < 0 || i >= dias.length) return const SizedBox();
                    final esHoy = i == hoy;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dias[i],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: esHoy
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: esHoy
                              ? AppColors.terracota
                              : AppColors.cafeMedio,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.terracota,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                    radius: i == hoy ? 6 : 4,
                    color: AppColors.terracota,
                    strokeColor: AppColors.crema,
                    strokeWidth: 2,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.terracota.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }

  // ── Simulador de pedido ─────────────────────────────────────

  Widget _tarjetaSimulador() {
    final pred = _prediccionSimulada;
    final colorNivel = pred == null
        ? AppColors.cafeMedio
        : pred.nivelOcupacion == 'alto'
            ? AppColors.terracota
            : pred.nivelOcupacion == 'medio'
                ? const Color(0xFFD9A050)
                : AppColors.oliva;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resultado principal
          if (pred != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIEMPO ESTIMADO',
                        style: AppTheme.etiqueta(size: 10)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${pred.minutosEstimados}',
                          style: AppTheme.titulo(
                              size: 52, color: colorNivel),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            ' min',
                            style: AppTheme.titulo(
                                size: 20, color: colorNivel),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rango: ${pred.rangoMin}–${pred.rangoMax} min',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio),
                    ),
                    Text(
                      'Confianza ${pred.confianza}%'
                      '${pred.fuente == 'modelo' ? ' · IA' : ' · estimación básica'}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorNivel.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pred.nivelOcupacion == 'alto'
                            ? '🔴 Alta demanda'
                            : pred.nivelOcupacion == 'medio'
                                ? '🟡 Moderado'
                                : '🟢 Tranquilo',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorNivel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorNivel.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pred.recomendacion,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorNivel,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.borde),
            const SizedBox(height: 16),
          ],

          // ── Controles del simulador ──
          Text('SIMULA TU PEDIDO', style: AppTheme.etiqueta(size: 10)),
          const SizedBox(height: 14),

          // Cantidad de items
          Row(
            children: [
              const Icon(Icons.restaurant_menu_outlined,
                  size: 16, color: AppColors.cafeMedio),
              const SizedBox(width: 8),
              Text('Cantidad de platos',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.cafeOscuro)),
              const Spacer(),
              _ControlCantidad(
                valor: _itemsSimulados,
                min: 1,
                max: 20,
                onCambio: (v) => setState(() => _itemsSimulados = v),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Total del pedido
          Row(
            children: [
              const Icon(Icons.attach_money_outlined,
                  size: 16, color: AppColors.cafeMedio),
              const SizedBox(width: 8),
              Text('Total aprox.',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.cafeOscuro)),
              const Spacer(),
              Text(
                '\$${(_totalSimulado / 1000).toStringAsFixed(0)}K',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.terracota,
              inactiveTrackColor: AppColors.cremaOscura,
              thumbColor: AppColors.terracota,
              overlayColor: AppColors.terracota.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _totalSimulado,
              min: 10000,
              max: 200000,
              divisions: 38,
              onChanged: (v) => setState(() => _totalSimulado = v),
            ),
          ),

          const SizedBox(height: 8),

          // Botón calcular
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cargandoSimulacion ? null : _simularPedido,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracota,
                foregroundColor: AppColors.crema,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _cargandoSimulacion
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.crema, strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_outlined, size: 18),
              label: Text(
                _cargandoSimulacion
                    ? 'Calculando...'
                    : 'Calcular tiempo estimado',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaSinDatos(BuildContext context) {
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
            child: const Icon(Icons.insights,
                color: AppColors.terracota, size: 36),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.t(context, 'sin_datos'),
              style: AppTheme.titulo(size: 18)),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'sin_datos_cliente'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.cafeMedio, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.terracota, size: 32),
          const SizedBox(height: 8),
          Text('Sin conexión con el servidor',
              style: AppTheme.titulo(
                  size: 14, color: AppColors.terracotaOscuro)),
          const SizedBox(height: 4),
          Text(_error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.cafeMedio)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cargarDatos,
            child: Text('Reintentar',
                style:
                    GoogleFonts.inter(color: AppColors.terracota)),
          ),
        ],
      ),
    );
  }
}

// ── Control de cantidad ─────────────────────────────────────

class _ControlCantidad extends StatelessWidget {
  final int valor;
  final int min;
  final int max;
  final ValueChanged<int> onCambio;

  const _ControlCantidad({
    required this.valor,
    required this.min,
    required this.max,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: valor > min ? () => onCambio(valor - 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: valor > min
                  ? AppColors.terracota.withValues(alpha: 0.12)
                  : AppColors.cremaOscura,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove,
                size: 14,
                color: valor > min
                    ? AppColors.terracota
                    : AppColors.cafeMedio),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$valor',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro),
          ),
        ),
        GestureDetector(
          onTap: valor < max ? () => onCambio(valor + 1) : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.terracota,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 14, color: AppColors.crema),
          ),
        ),
      ],
    );
  }
}

// ── Leyenda ─────────────────────────────────────────────────

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
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.cafeMedio)),
      ],
    );
  }
}