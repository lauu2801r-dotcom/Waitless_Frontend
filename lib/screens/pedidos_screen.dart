import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pedido_service.dart';
import '../services/menu_service.dart';
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
    final resultado = await PedidoService.cancelarPedido(pedido.id);
    if (!mounted) return;
    if (resultado is PedidoExito<String>) {
      _snack('Pedido #${pedido.id} cancelado');
      _cargarPedidos();
    } else if (resultado is PedidoError<String>) {
      _snack(resultado.mensaje, esError: true);
    }
  }

  Future<void> _abrirModalPedido({PedidoApi? pedidoExistente}) async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalPedido(pedidoExistente: pedidoExistente),
    );
    if (resultado == true) _cargarPedidos();
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
                    Row(
                      children: [
                        // ── Botón nuevo pedido ──
                        GestureDetector(
                          onTap: () => _abrirModalPedido(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.terracota,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add,
                                    color: AppColors.crema, size: 16),
                                const SizedBox(width: 4),
                                Text('Nuevo',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.crema)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _cargarPedidos,
                          icon: const Icon(Icons.refresh,
                              color: AppColors.terracota),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.terracota),
                    ),
                  )
                else if (_error != null)
                  _ErrorWidget(mensaje: _error!, onReintentar: _cargarPedidos)
                else ...[
                  // ── Resumen ──
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
                                fontSize: 11, color: AppColors.cafeMedio)),
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
                                      DetallePedidoScreen(pedido: p)),
                            ).then((_) => _cargarPedidos()),
                            onCancelar:
                                p.estado == EstadoPedidoApi.pendiente
                                    ? () => _cancelar(p)
                                    : null,
                            onEditar:
                                p.estado == EstadoPedidoApi.pendiente
                                    ? () => _abrirModalPedido(
                                        pedidoExistente: p)
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
                                        DetallePedidoScreen(pedido: p)),
                              ),
                            ),
                          ),
                        )),
                  ],

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
//  MODAL CREAR / EDITAR PEDIDO
// ─────────────────────────────────────────────────────────────

class _ModalPedido extends StatefulWidget {
  final PedidoApi? pedidoExistente;
  const _ModalPedido({this.pedidoExistente});

  @override
  State<_ModalPedido> createState() => _ModalPedidoState();
}

class _ModalPedidoState extends State<_ModalPedido> {
  final _notasCtrl = TextEditingController();
  final _mesaCtrl = TextEditingController();

  List<Producto> _menu = [];
  final Map<int, int> _cantidades = {}; // productoId → cantidad
  bool _cargandoMenu = true;
  bool _guardando = false;
  String? _errorGuardar;

