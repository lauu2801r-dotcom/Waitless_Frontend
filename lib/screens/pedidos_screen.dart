import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import 'detalle_pedido_screen.dart';

class PedidosScreen extends StatefulWidget {
  final VoidCallback? onIrAInicio;
  const PedidosScreen({super.key, this.onIrAInicio});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<PedidoApi> _pedidos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultado = await PedidoService.misPedidos();

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resultado is PedidoExito<List<PedidoApi>>) {
        _pedidos = resultado.datos;
      } else if (resultado is PedidoError<List<PedidoApi>>) {
        _error = resultado.mensaje;
      }
    });
  }

  Future<void> _cancelar(PedidoApi pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar pedido', style: AppTheme.titulo(size: 18)),
        content: Text(
          '¿Cancelar el pedido #${pedido.id}? Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No',
                style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.terracota,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await PedidoService.cancelarPedido(pedido.id);
    if (!mounted) return;

    if (resultado is PedidoExito<String>) {
      _snack('Pedido #${pedido.id} cancelado');
      _cargarPedidos();
    } else if (resultado is PedidoError<String>) {
      _snack(resultado.mensaje, esError: true);
    }
  }

  void _snack(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: esError ? AppColors.terracota : AppColors.oliva,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activos = _pedidos
        .where((p) =>
            p.estado != EstadoPedidoApi.entregado &&
            p.estado != EstadoPedidoApi.cancelado)
        .toList();
    final historicos = _pedidos
        .where((p) =>
            p.estado == EstadoPedidoApi.entregado ||
            p.estado == EstadoPedidoApi.cancelado)
        .toList();

    final totalGastado = _pedidos
        .where((p) => p.estado == EstadoPedidoApi.entregado)
        .fold<double>(0, (s, p) => s + p.total);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.terracota,
          onRefresh: _cargarPedidos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
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
                    IconButton(
                      onPressed: _cargarPedidos,
                      icon: const Icon(Icons.refresh,
                          color: AppColors.terracota),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Cargando ──
                if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.terracota),
                    ),
                  )
                else if (_error != null)
                  _ErrorWidget(
                      mensaje: _error!, onReintentar: _cargarPedidos)
                else ...[
                  // ── Resumen rápido ──
                  Row(
                    children: [
                      Expanded(
                        child: _TarjetaResumen(
                          icono: Icons.local_fire_department_outlined,
                          etiqueta: AppStrings.t(context, 'en_preparacion'),
                          valor: activos.length.toString(),
                          color: AppColors.terracota,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TarjetaResumen(
                          icono: Icons.receipt_long_outlined,
                          etiqueta: AppStrings.t(context, 'total_hoy'),
                          valor: totalGastado == 0
                              ? '\$0'
                              : '\$${(totalGastado / 1000).toStringAsFixed(0)}K',
                          color: AppColors.oliva,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Pedidos activos ──
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
                        Text('${activos.length} pedidos',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...activos.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TarjetaPedido(
                            pedido: p,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetallePedidoScreen(pedido: p),
                              ),
                            ).then((_) => _cargarPedidos()),
                            onCancelar:
                                p.estado == EstadoPedidoApi.pendiente
                                    ? () => _cancelar(p)
                                    : null,
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // ── Historial ──
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
                            child: _TarjetaPedido(
                              pedido: p,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetallePedidoScreen(pedido: p),
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],

                  // ── Estado vacío ──
                  if (_pedidos.isEmpty)
                    _EstadoVacio(onIrAInicio: widget.onIrAInicio),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TARJETA DE PEDIDO
// ─────────────────────────────────────────────────────────────

class _TarjetaPedido extends StatelessWidget {
  final PedidoApi pedido;
  final VoidCallback? onTap;
  final VoidCallback? onCancelar;

  const _TarjetaPedido({
    required this.pedido,
    this.onTap,
    this.onCancelar,
  });

  Color get _colorEstado {
    if (pedido.estado == EstadoPedidoApi.pendiente) return AppColors.cafeMedio;
    if (pedido.estado == EstadoPedidoApi.en_preparacion) return AppColors.oliva;
    if (pedido.estado == EstadoPedidoApi.listo) return AppColors.terracota;
    if (pedido.estado == EstadoPedidoApi.entregado) return AppColors.exitoTexto;
    return AppColors.cafeMedio; // cancelado
  }

  @override
  Widget build(BuildContext context) {
    final cantItems = pedido.items.fold(0, (s, i) => s + i.cantidad);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Número de pedido
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colorEstado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${pedido.id}',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _colorEstado),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${pedido.mesaId} · $cantItems ${cantItems == 1 ? 'producto' : 'productos'}',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colorEstado.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pedido.estado.etiqueta,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _colorEstado),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '· ${pedido.horaFormateada}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pedido.totalFormateado,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracota),
                    ),
                    if (onCancelar != null)
                      GestureDetector(
                        onTap: onCancelar,
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.terracota,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (pedido.estado != EstadoPedidoApi.entregado &&
                pedido.estado != EstadoPedidoApi.cancelado) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pedido.estado.progreso,
                  minHeight: 3,
                  backgroundColor: AppColors.cremaOscura,
                  valueColor: AlwaysStoppedAnimation(_colorEstado),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta resumen ──
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
                color: AppColors.cafeOscuro),
          ),
          Text(
            etiqueta,
            style: GoogleFonts.inter(
                fontSize: 9.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeMedio),
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ──
class _EstadoVacio extends StatelessWidget {
  final VoidCallback? onIrAInicio;
  const _EstadoVacio({this.onIrAInicio});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.restaurant_menu_outlined,
                color: AppColors.terracota, size: 36),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.t(context, 'sin_pedidos'),
              style: AppTheme.titulo(size: 18)),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, 'sin_pedidos_msg'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.cafeMedio, height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onIrAInicio,
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppStrings.t(context, 'explorar_menu')),
          ),
        ],
      ),
    );
  }
}

// ── Error ──
class _ErrorWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorWidget({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.cafeMedio, size: 36),
          const SizedBox(height: 12),
          Text(mensaje,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.terracota),
          ),
        ],
      ),
    );
  }
}