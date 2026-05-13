import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_controller.dart';
import '../../services/prediccion_service.dart';
import '../../services/mesa_service.dart'; // MesaService, MesaModel
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../../widgets/common_widgets.dart';

class PrediccionScreen extends StatefulWidget {
  const PrediccionScreen({super.key});

  @override
  State<PrediccionScreen> createState() => _PrediccionScreenState();
}

class _PrediccionScreenState extends State<PrediccionScreen> {
  List<DatoAfluenciaHora> _afluencia = [];
  int _mesasOcupadas = 0;
  int _mesasTotales = 14;
  bool _cargando = true;
  String? _error;

  // Predicción rápida para "ahora"
  PrediccionTiempo? _prediccionAhora;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });

    final ahora = DateTime.now();

    // 1. Afluencia por hora del día actual
    final resultAfluencia = await PrediccionService.afluenciaPorHora(
      diaSemana: ahora.weekday - 1, // DateTime: 1=lun, nosotros: 0=lun
    );

    // 2. Mesas ocupadas actualmente
    int ocupadas = 0;
    int totales = 14;
    try {
      final mesaService = MesaService();
      final todasMesas = await mesaService.todasLasMesas();
      ocupadas = todasMesas.where((m) => m.estado == 'ocupada').length;
      totales = todasMesas.length;
    } catch (_) {}

    // 3. Predicción para este momento (3 items promedio, $45000 promedio)
    final resultPrediccion = await PrediccionService.predecirTiempoEspera(
      hora: ahora.hour,
      diaSemana: ahora.weekday - 1,
      mesasOcupadas: ocupadas,
      totalItems: 3,
      totalPedido: 45000,
    );

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resultAfluencia is IaExito<List<DatoAfluenciaHora>>) {
        _afluencia = resultAfluencia.datos;
      }
      _mesasOcupadas = ocupadas;
      _mesasTotales = totales;
      if (resultPrediccion is IaExito<PrediccionTiempo>) {
        _prediccionAhora = resultPrediccion.datos;
      } else if (resultPrediccion is IaError) {
        _error = (resultPrediccion as IaError).mensaje;
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(context, 'momento_ideal'),
                    style: AppTheme.titulo(size: 30)),
                const SizedBox(height: 4),
                Text(AppStrings.t(context, 'prediccion_afluencia'),
                    style: AppTheme.etiqueta()),
                const SizedBox(height: 20),

                if (!conDatos) ...[
                  _tarjetaSinDatos(context),
                ] else if (_cargando) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.terracota),
                    ),
                  ),
                ] else if (_error != null) ...[
                  _tarjetaError(),
                ] else ...[
                  _tarjetaMejorHora(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TarjetaMetrica(
                          etiqueta: 'ESPERA AHORA',
                          valor: _prediccionAhora != null
                              ? '${_prediccionAhora!.minutosEstimados} min'
                              : '-- min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TarjetaMetrica(
                          etiqueta: 'MESAS LIBRES',
                          valor: '${_mesasTotales - _mesasOcupadas} / $_mesasTotales',
                          colorFondo: AppColors.olivaFondo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('TENDENCIA DE LA SEMANA', style: AppTheme.etiqueta()),
                  const SizedBox(height: 12),
                  _graficaTendenciaSemanal(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarjeta mejor hora + gráfica de barras ─────────────────

  Widget _tarjetaMejorHora() {
    // Hora más tranquila del día
    DatoAfluenciaHora? masTransquila;
    DatoAfluenciaHora? horaActual;
    final ahoraH = DateTime.now().hour;

    if (_afluencia.isNotEmpty) {
      masTransquila = _afluencia.reduce(
          (a, b) => a.ocupacionPct < b.ocupacionPct ? a : b);
      try {
        horaActual = _afluencia.firstWhere(
          (h) => int.parse(h.hora.split(':')[0]) == ahoraH,
        );
      } catch (_) {}
    }

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
              const Icon(Icons.trending_down, color: AppColors.oliva, size: 18),
              const SizedBox(width: 6),
              Text('MEJOR HORA SUGERIDA', style: AppTheme.etiqueta()),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                masTransquila?.horaLabel.replaceAll('am', '').replaceAll('pm', '') ?? '--',
                style: AppTheme.titulo(size: 44, color: AppColors.terracota),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  masTransquila?.horaLabel.contains('pm') == true ? 'pm' : 'am',
                  style: AppTheme.titulo(size: 18, color: AppColors.terracota),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            masTransquila != null
                ? 'Solo ${masTransquila.ocupacionPct}% de ocupación esperada'
                : 'Cargando...',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
          ),
          const SizedBox(height: 24),

          // Gráfica de barras desde la API
          if (_afluencia.isNotEmpty)
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.cafeOscuro,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        '${rod.toY.round()}% ocupación',
                        GoogleFonts.inter(
                          color: AppColors.crema,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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
                                  fontSize: 9, color: AppColors.cafeMedio),
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

  Widget _graficaTendenciaSemanal() {
    // Tomamos la afluencia de cada día de la semana (lun-dom) para el mismo horario
    // Como la API retorna horas del día, simulamos la curva semanal usando
    // el promedio de ocupación del día actual y variaciones por día
    final base = _afluencia.isNotEmpty
        ? _afluencia.map((h) => h.ocupacionPct).reduce((a, b) => a + b) /
            _afluencia.length
        : 65.0;

    final spots = [
      FlSpot(0, (base * 0.85).clamp(0, 100)),
      FlSpot(1, (base * 0.92).clamp(0, 100)),
      FlSpot(2, (base * 0.78).clamp(0, 100)),
      FlSpot(3, (base * 1.05).clamp(0, 100)),
      FlSpot(4, (base * 1.20).clamp(0, 100)),
      FlSpot(5, (base * 1.35).clamp(0, 100)),
      FlSpot(6, (base * 1.10).clamp(0, 100)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: SizedBox(
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dias[i],
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.cafeMedio)),
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
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.terracota,
                    strokeColor: AppColors.crema,
                    strokeWidth: 2,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.terracota.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
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
        border: Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.terracota, size: 32),
          const SizedBox(height: 8),
          Text('Sin conexión con el servidor',
              style: AppTheme.titulo(size: 14, color: AppColors.terracotaOscuro)),
          const SizedBox(height: 4),
          Text(_error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.cafeMedio)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cargarDatos,
            child: Text('Reintentar',
                style: GoogleFonts.inter(color: AppColors.terracota)),
          ),
        ],
      ),
    );
  }
}

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