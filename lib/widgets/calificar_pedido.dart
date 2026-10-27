import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/calificaciones_service.dart';
import '../services/inventario_service.dart' show InvExito, InvError;
import '../services/notificaciones_service.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';

/// Fila de estrellas (solo mostrar, o tocar si se pasa [onCambio]).
class Estrellas extends StatelessWidget {
  final double valor;
  final double size;
  final ValueChanged<int>? onCambio;
  const Estrellas({super.key, required this.valor, this.size = 16, this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final llena = valor >= i + 1;
        final media = !llena && valor > i && valor - i >= 0.5;
        final icono = Icon(
          llena ? Icons.star : (media ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: size,
        );
        if (onCambio == null) return icono;
        return GestureDetector(
          onTap: () => onCambio!(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: icono,
          ),
        );
      }),
    );
  }
}

/// Bloque de la pantalla de detalle del pedido: botón «Calificar» cuando el
/// pedido ya está pagado, o las estrellas que el cliente dio.
class CalificarPedido extends StatefulWidget {
  final PedidoApi pedido;
  const CalificarPedido({super.key, required this.pedido});

  @override
  State<CalificarPedido> createState() => _CalificarPedidoState();
}

class _CalificarPedidoState extends State<CalificarPedido> {
  EstadoCalificacion? _estado;

  @override
  void initState() {
    super.initState();
    // Si el cliente paga en esta misma pantalla llega una notificación: se vuelve a revisar.
    NotificacionesCenter.instancia.addListener(_alCambiarNotificaciones);
    _revisar();
  }

  @override
  void dispose() {
    NotificacionesCenter.instancia.removeListener(_alCambiarNotificaciones);
    super.dispose();
  }

  void _alCambiarNotificaciones() {
    if (_estado == null || !_estado!.pagado) _revisar();
  }

  Future<void> _revisar() async {
    final r = await CalificacionesService.deUnPedido(widget.pedido.id);
    if (!mounted) return;
    if (r is InvExito<EstadoCalificacion>) setState(() => _estado = r.datos);
  }

  Future<void> _calificar() async {
    final nuevo = await showModalBottomSheet<EstadoCalificacion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CalificarSheet(pedido: widget.pedido),
    );
    if (nuevo != null && mounted) {
      setState(() => _estado = nuevo);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Gracias por tu calificación! ⭐'),
        backgroundColor: AppColors.oliva,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _estado;
    if (e == null || !e.pagado) return const SizedBox.shrink();

    if (e.calificado) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu calificación',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro)),
            const SizedBox(height: 8),
            for (final i in e.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(i.productoNombre,
                          style: GoogleFonts.inter(
                              fontSize: 12.5, color: AppColors.cafeMedio)),
                    ),
                    Estrellas(valor: i.estrellas.toDouble(), size: 16),
                  ],
                ),
              ),
            if ((e.comentario ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('“${e.comentario}”',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.cafeMedio)),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _calificar,
          icon: const Icon(Icons.star, color: Colors.amber),
          label: Text('Calificar mi pedido',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.terracota,
                  fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.terracota),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _CalificarSheet extends StatefulWidget {
  final PedidoApi pedido;
  const _CalificarSheet({required this.pedido});

  @override
  State<_CalificarSheet> createState() => _CalificarSheetState();
}

class _CalificarSheetState extends State<_CalificarSheet> {
  final TextEditingController _comentario = TextEditingController();
  final Map<int, int> _estrellas = {}; // productoId → estrellas
  late final List<MapEntry<int, String>> _platos;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final vistos = <int, String>{};
    for (final i in widget.pedido.items) {
      vistos.putIfAbsent(i.productoId, () => i.nombreProducto ?? 'Plato');
    }
    _platos = vistos.entries.toList();
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  bool get _completo =>
      _platos.isNotEmpty && _platos.every((p) => (_estrellas[p.key] ?? 0) > 0);

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final r = await CalificacionesService.calificar(
      pedidoId: widget.pedido.id,
      estrellasPorPlato: _estrellas,
      comentario: _comentario.text,
    );
    if (!mounted) return;
    switch (r) {
      case InvExito(:final datos):
        Navigator.pop(context, datos);
      case InvError(:final mensaje):
        setState(() {
          _enviando = false;
          _error = mensaje;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Text('¿Cómo estuvo tu pedido #${widget.pedido.id}?',
                style: AppTheme.titulo(size: 20)),
            const SizedBox(height: 4),
            Text('Califica cada plato de 1 a 5 estrellas.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.cafeMedio)),
            const SizedBox(height: 16),
            for (final p in _platos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.value,
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                    ),
                    Estrellas(
                      valor: (_estrellas[p.key] ?? 0).toDouble(),
                      size: 28,
                      onCambio: (v) => setState(() => _estrellas[p.key] = v),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            TextField(
              controller: _comentario,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Cuéntanos más (opcional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.alertaTexto)),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: (_completo && !_enviando) ? _enviar : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.terracota,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('ENVIAR CALIFICACIÓN'),
            ),
          ],
        ),
      ),
    );
  }
}
