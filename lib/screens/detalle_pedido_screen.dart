import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';

class DetallePedidoScreen extends StatelessWidget {
  final PedidoApi pedido;
  const DetallePedidoScreen({super.key, required this.pedido});

  void _llamarMesero(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent,
                    color: AppColors.terracota, size: 32),
              ),
            ),
            const SizedBox(height: 14),
            Text('Llamar al mesero',
                textAlign: TextAlign.center,
                style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 6),
            Text(
              'Selecciona el motivo y el mesero asignado a tu mesa lo recibirá al instante.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.cafeMedio,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _MotivoMesero(
              icono: Icons.local_drink_outlined,
              titulo: 'Pedir más bebida',
              onTap: () => _confirmarLlamada(ctx, 'Bebida adicional'),
            ),
            _MotivoMesero(
              icono: Icons.lunch_dining_outlined,
              titulo: 'Pedir más pan / acompañamiento',
              onTap: () => _confirmarLlamada(ctx, 'Acompañamiento'),
            ),
            _MotivoMesero(
              icono: Icons.receipt_outlined,
              titulo: 'Pedir la cuenta',
              onTap: () => _confirmarLlamada(ctx, 'La cuenta'),
            ),
            _MotivoMesero(
              icono: Icons.help_outline,
              titulo: 'Tengo otra duda',
              onTap: () => _confirmarLlamada(ctx, 'Consulta general'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLlamada(BuildContext ctx, String motivo) {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          'El mesero fue notificado: $motivo',
          style: GoogleFonts.inter(color: AppColors.crema),
        ),
        backgroundColor: AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Color _colorEstado() {
    if (pedido.estado == EstadoPedidoApi.pendiente) return AppColors.cafeMedio;
    if (pedido.estado == EstadoPedidoApi.en_preparacion) return AppColors.oliva;
    if (pedido.estado == EstadoPedidoApi.listo) return AppColors.terracota;
    if (pedido.estado == EstadoPedidoApi.entregado) return AppColors.exitoTexto;
    return AppColors.cafeMedio; // cancelado
  }

  @override
  Widget build(BuildContext context) {
    final cantItems = pedido.items.fold(0, (s, i) => s + i.cantidad);
    final color = _colorEstado();

    // Pasos del timeline según EstadoPedidoApi
    final pasos = [
      _PasoTimeline('Pendiente', EstadoPedidoApi.pendiente),
      _PasoTimeline('En preparación', EstadoPedidoApi.en_preparacion),
      _PasoTimeline('Listo', EstadoPedidoApi.listo),
      _PasoTimeline('Entregado', EstadoPedidoApi.entregado),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${pedido.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tarjeta principal ──
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
                  // Estado + hora
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pedido.estado.etiqueta,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                      Text(
                        pedido.horaFormateada,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.cafeMedio),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mesa e items
                  Text(
                    'Mesa ${pedido.mesaId}',
                    style: AppTheme.titulo(size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$cantItems ${cantItems == 1 ? 'producto' : 'productos'}',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.cafeMedio),
                  ),

                  if (pedido.notas != null && pedido.notas!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Nota: ${pedido.notas}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.cafeMedio,
                          fontStyle: FontStyle.italic),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.bordeSuave, height: 1),
                  const SizedBox(height: 20),

                  // Timeline
                  Text('PROGRESO EN TIEMPO REAL',
                      style: AppTheme.etiqueta()),
                  const SizedBox(height: 16),

                  ...List.generate(pasos.length, (i) {
                    final paso = pasos[i];
                    final actual = paso.estado == pedido.estado;
                    final completado =
                        paso.estado.progreso < pedido.estado.progreso ||
                            actual;
                    return _TimelineStep(
                      titulo: paso.titulo,
                      esUltimo: i == pasos.length - 1,
                      completado: completado,
                      actual: actual,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Resumen de items ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DETALLE DEL PEDIDO', style: AppTheme.etiqueta()),
                  const SizedBox(height: 12),
                  ...pedido.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.cantidad}x Producto #${item.productoId}',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.cafeOscuro),
                            ),
                            Text(
                              '\$${item.subtotal.toInt()}',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.cafeOscuro,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.bordeSuave, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.cafeMedio)),
                      Text(
                        pedido.totalFormateado,
                        style: AppTheme.titulo(size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Llamar al mesero ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _llamarMesero(context),
                icon: const Icon(Icons.support_agent,
                    color: AppColors.terracota),
                label: Text(
                  'Llamar al mesero',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.terracota,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.terracota),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HELPERS INTERNOS
// ─────────────────────────────────────────────────────────────

class _PasoTimeline {
  final String titulo;
  final EstadoPedidoApi estado;
  _PasoTimeline(this.titulo, this.estado);
}

class _TimelineStep extends StatelessWidget {
  final String titulo;
  final bool esUltimo;
  final bool completado;
  final bool actual;

  const _TimelineStep({
    required this.titulo,
    required this.esUltimo,
    required this.completado,
    required this.actual,
  });

  @override
  Widget build(BuildContext context) {
    final color = actual
        ? AppColors.terracota
        : completado
            ? AppColors.oliva
            : AppColors.bordeSuave;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: actual ? AppColors.crema : color,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!esUltimo)
                Expanded(
                  child: Container(
                    width: 2,
                    color: completado
                        ? AppColors.oliva
                        : AppColors.bordeSuave,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : 18),
              child: Text(
                titulo,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: actual || completado
                      ? AppColors.cafeOscuro
                      : AppColors.cafeMedio,
                  fontWeight:
                      actual ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivoMesero extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;
  const _MotivoMesero({
    required this.icono,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: AppColors.terracota, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.cafeMedio, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}