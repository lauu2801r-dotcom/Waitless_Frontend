import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/pedido_service.dart';
import '../../theme/app_theme.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  String _filtro = 'Todos';
  List<PedidoApi> _pedidos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() { _cargando = true; _error = null; });
    final resultado = await PedidoService.todosPedidos();
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

  Future<void> _avanzarEstado(PedidoApi pedido) async {
    // Flujo de estados del backend
    final flujo = [
      EstadoPedidoApi.pendiente,
      EstadoPedidoApi.en_preparacion,
      EstadoPedidoApi.listo,
      EstadoPedidoApi.entregado,
    ];

    final actual = flujo.indexOf(pedido.estado);
    if (actual < 0 || actual >= flujo.length - 1) return;
    final nuevoEstado = flujo[actual + 1];

    final resultado = await PedidoService.actualizarEstado(
      pedidoId: pedido.id,
      nuevoEstado: nuevoEstado,
    );

    if (!mounted) return;

    if (resultado is PedidoExito<PedidoApi>) {
      final idx = _pedidos.indexWhere((p) => p.id == pedido.id);
      if (idx >= 0) {
        setState(() => _pedidos[idx] = resultado.datos);
      }
      _snack('Pedido #${pedido.id} → ${nuevoEstado.etiqueta}');
    } else if (resultado is PedidoError<PedidoApi>) {
      _snack(resultado.mensaje, esError: true);
    }
  }

  Future<void> _cancelarPedido(PedidoApi pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar pedido #${pedido.id}',
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('¿Estás seguro? Esta acción no se puede deshacer.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await PedidoService.actualizarEstado(
      pedidoId: pedido.id,
      nuevoEstado: EstadoPedidoApi.cancelado,
    );

    if (!mounted) return;

    if (resultado is PedidoExito<PedidoApi>) {
      setState(() {
        final idx = _pedidos.indexWhere((p) => p.id == pedido.id);
        if (idx >= 0) _pedidos[idx] = resultado.datos;
      });
      _snack('Pedido #${pedido.id} cancelado');
    } else if (resultado is PedidoError<PedidoApi>) {
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

  List<PedidoApi> get _pedidosFiltrados {
    switch (_filtro) {
      case 'En cocina':
        return _pedidos.where((p) =>
            p.estado == EstadoPedidoApi.pendiente ||
            p.estado == EstadoPedidoApi.en_preparacion).toList();
      case 'Listos':
        return _pedidos.where((p) =>
            p.estado == EstadoPedidoApi.listo).toList();
      case 'Entregados':
        return _pedidos.where((p) =>
            p.estado == EstadoPedidoApi.entregado).toList();
      default:
        return _pedidos
            .where((p) => p.estado != EstadoPedidoApi.cancelado)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pedidos',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 30, fontWeight: FontWeight.w600,
                                  color: AppColors.cafeOscuro)),
                          const SizedBox(height: 4),
                          Text('GESTIONA TUS PEDIDOS DEL DÍA',
                              style: GoogleFonts.inter(
                                  fontSize: 11, letterSpacing: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cafeMedio)),
                        ],
                      ),
                      IconButton(
                        onPressed: _cargarPedidos,
                        icon: const Icon(Icons.refresh, color: AppColors.terracota),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Filtros
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ChipFiltro(
                          label: 'Todos',
                          activo: _filtro == 'Todos',
                          onTap: () => setState(() => _filtro = 'Todos'),
                          contador: _pedidos
                              .where((p) => p.estado != EstadoPedidoApi.cancelado)
                              .length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'En cocina',
                          activo: _filtro == 'En cocina',
                          onTap: () => setState(() => _filtro = 'En cocina'),
                          contador: _pedidos.where((p) =>
                              p.estado == EstadoPedidoApi.pendiente ||
                              p.estado == EstadoPedidoApi.en_preparacion).length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'Listos',
                          activo: _filtro == 'Listos',
                          onTap: () => setState(() => _filtro = 'Listos'),
                          contador: _pedidos
                              .where((p) => p.estado == EstadoPedidoApi.listo)
                              .length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'Entregados',
                          activo: _filtro == 'Entregados',
                          onTap: () => setState(() => _filtro = 'Entregados'),
                          contador: _pedidos
                              .where((p) => p.estado == EstadoPedidoApi.entregado)
                              .length,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.terracota))
                  : _error != null
                      ? _ErrorWidget(mensaje: _error!, onReintentar: _cargarPedidos)
                      : _pedidosFiltrados.isEmpty
                          ? _EstadoVacio(filtro: _filtro)
                          : RefreshIndicator(
                              color: AppColors.terracota,
                              onRefresh: _cargarPedidos,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: _pedidosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final pedido = _pedidosFiltrados[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _TarjetaPedidoAdmin(
                                      pedido: pedido,
                                      onAvanzar: pedido.estado != EstadoPedidoApi.entregado
                                          ? () => _avanzarEstado(pedido)
                                          : null,
                                      onCancelar: pedido.estado == EstadoPedidoApi.pendiente
                                          ? () => _cancelarPedido(pedido)
                                          : null,
                                    ),
                                  );
                                },
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
// TARJETA PEDIDO ADMIN
// ─────────────────────────────────────────────────────────────
class _TarjetaPedidoAdmin extends StatelessWidget {
  final PedidoApi pedido;
  final VoidCallback? onAvanzar;
  final VoidCallback? onCancelar;

