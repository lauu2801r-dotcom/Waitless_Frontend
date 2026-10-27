import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/calificaciones_service.dart';
import '../../services/inventario_service.dart' show InvExito, InvError;
import '../../theme/app_theme.dart';
import '../../widgets/calificar_pedido.dart' show Estrellas;
import '../../widgets/notificaciones_sheet.dart' show tiempoRelativo;

void mostrarCalificacionesAdmin(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _CalificacionesAdminSheet(),
  );
}

class _CalificacionesAdminSheet extends StatefulWidget {
  const _CalificacionesAdminSheet();

  @override
  State<_CalificacionesAdminSheet> createState() =>
      _CalificacionesAdminSheetState();
}

class _CalificacionesAdminSheetState extends State<_CalificacionesAdminSheet> {
  ResumenCalificaciones? _datos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await CalificacionesService.resumen();
    if (!mounted) return;
    setState(() {
      switch (r) {
        case InvExito(:final datos):
          _datos = datos;
        case InvError(:final mensaje):
          _error = mensaje;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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
            Text('Calificaciones', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 12),
            Expanded(child: _contenido(scroll)),
          ],
        ),
      ),
    );
  }

  Widget _contenido(ScrollController scroll) {
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: GoogleFonts.inter(color: AppColors.cafeMedio)));
    }
    final d = _datos;
    if (d == null) return const Center(child: CircularProgressIndicator());
    if (d.total == 0) {
      return Center(
        child: Text('Aún no hay calificaciones de tus clientes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
      );
    }
    final maxDist = d.distribucion.values.fold<int>(1, (a, b) => b > a ? b : a);
    return ListView(
      controller: scroll,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(d.promedio.toStringAsFixed(1),
                    style: AppTheme.titulo(size: 40)),
                Estrellas(valor: d.promedio, size: 16),
                const SizedBox(height: 2),
                Text('${d.total} calificaciones',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.cafeMedio)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  for (var e = 5; e >= 1; e--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$e',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.cafeMedio)),
                          const Icon(Icons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (d.distribucion[e] ?? 0) / maxDist,
                                minHeight: 7,
                                backgroundColor: AppColors.cremaOscura,
                                color: AppColors.terracota,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 22,
                            child: Text('${d.distribucion[e] ?? 0}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.cafeMedio)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _titulo('Mejor calificados'),
        for (final p in d.mejores) _filaPlato(p),
        if (d.porMejorar.isNotEmpty) ...[
          const SizedBox(height: 14),
          _titulo('Por mejorar (menos de 4★)'),
          for (final p in d.porMejorar) _filaPlato(p),
        ],
        const SizedBox(height: 14),
        _titulo('Comentarios recientes'),
        for (final c in d.recientes) _filaReciente(c),
      ],
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro)),
      );

  Widget _filaPlato(PlatoCalificado p) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(p.nombre,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.cafeOscuro)),
            ),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 3),
            Text('${p.promedio.toStringAsFixed(1)} (${p.total})',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeMedio)),
          ],
        ),
      );

  Widget _filaReciente(CalifReciente c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${c.cliente} · ${c.plato}',
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                ),
                Estrellas(valor: c.estrellas.toDouble(), size: 13),
              ],
            ),
            if ((c.comentario ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(c.comentario!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.cafeMedio)),
            ],
            const SizedBox(height: 4),
            Text('Pedido #${c.pedidoId} · ${tiempoRelativo(c.creadoEn)}',
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.cafeMedio)),
          ],
        ),
      );
}
