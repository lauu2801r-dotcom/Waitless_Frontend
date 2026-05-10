import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../widgets/common_widgets.dart';

class PrediccionScreen extends StatelessWidget {
  const PrediccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conDatos = AuthScope.of(context).usuario?.conDatos ?? false;
    final horasOcupacion = [
      _DatoHora('12p', 30),
      _DatoHora('1p', 45),
      _DatoHora('2p', 85),
      _DatoHora('3p', 95),
      _DatoHora('4p', 60),
      _DatoHora('5p', 25, esAhora: true),
      _DatoHora('6p', 40),
      _DatoHora('7p', 70),
      _DatoHora('8p', 90),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t(context, 'momento_ideal'),
                  style: AppTheme.titulo(size: 30)),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(context, 'prediccion_afluencia'),
                style: AppTheme.etiqueta(),
              ),
              const SizedBox(height: 20),

              if (!conDatos) ...[
                Container(
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
                          fontSize: 12.5,
                          color: AppColors.cafeMedio,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[

              Container(
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
                        const Icon(Icons.trending_down,
                            color: AppColors.oliva, size: 18),
                        const SizedBox(width: 6),
                        Text('MEJOR HORA SUGERIDA',
                            style: AppTheme.etiqueta()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '5:30',
                          style: AppTheme.titulo(
                              size: 44, color: AppColors.terracota),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'pm',
                            style: AppTheme.titulo(
                                size: 18, color: AppColors.terracota),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo 25% de ocupación esperada',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.cafeMedio),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.cafeOscuro,
                              getTooltipItem: (group, _, rod, __) {
                                return BarTooltipItem(
                                  '${rod.toY.round()}% ocupación',
                                  GoogleFonts.inter(
                                    color: AppColors.crema,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                getTitlesWidget: (value, _) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= horasOcupacion.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      horasOcupacion[i].hora,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.cafeMedio),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: horasOcupacion.asMap().entries.map((e) {
                            final i = e.key;
                            final d = e.value;
                            final color = d.esAhora
                                ? AppColors.oliva
                                : d.valor > 70
                                    ? AppColors.terracota
                                        .withValues(alpha: 0.55)
                                    : d.valor > 40
                                        ? const Color(0xFFD9B896)
                                        : AppColors.cremaOscura;
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: d.valor.toDouble(),
                                  color: color,
                                  width: 20,
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
                        const _Leyenda(
                            color: AppColors.oliva, label: 'Ahora'),
                        const SizedBox(width: 14),
                        const _Leyenda(
                            color: AppColors.cremaOscura, label: 'Tranquilo'),
                        const SizedBox(width: 14),
                        _Leyenda(
                            color: AppColors.terracota.withValues(alpha: 0.55),
                            label: 'Lleno'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Row(
                children: [
                  Expanded(
                    child: TarjetaMetrica(
                      etiqueta: 'ESPERA PROMEDIO',
                      valor: '12 min',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TarjetaMetrica(
                      etiqueta: 'MESAS LIBRES',
                      valor: '9 / 14',
                      colorFondo: AppColors.olivaFondo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text('TENDENCIA DE LA SEMANA', style: AppTheme.etiqueta()),
              const SizedBox(height: 12),

              Container(
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
                              const dias = [
                                'L',
                                'M',
                                'M',
                                'J',
                                'V',
                                'S',
                                'D'
                              ];
                              final i = value.toInt();
                              if (i < 0 || i >= dias.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  dias[i],
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.cafeMedio),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 55),
                            FlSpot(1, 62),
                            FlSpot(2, 48),
                            FlSpot(3, 70),
                            FlSpot(4, 85),
                            FlSpot(5, 92),
                            FlSpot(6, 78),
                          ],
                          isCurved: true,
                          color: AppColors.terracota,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
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
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoHora {
  final String hora;
  final int valor;
  final bool esAhora;
  _DatoHora(this.hora, this.valor, {this.esAhora = false});
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
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.cafeMedio)),
      ],
    );
  }
}