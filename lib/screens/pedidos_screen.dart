import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/mock_data.dart';
import '../models/pedido.dart';
import '../services/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../widgets/common_widgets.dart';
import 'detalle_pedido_screen.dart';

class PedidosScreen extends StatelessWidget {
  final VoidCallback? onIrAInicio;
  const PedidosScreen({super.key, this.onIrAInicio});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.of(context).usuario;
    final primerNombre = usuario?.primerNombre;
    final pedidos = (usuario?.conDatos ?? false)
        ? PedidosMock.pedidosClientePersonalizados(primerNombre)
        : <Pedido>[];
    final activos = pedidos
        .where((p) => p.estado != EstadoPedido.entregado)
        .toList();
    final historicos = pedidos
        .where((p) => p.estado == EstadoPedido.entregado)
        .toList();

    final totalGastado = pedidos.fold<double>(0, (s, p) => s + p.precio);
    final enPreparacion = activos.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t(context, 'mis_pedidos'),
                          style: AppTheme.titulo(size: 30)),
                      const SizedBox(height: 4),
                      Text(AppStrings.t(context, 'seguimiento_vivo'),
                          style: AppTheme.etiqueta()),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.terracota.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search,
                        color: AppColors.terracota, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Resumen rápido
              Row(
                children: [
                  Expanded(
                    child: _TarjetaResumen(
                      icono: Icons.local_fire_department_outlined,
                      etiqueta: AppStrings.t(context, 'en_preparacion'),
                      valor: enPreparacion.toString(),
                      color: AppColors.terracota,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TarjetaResumen(
                      icono: Icons.receipt_long_outlined,
                      etiqueta: AppStrings.t(context, 'total_hoy'),
                      valor:
                          '\$${(totalGastado / 1000).toStringAsFixed(0)}K',
                      color: AppColors.oliva,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (activos.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.terracota,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppStrings.t(context, 'en_preparacion'),
                        style: AppTheme.etiqueta()),
                    const Spacer(),
                    Text(
                      '${activos.length} pedidos',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...activos.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaPedido(
                        pedido: p,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetallePedidoScreen(pedido: p),
                            ),
                          );
                        },
                      ),
                    )),
                const SizedBox(height: 24),
              ],

              if (historicos.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.history,
                        size: 14, color: AppColors.cafeMedio),
                    const SizedBox(width: 6),
                    Text(AppStrings.t(context, 'historial_hoy'),
                        style: AppTheme.etiqueta()),
                  ],
                ),
                const SizedBox(height: 12),
                ...historicos.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Opacity(
                        opacity: 0.7,
                        child: TarjetaPedido(
                          pedido: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetallePedidoScreen(pedido: p),
                              ),
                            );
                          },
                        ),
                      ),
                    )),
              ],

              if (activos.isEmpty && historicos.isEmpty) ...[
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
                        child: const Icon(Icons.restaurant_menu_outlined,
                            color: AppColors.terracota, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.t(context, 'sin_pedidos'),
                        style: AppTheme.titulo(size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.t(context, 'sin_pedidos_msg'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.cafeMedio,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: onIrAInicio,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(AppStrings.t(context, 'explorar_menu')),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Sugerencia de pedido (siempre visible para enriquecer)
              Text(AppStrings.t(context, 'sugerencia'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.terracota.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🍷', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Combina con un buen vino',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reserva Malbec con descuento del 15%',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.cafeMedio,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.cafeMedio),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;

  const _TarjetaResumen({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          Text(
            etiqueta,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}