  bool get _esEdicion => widget.pedidoExistente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _mesaCtrl.text = widget.pedidoExistente!.mesaId.toString();
      _notasCtrl.text = widget.pedidoExistente!.notas ?? '';
      for (final item in widget.pedidoExistente!.items) {
        _cantidades[item.productoId] = item.cantidad;
      }
    }
    _cargarMenu();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    _mesaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMenu() async {
    final productos = await MenuService.obtenerMenu();
    if (!mounted) return;
    setState(() {
      _menu = productos;
      _cargandoMenu = false;
    });
  }

  List<ItemCarrito> get _itemsSeleccionados {
    final lista = <ItemCarrito>[];
    for (final p in _menu) {
      final cant = _cantidades[p.id] ?? 0;
      if (cant > 0) lista.add(ItemCarrito(producto: p, cantidad: cant));
    }
    return lista;
  }

  double get _total => _itemsSeleccionados.fold(0, (s, i) => s + i.subtotal);

  String get _totalFormateado {
    final t = _total.toInt();
    return '\$${t.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _confirmar() async {
    final mesaId = int.tryParse(_mesaCtrl.text.trim());
    if (mesaId == null) {
      setState(() => _errorGuardar = 'Ingresa un número de mesa válido');
      return;
    }
    if (_itemsSeleccionados.isEmpty) {
      setState(() => _errorGuardar = 'Agrega al menos un producto');
      return;
    }

    setState(() {
      _guardando = true;
      _errorGuardar = null;
    });

    PedidoResultado<PedidoApi> resultado;

    if (_esEdicion) {
      resultado = await PedidoService.editarItemsPedido(
        pedidoId: widget.pedidoExistente!.id,
        mesaId: mesaId,
        items: _itemsSeleccionados,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
    } else {
      resultado = await PedidoService.crearPedido(
        mesaId: mesaId,
        items: _itemsSeleccionados,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (resultado is PedidoExito<PedidoApi>) {
      Navigator.pop(context, true);
    } else if (resultado is PedidoError<PedidoApi>) {
      setState(() => _errorGuardar = (resultado as PedidoError<PedidoApi>).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        children: [
          // ── Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borde,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Título ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _esEdicion
                      ? 'Editar pedido #${widget.pedidoExistente!.id}'
                      : 'Nuevo pedido',
                  style: AppTheme.titulo(size: 20),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.cafeMedio),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.borde),

          Expanded(
            child: _cargandoMenu
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.terracota))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    children: [
                      // ── Mesa ──
                      Text('Mesa', style: AppTheme.etiqueta()),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _mesaCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_esEdicion,
                        decoration: InputDecoration(
                          hintText: 'Número de mesa',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.cafeMedio),
                          filled: true,
                          fillColor: AppColors.superficie,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borde),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Productos ──
                      Text('Productos', style: AppTheme.etiqueta()),
                      const SizedBox(height: 10),

                      ..._menu.map((p) => _FilaProducto(
                            producto: p,
                            cantidad: _cantidades[p.id] ?? 0,
                            onIncrementar: () => setState(
                                () => _cantidades[p.id] =
                                    (_cantidades[p.id] ?? 0) + 1),
                            onDecrementar: () => setState(() {
                              final actual = _cantidades[p.id] ?? 0;
                              if (actual <= 1) {
                                _cantidades.remove(p.id);
                              } else {
                                _cantidades[p.id] = actual - 1;
                              }
                            }),
                          )),

                      const SizedBox(height: 20),

                      // ── Notas ──
                      Text('Notas (opcional)', style: AppTheme.etiqueta()),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notasCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ej: sin cebolla, alergia al maní...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.cafeMedio),
                          filled: true,
                          fillColor: AppColors.superficie,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borde),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borde),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),

          // ── Footer con total y botón ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.crema,
              border: Border(top: BorderSide(color: AppColors.borde)),
            ),
            child: Column(
              children: [
                if (_errorGuardar != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.terracota.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorGuardar!,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.terracota),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio,
                                fontWeight: FontWeight.w600)),
                        Text(_totalFormateado,
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cafeOscuro)),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracota,
                          foregroundColor: AppColors.crema,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: AppColors.crema,
                                    strokeWidth: 2),
                              )
                            : Text(
                                _esEdicion ? 'Guardar cambios' : 'Confirmar pedido',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  FILA DE PRODUCTO EN EL MODAL
// ─────────────────────────────────────────────────────────────

class _FilaProducto extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  const _FilaProducto({
    required this.producto,
    required this.cantidad,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cantidad > 0 ? AppColors.terracota : AppColors.borde,
            width: cantidad > 0 ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(producto.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro),
                  ),
                  Text(
                    producto.precioFormateado,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.cafeMedio),
                  ),
                ],
              ),
            ),
            // ── Contador ──
            Row(
              children: [
                if (cantidad > 0) ...[
                  GestureDetector(
                    onTap: onDecrementar,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.terracota.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove,
                          size: 14, color: AppColors.terracota),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$cantidad',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: onIncrementar,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.terracota,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add,
                        size: 14, color: AppColors.crema),
                  ),
                ),
              ],
            ),
          ],
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
  final VoidCallback? onEditar;

  const _TarjetaPedido({
    required this.pedido,
    this.onTap,
    this.onCancelar,
    this.onEditar,
  });

  Color get _colorEstado {
    if (pedido.estado == EstadoPedidoApi.pendiente) return AppColors.cafeMedio;
    if (pedido.estado == EstadoPedidoApi.en_preparacion) return AppColors.oliva;
    if (pedido.estado == EstadoPedidoApi.listo) return AppColors.terracota;
    if (pedido.estado == EstadoPedidoApi.entregado) return AppColors.exitoTexto;
    return AppColors.cafeMedio;
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
                                fontSize: 11, color: AppColors.cafeMedio),
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
                    const SizedBox(height: 4),
                    // ── Botones Editar / Cancelar ──
                    Row(
                      children: [
                        if (onEditar != null) ...[
                          GestureDetector(
                            onTap: onEditar,
                            child: Text(
                              'Editar',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.oliva,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (onCancelar != null)
                            Text(' · ',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.cafeMedio)),
                        ],
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
            style: TextButton.styleFrom(foregroundColor: AppColors.terracota),
          ),
        ],
      ),
    );
  }
}