import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_controller.dart';
import '../../data/mock_data.dart';
import '../../utils/app_strings.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombreRestaurante = auth.usuario?.nombreRestaurante ?? 'Mi Restaurante';
    final restauranteId = auth.usuario?.restauranteId ?? 'rest_001';
    final conDatos = auth.usuario?.conDatos ?? false;

    // Obtener pedidos del restaurante (vacío si recién registrado)
    final pedidosRestaurante =
        conDatos ? PedidosMock.porRestaurante(restauranteId) : [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════ HEADER ═══════════════════
              Text(
                '${AppStrings.t(context, 'hola')} 👋',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.cafeOscuro.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nombreRestaurante,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(context, 'resumen_hoy'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                ),
              ),
              const SizedBox(height: 24),

              // ═══════════════════ TARJETAS DE MÉTRICAS ═══════════════════
              Row(
                children: [
                  Expanded(
                    child: _TarjetaMetrica(
                      icono: Icons.attach_money,
                      titulo: AppStrings.t(context, 'ventas_hoy'),
                      valor: conDatos ? '\$1,250' : '\$0',
                      color: AppColors.terracota,
                      tendencia: conDatos ? '+12%' : '—',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TarjetaMetrica(
                      icono: Icons.receipt_long,
                      titulo: AppStrings.t(context, 'pedidos_activos'),
                      valor: '${pedidosRestaurante.length}',
                      color: AppColors.oliva,
                      tendencia: conDatos ? '+3' : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TarjetaMetrica(
                      icono: Icons.table_restaurant,
                      titulo: AppStrings.t(context, 'mesas_ocupadas'),
                      valor: conDatos ? '6/9' : '0/14',
                      color: AppColors.terracotaOscuro,
                      tendencia: conDatos ? '67%' : '—',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TarjetaMetrica(
                      icono: Icons.people,
                      titulo: AppStrings.t(context, 'clientes_hoy'),
                      valor: conDatos ? '24' : '0',
                      color: AppColors.cafeMedio,
                      tendencia: conDatos ? '+5' : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ═══════════════════ PEDIDOS RECIENTES ═══════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t(context, 'pedidos_recientes'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  Text(
                    AppStrings.t(context, 'ver_todos'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.terracota,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _TarjetaPedidoReciente(
                mesa: 5,
                productos: 3,
                total: 145,
                estado: 'Preparando',
                tiempo: 'hace 8 min',
              ),
              const _TarjetaPedidoReciente(
                mesa: 2,
                productos: 2,
                total: 89,
                estado: 'Nuevo',
                tiempo: 'hace 3 min',
              ),
              const _TarjetaPedidoReciente(
                mesa: 7,
                productos: 4,
                total: 220,
                estado: 'Listo',
                tiempo: 'hace 15 min',
              ),
              const SizedBox(height: 28),

              // ═══════════════════ TOP PLATOS ═══════════════════
              Text(
                'Top platos del día',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro,
                ),
              ),
              const SizedBox(height: 12),
              const _TarjetaTopPlato(
                posicion: 1,
                emoji: '🍝',
                nombre: 'Pasta Carbonara',
                vendidos: 18,
                ingresos: '\$324',
              ),
              const _TarjetaTopPlato(
                posicion: 2,
                emoji: '🥩',
                nombre: 'Bife de Chorizo',
                vendidos: 12,
                ingresos: '\$420',
              ),
              const _TarjetaTopPlato(
                posicion: 3,
                emoji: '🍕',
                nombre: 'Pizza Margherita',
                vendidos: 10,
                ingresos: '\$180',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Tarjeta de Métrica
// ═══════════════════════════════════════════════════════════
class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final String tendencia;

  const _TarjetaMetrica({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.tendencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tendencia,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Tarjeta de Pedido Reciente
// ═══════════════════════════════════════════════════════════
class _TarjetaPedidoReciente extends StatelessWidget {
  final int mesa;
  final int productos;
  final double total;
  final String estado;
  final String tiempo;

  const _TarjetaPedidoReciente({
    required this.mesa,
    required this.productos,
    required this.total,
    required this.estado,
    required this.tiempo,
  });

  Color _getColorEstado() {
    switch (estado) {
      case 'Nuevo':
        return AppColors.oliva;
      case 'Preparando':
        return AppColors.terracotaOscuro;
      case 'Listo':
        return AppColors.terracota;
      default:
        return AppColors.cafeOscuro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _getColorEstado();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$mesa',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorEstado,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa $mesa · $productos productos',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estado,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorEstado,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· $tiempo',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.cafeMedio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(0)}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.terracota,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: Tarjeta Top Plato
// ═══════════════════════════════════════════════════════════
class _TarjetaTopPlato extends StatelessWidget {
  final int posicion;
  final String emoji;
  final String nombre;
  final int vendidos;
  final String ingresos;

  const _TarjetaTopPlato({
    required this.posicion,
    required this.emoji,
    required this.nombre,
    required this.vendidos,
    required this.ingresos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$posicion',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracota,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$vendidos vendidos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.cafeMedio,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ingresos,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.terracota,
            ),
          ),
        ],
      ),
    );
  }
}