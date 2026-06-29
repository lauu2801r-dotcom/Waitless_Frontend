import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/pedido.dart';

/// Chip para mostrar el estado de un pedido.
class ChipEstado extends StatelessWidget {
  final EstadoPedido estado;
  const ChipEstado({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estado.colorFondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.etiqueta,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: estado.colorTexto,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Tarjeta con una métrica destacada (ej: tiempo de espera, ocupación).
class TarjetaMetrica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color colorFondo;

  const TarjetaMetrica({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.colorFondo = AppColors.cremaOscura,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: AppTheme.etiqueta()),
          const SizedBox(height: 4),
          Text(valor, style: AppTheme.titulo(size: 22)),
        ],
      ),
    );
  }
}

/// Tarjeta de pedido para el listado en tiempo real.
class TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTap;

  const TarjetaPedido({super.key, required this.pedido, this.onTap});

  @override
  Widget build(BuildContext context) {
    final esEntregado = pedido.estado == EstadoPedido.entregado;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: esEntregado ? 0.65 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra lateral de color según estado
                    Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: pedido.estado.colorAcento,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PEDIDO #${pedido.numero}',
                              style: AppTheme.etiqueta(size: 10)),
                          const SizedBox(height: 2),
                          Text(
                            pedido.plato,
                            style: AppTheme.titulo(size: 16),
                          ),
                        ],
                      ),
                    ),
                    ChipEstado(estado: pedido.estado),
                  ],
                ),
                if (!esEntregado) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pedido.estado.progreso,
                      minHeight: 4,
                      backgroundColor: AppColors.cremaOscura,
                      valueColor: AlwaysStoppedAnimation(
                          pedido.estado.colorAcento),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pedido.minutosRestantes > 0
                        ? 'Listo en ~${pedido.minutosRestantes} min'
                        : 'Llegando a tu mesa',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
