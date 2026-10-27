import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notificaciones_service.dart';
import '../theme/app_theme.dart';

/// Abre la hoja con las notificaciones reales del usuario.
void mostrarNotificaciones(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const NotificacionesSheet(),
  );
}

IconData _icono(String tipo) => switch (tipo) {
      'pedido' => Icons.local_dining,
      'pago' => Icons.receipt_long,
      'reserva' => Icons.event,
      'calificacion' => Icons.star,
      'promo' => Icons.local_offer,
      _ => Icons.notifications,
    };

String tiempoRelativo(DateTime? d) {
  if (d == null) return '';
  final dif = DateTime.now().difference(d);
  if (dif.inSeconds < 60) return 'justo ahora';
  if (dif.inMinutes < 60) return 'hace ${dif.inMinutes} min';
  if (dif.inHours < 24) {
    return 'hace ${dif.inHours} ${dif.inHours == 1 ? 'hora' : 'horas'}';
  }
  if (dif.inDays == 1) return 'ayer';
  if (dif.inDays < 7) return 'hace ${dif.inDays} días';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class NotificacionesSheet extends StatefulWidget {
  const NotificacionesSheet({super.key});

  @override
  State<NotificacionesSheet> createState() => _NotificacionesSheetState();
}

class _NotificacionesSheetState extends State<NotificacionesSheet> {
  final NotificacionesCenter _centro = NotificacionesCenter.instancia;
  // ids que estaban sin leer al abrir (se resaltan aunque ya se marquen leídas)
  Set<int> _nuevas = {};
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    _nuevas = _centro.items.where((n) => !n.leida).map((n) => n.id).toSet();
    _cargar();
  }

  Future<void> _cargar() async {
    await _centro.refrescar();
    if (!mounted) return;
    setState(() {
      _nuevas = {
        ..._nuevas,
        ..._centro.items.where((n) => !n.leida).map((n) => n.id),
      };
      _primeraCarga = false;
    });
    await _centro.marcarTodasLeidas(); // al verlas se quita el punto de la campana
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
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
            const SizedBox(height: 16),
            Text('Notificaciones', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 14),
            Expanded(
              child: ListenableBuilder(
                listenable: _centro,
                builder: (context, _) {
                  final lista = _centro.items;
                  if (_primeraCarga && lista.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (lista.isEmpty) {
                    return ListView(
                      controller: scroll,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(Icons.notifications_none,
                            size: 48, color: AppColors.cafeMedio),
                        const SizedBox(height: 10),
                        Text(
                          _centro.error ?? 'Aún no tienes notificaciones',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.cafeMedio),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: scroll,
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final n = lista[i];
                      return Dismissible(
                        key: ValueKey('notif-${n.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _centro.eliminar(n.id),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.only(right: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: AppColors.alertaFondo,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: AppColors.alertaTexto),
                        ),
                        child: _ItemNotificacionReal(
                          n: n,
                          esNueva: _nuevas.contains(n.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemNotificacionReal extends StatelessWidget {
  final NotificacionApi n;
  final bool esNueva;
  const _ItemNotificacionReal({required this.n, required this.esNueva});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esNueva ? AppColors.alertaFondo : AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esNueva
              ? AppColors.terracota.withValues(alpha: 0.3)
              : AppColors.borde,
        ),
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
            child: Icon(_icono(n.tipo), color: AppColors.terracota, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.titulo,
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                    ),
                    if (esNueva)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.terracota,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if ((n.detalle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.detalle!,
                      style: GoogleFonts.inter(
                          fontSize: 11.5, color: AppColors.cafeMedio)),
                ],
                const SizedBox(height: 4),
                Text(tiempoRelativo(n.creadoEn),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.cafeMedio,
                        letterSpacing: 0.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