  const _TarjetaPedidoAdmin({
    required this.pedido,
    this.onAvanzar,
    this.onCancelar,
  });

  Color get _colorEstado {
    switch (pedido.estado) {
      case EstadoPedidoApi.pendiente:      return AppColors.cafeMedio;
      case EstadoPedidoApi.en_preparacion: return AppColors.terracota;
      case EstadoPedidoApi.listo:          return AppColors.oliva;
      case EstadoPedidoApi.entregado:      return AppColors.exitoTexto;
      case EstadoPedidoApi.cancelado:      return AppColors.cafeMedio;
    }
  }

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final esEntregado = pedido.estado == EstadoPedidoApi.entregado;
    final cantItems = pedido.items.fold(0, (s, i) => s + i.cantidad);

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
          Row(
            children: [
              // Barra lateral de color
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _colorEstado,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('PEDIDO #${pedido.id}',
                            style: GoogleFonts.inter(
                                fontSize: 10, letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cafeMedio)),
                        const SizedBox(width: 8),
                        Text('· ${pedido.horaFormateada}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.cafeMedio)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cantItems ${cantItems == 1 ? 'producto' : 'productos'}',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant_outlined,
                            size: 12, color: AppColors.cafeMedio),
                        const SizedBox(width: 4),
                        Text('Mesa ${pedido.mesaId}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.cafeMedio)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _colorEstado.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido.estado.etiqueta,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _colorEstado),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('\$${_fmt(pedido.total)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                ],
              ),
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
                valueColor: AlwaysStoppedAnimation(_colorEstado),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onAvanzar != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAvanzar,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Avanzar estado'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.oliva,
                        side: const BorderSide(color: AppColors.oliva),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (onCancelar != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onCancelar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracota,
                      side: const BorderSide(color: AppColors.terracota),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIPS DE FILTRO
// ─────────────────────────────────────────────────────────────
class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final int contador;

  const _ChipFiltro({
    required this.label,
    required this.activo,
    required this.onTap,
    required this.contador,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo ? AppColors.terracota : AppColors.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: activo ? AppColors.terracota : AppColors.borde),
          ),
          child: Row(
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: activo ? AppColors.crema : AppColors.cafeOscuro)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? AppColors.crema.withValues(alpha: 0.25)
                      : AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(contador.toString(),
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: activo ? AppColors.crema : AppColors.cafeMedio)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ESTADO VACÍO
// ─────────────────────────────────────────────────────────────
class _EstadoVacio extends StatelessWidget {
  final String filtro;
  const _EstadoVacio({required this.filtro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
                color: AppColors.cremaOscura, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.cafeMedio, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No hay pedidos en "$filtro"',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro)),
          const SizedBox(height: 4),
          Text('Cuando lleguen pedidos, aparecerán aquí',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR
// ─────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorWidget({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.cafeMedio, size: 48),
            const SizedBox(height: 16),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.cafeMedio)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.terracota),
            ),
          ],
        ),
      ),
    );
  }
}