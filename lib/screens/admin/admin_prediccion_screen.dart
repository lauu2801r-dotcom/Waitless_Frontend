import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_controller.dart';
import '../../../services/prediccion_service.dart';
import '../../../services/mesa_service.dart'; // MesaService, MesaModel
import '../../../theme/app_theme.dart';

class AdminPrediccionScreen extends StatefulWidget {
  const AdminPrediccionScreen({super.key});

  @override
  State<AdminPrediccionScreen> createState() => _AdminPrediccionScreenState();
}

class _AdminPrediccionScreenState extends State<AdminPrediccionScreen> {
  List<DatoAfluenciaHora> _afluencia = [];
  MetricasModelo? _metricas;
  int _mesasOcupadas = 0;
  int _mesasTotales = 14;
  bool _cargando = true;
  bool _entrenando = false;
  String? _error;
  int _diaSeleccionado = 0; // 0=lun…6=dom

  static const _diasNombre = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = DateTime.now().weekday - 1;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });

    // 1. Afluencia por hora
    final resAfluencia = await PrediccionService.afluenciaPorHora(
      diaSemana: _diaSeleccionado,
    );

    // 2. Métricas del modelo
    final resMetricas = await PrediccionService.obtenerMetricas();

    // 3. Mesas
    int ocupadas = 0, totales = 14;
    try {
      final mesaService = MesaService();
      final todasMesas = await mesaService.todasLasMesas();
      ocupadas = todasMesas.where((m) => m.estado == 'ocupada').length;
      totales = todasMesas.length;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resAfluencia is IaExito<List<DatoAfluenciaHora>>) {
        _afluencia = resAfluencia.datos;
      } else {
        _error = 'No se pudo cargar la afluencia';
      }
      if (resMetricas is IaExito<MetricasModelo>) {
        _metricas = resMetricas.datos;
      }
      _mesasOcupadas = ocupadas;
      _mesasTotales = totales;
    });
  }

  Future<void> _reentrenar() async {
    setState(() => _entrenando = true);
    final res = await PrediccionService.entrenarModelo();
    if (!mounted) return;
    setState(() => _entrenando = false);

    if (res is IaExito<Map<String, dynamic>>) {
      final datos = res.datos;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Modelo re-entrenado ✓  MAE: ${datos['mae_minutos']} min · '
            'R²: ${datos['r2_score']} · ${datos['total_muestras']} muestras',
          ),
          backgroundColor: AppColors.oliva,
        ));
        _cargarDatos(); // recarga métricas
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al re-entrenar el modelo'),
          backgroundColor: AppColors.terracota,
        ));
      }
    }
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Análisis', style: AppTheme.titulo(size: 30)),
                    if (!_entrenando)
                      TextButton.icon(
                        onPressed: _reentrenar,
                        icon: const Icon(Icons.model_training,
                            color: AppColors.terracota, size: 16),
                        label: Text('Re-entrenar',
                            style: GoogleFonts.inter(
                                color: AppColors.terracota, fontSize: 12)),
                      )
                    else
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.terracota),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('PREDICCIONES Y MÉTRICAS', style: AppTheme.etiqueta()),
                const SizedBox(height: 20),

                if (!conDatos) ...[
                  _tarjetaSinDatos(),
                ] else if (_cargando) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.terracota),
                    ),
                  ),
                ] else ...[

                  // ── Hora pico ─────────────────────────────
                  if (_afluencia.isNotEmpty) _tarjetaHoraPico(),
                  const SizedBox(height: 14),

                  // ── Selector de día ───────────────────────
                  _selectorDia(),
                  const SizedBox(height: 12),

                  // ── Gráfica de ocupación ──────────────────
                  _graficaOcupacion(),
                  const SizedBox(height: 14),

                  // ── Métricas IA ───────────────────────────
                  Text('MODELO DE IA', style: AppTheme.etiqueta()),
                  const SizedBox(height: 12),
                  _tarjetasMetricas(),
                  const SizedBox(height: 20),

                  // ── Mesas + ocupación hoy ─────────────────
                  Text('ESTADO ACTUAL', style: AppTheme.etiqueta()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricaCard(
                          icono: Icons.table_restaurant,
                          valor: '$_mesasOcupadas/$_mesasTotales',
                          etiqueta: 'MESAS OCUPADAS',
                          color: AppColors.cremaOscura,
                          iconColor: AppColors.terracota,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricaCard(
                          icono: Icons.access_time,
                          valor: _metricas?.tiempoPromedioPredicho != null
                              ? '${_metricas!.tiempoPromedioPredicho!.round()}m'
                              : '--',
                          etiqueta: 'ESPERA PROM.',
                          color: AppColors.infoFondo,
                          iconColor: AppColors.infoTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hora pico ──────────────────────────────────────────────

  Widget _tarjetaHoraPico() {
    final pico = _afluencia.reduce(
        (a, b) => a.ocupacionPct > b.ocupacionPct ? a : b);

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
                Text('HORA PICO PRONOSTICADA',
                    style: AppTheme.etiqueta(
                        size: 10, color: AppColors.terracota)),
                const SizedBox(height: 2),
                Text('${pico.hora} · ${pico.ocupacionPct}% ocupación',
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
                  color: seleccionado
                      ? AppColors.terracota
                      : AppColors.borde,
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
              Text('OCUPACIÓN POR HORA', style: AppTheme.etiqueta()),
            ],
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
                                    fontSize: 9,
                                    color: AppColors.cafeMedio)),
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
                      x: i,
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

  // ── Tarjetas de métricas IA ────────────────────────────────

  Widget _tarjetasMetricas() {
    final mae = _metricas?.maeMinutos;
    final prec = _metricas?.precision10minPct;
    final muestras = _metricas?.totalPedidosEvaluados ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricaCard(
                icono: Icons.precision_manufacturing,
                valor: mae != null ? '${mae.toStringAsFixed(1)}m' : '--',
                etiqueta: 'ERROR PROMEDIO',
                color: AppColors.alertaFondo,
                iconColor: AppColors.terracotaOscuro,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricaCard(
                icono: Icons.check_circle_outline,
                valor: prec != null ? '${prec.toStringAsFixed(0)}%' : '--',
                etiqueta: 'PRECISIÓN ±10min',
                color: AppColors.olivaFondo,
                iconColor: AppColors.oliva,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricaCard(
                icono: Icons.dataset,
                valor: muestras > 0 ? '$muestras' : 'Sin datos',
                etiqueta: 'PEDIDOS EVALUADOS',
                color: AppColors.infoFondo,
                iconColor: AppColors.infoTexto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricaCard(
                icono: Icons.people_outline,
                valor: '$_mesasOcupadas',
                etiqueta: 'MESAS EN USO',
                color: AppColors.cremaOscura,
                iconColor: AppColors.terracota,
              ),
            ),
          ],
        ),
      ],
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
          Text('Aún sin datos suficientes',
              style: AppTheme.titulo(size: 18)),
          const SizedBox(height: 6),
          Text(
            'A medida que recibas pedidos, aquí verás\nlas predicciones de afluencia y ventas.',
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