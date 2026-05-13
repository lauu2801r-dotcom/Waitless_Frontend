import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/menu_service.dart';
import '../services/pedido_service.dart';
import 'carrito_screen.dart';

class _ItemBorrador {
  final Producto producto;
  int cantidad;
  String? notas;
  _ItemBorrador({required this.producto, this.cantidad = 1, this.notas});
  double get subtotal => producto.precio * cantidad;
}

enum TipoEntrega { restaurante, domicilio }

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});

  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  List<Producto> _productos = [];
  bool _cargando = true;
  int _tabActivo = 0;

  final List<_ItemBorrador> _borrador = [];
  TipoEntrega _tipoEntrega = TipoEntrega.restaurante;
  String _direccion = '';
  bool _editandoDireccion = false;

  String _categoriaActiva = 'Todos';
  String _busqueda = '';
  final TextEditingController _busquedaCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  final List<Map<String, String>> _categorias = [
    {'nombre': 'Todos', 'emoji': '🍽️'},
    {'nombre': 'Entradas', 'emoji': '🥗'},
    {'nombre': 'Principales', 'emoji': '🍝'},
    {'nombre': 'Postres', 'emoji': '🍰'},
    {'nombre': 'Bebidas', 'emoji': '🍹'},
  ];

  int get _totalItems => _borrador.fold(0, (s, i) => s + i.cantidad);
  double get _totalPrecio => _borrador.fold(0.0, (s, i) => s + i.subtotal);
  bool get _borradorVacio => _borrador.isEmpty;

  String get _totalFormateado {
    final t = _totalPrecio.toInt();
    return '\$${t.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  List<Producto> get _productosFiltrados {
    var lista = _productos;
    if (_categoriaActiva != 'Todos') {
      lista = lista.where((p) => p.categoria == _categoriaActiva).toList();
    }
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista.where((p) =>
          p.nombre.toLowerCase().contains(q) ||
          (p.categoria?.toLowerCase().contains(q) ?? false)).toList();
    }
    return lista;
  }

  @override
  void initState() {
    super.initState();
    _cargarMenu();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMenu() async {
    setState(() => _cargando = true);
    final productos = await MenuService.obtenerMenu();
    if (mounted) {
      setState(() {
        _productos = productos;
        _cargando = false;
      });
    }
  }

  void _agregarProducto(Producto p) {
    setState(() {
      final idx = _borrador.indexWhere((i) => i.producto.id == p.id);
      if (idx >= 0) {
        _borrador[idx].cantidad++;
      } else {
        _borrador.add(_ItemBorrador(producto: p));
      }
    });
    _snack('${p.nombre} agregado 🛒');
  }

  void _actualizarCantidad(int productoId, int nuevaCantidad) {
    setState(() {
      final idx = _borrador.indexWhere((i) => i.producto.id == productoId);
      if (idx < 0) return;
      if (nuevaCantidad <= 0) {
        _borrador.removeAt(idx);
      } else {
        _borrador[idx].cantidad = nuevaCantidad;
      }
    });
  }

  void _eliminarItem(int productoId) {
    final idx = _borrador.indexWhere((i) => i.producto.id == productoId);
    if (idx < 0) return;
    final nombre = _borrador[idx].producto.nombre;
    setState(() => _borrador.removeAt(idx));
    _snack('$nombre eliminado del pedido');
  }

  void _editarNotas(int productoId) {
    final idx = _borrador.indexWhere((i) => i.producto.id == productoId);
    if (idx < 0) return;
    final notasCtrl = TextEditingController(text: _borrador[idx].notas ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.crema,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notas para ${_borrador[idx].producto.nombre}',
                  style: AppTheme.titulo(size: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: notasCtrl,
                maxLines: 3,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeOscuro),
                decoration: const InputDecoration(hintText: 'Sin cebolla, punto medio...'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _borrador[idx].notas = notasCtrl.text.trim().isEmpty
                        ? null
                        : notasCtrl.text.trim();
                  });
                  Navigator.pop(context);
                  _snack('Notas guardadas ✏️');
                },
                child: const Text('GUARDAR NOTAS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _limpiarBorrador() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Limpiar pedido', style: AppTheme.titulo(size: 18)),
        content: Text('¿Eliminar todos los productos del borrador?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _borrador.clear());
              Navigator.pop(ctx);
              _snack('Pedido limpiado 🗑️');
            },
            child: Text('Limpiar',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _enviarAlCarrito() {
    if (_borradorVacio) {
      _snack('Agrega al menos un producto', esError: true);
      return;
    }
    final carrito = Carrito();
    carrito.limpiar();
    for (final item in _borrador) {
      carrito.agregar(item.producto, cantidad: item.cantidad);
    }
    final tipoApi = _tipoEntrega == TipoEntrega.domicilio
        ? TipoEntregaApi.domicilio
        : TipoEntregaApi.restaurante;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarritoScreen(
          tipoEntrega: tipoApi,
          direccionDomicilio: _tipoEntrega == TipoEntrega.domicilio ? _direccion : null,
        ),
      ),
    ).then((_) {
      if (Carrito().estaVacio) {
        setState(() => _borrador.clear());
        _snack('¡Pedido confirmado! 🎉');
      }
    });
  }

  void _snack(String msg, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
      backgroundColor: esError ? AppColors.terracota : AppColors.cafeOscuro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  int _cantidadEnBorrador(int productoId) {
    final idx = _borrador.indexWhere((i) => i.producto.id == productoId);
    return idx >= 0 ? _borrador[idx].cantidad : 0;
  }

  String _fmt(double precio) {
    final t = precio.toInt();
    return '\$${t.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cafeOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Crea tu Pedido', style: AppTheme.titulo(size: 20)),
        actions: [
          if (!_borradorVacio)
            TextButton.icon(
              onPressed: _limpiarBorrador,
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.terracota),
              label: Text('Limpiar',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.terracota)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Tabs manuales
          Row(
            children: [
              _TabBtn(
                label: 'ELEGIR PRODUCTOS',
                activo: _tabActivo == 0,
                onTap: () => setState(() => _tabActivo = 0),
              ),
              _TabBtn(
                label: 'MI PEDIDO',
                badge: _totalItems > 0 ? '$_totalItems' : null,
                activo: _tabActivo == 1,
                onTap: () => setState(() => _tabActivo = 1),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.borde),
          // ── Contenido con IndexedStack
          Expanded(
            child: IndexedStack(
              index: _tabActivo,
              children: [
                _buildTabProductos(),
                _buildTabMiPedido(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            boxShadow: [
              BoxShadow(
                color: AppColors.cafeOscuro.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: _borradorVacio
              ? Center(
                  child: Text(
                    _cargando ? 'Cargando menú...' : 'Agrega productos del menú para comenzar',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
                  ),
                )
              : Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_totalItems productos', style: AppTheme.etiqueta()),
                        Text(_totalFormateado,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracota,
                            )),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _enviarAlCarrito,
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: const Text('ENVIAR AL CARRITO'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabProductos() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.terracota, strokeWidth: 2),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            controller: _busquedaCtrl,
            onChanged: (v) => setState(() => _busqueda = v),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeOscuro),
            decoration: InputDecoration(
              hintText: 'Buscar plato...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
              prefixIcon: const Icon(Icons.search, color: AppColors.cafeMedio, size: 20),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.cafeMedio, size: 18),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        setState(() => _busqueda = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categorias[i];
              final activa = _categoriaActiva == cat['nombre'];
              return GestureDetector(
                onTap: () => setState(() => _categoriaActiva = cat['nombre']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: activa ? AppColors.terracota : AppColors.superficie,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: activa ? AppColors.terracota : AppColors.borde),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(cat['nombre']!,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activa ? AppColors.crema : AppColors.cafeOscuro)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.borde),
        Expanded(
          child: _productosFiltrados.isEmpty
              ? Center(
                  child: Text('Sin resultados',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.cafeMedio)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: _productosFiltrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = _productosFiltrados[i];
                    final cantidad = _cantidadEnBorrador(p.id);
                    return _TarjetaProducto(
                      producto: p,
                      cantidad: cantidad,
                      onAgregar: () => _agregarProducto(p),
                      onIncrementar: () => _actualizarCantidad(p.id, cantidad + 1),
                      onDecrementar: () => _actualizarCantidad(p.id, cantidad - 1),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabMiPedido() {
    if (_borrador.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.terracota, size: 38),
              ),
              const SizedBox(height: 20),
              Text('Tu pedido está vacío', style: AppTheme.titulo(size: 20)),
              const SizedBox(height: 8),
              Text(
                'Ve a "Elegir Productos" y agrega lo que quieras',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.cafeMedio, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CÓMO QUIERES RECIBIRLO', style: AppTheme.etiqueta()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BotonTipoEntrega(
                  icono: Icons.table_restaurant_outlined,
                  titulo: 'En el restaurante',
                  subtitulo: 'Escoge tu mesa',
                  seleccionado: _tipoEntrega == TipoEntrega.restaurante,
                  color: AppColors.terracota,
                  onTap: () => setState(() => _tipoEntrega = TipoEntrega.restaurante),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BotonTipoEntrega(
                  icono: Icons.delivery_dining_outlined,
                  titulo: 'A domicilio',
                  subtitulo: '30–45 min',
                  seleccionado: _tipoEntrega == TipoEntrega.domicilio,
                  color: AppColors.oliva,
                  onTap: () => setState(() => _tipoEntrega = TipoEntrega.domicilio),
                ),
              ),
            ],
          ),
          if (_tipoEntrega == TipoEntrega.domicilio) ...[
            const SizedBox(height: 16),
            Text('DIRECCIÓN DE ENTREGA', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _editandoDireccion
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: GestureDetector(
                onTap: () => setState(() => _editandoDireccion = true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.terracota, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _direccion.isEmpty ? 'Toca para ingresar tu dirección' : _direccion,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _direccion.isEmpty ? AppColors.cafeMedio : AppColors.cafeOscuro,
                          ),
                        ),
                      ),
                      Text('Editar',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.terracota,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              secondChild: Column(
                children: [
                  TextField(
                    controller: _direccionCtrl,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeOscuro),
                    decoration: const InputDecoration(
                      hintText: 'Ej: Cra. 15 #100-20, Apto 301',
                      prefixIcon: Icon(Icons.edit_location_alt_outlined,
                          color: AppColors.terracota, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _direccion = _direccionCtrl.text.trim();
                          _editandoDireccion = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('GUARDAR DIRECCIÓN'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRODUCTOS SELECCIONADOS', style: AppTheme.etiqueta()),
              Text('${_borrador.fold(0, (s, i) => s + i.cantidad)} ítems',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio)),
            ],
          ),
          const SizedBox(height: 12),
          ..._borrador.map((item) => _ItemBorradorWidget(
                item: item,
                onIncrementar: () => _actualizarCantidad(item.producto.id, item.cantidad + 1),
                onDecrementar: () => _actualizarCantidad(item.producto.id, item.cantidad - 1),
                onEliminar: () => _eliminarItem(item.producto.id),
                onEditarNotas: () => _editarNotas(item.producto.id),
                subtotalFormateado: _fmt(item.subtotal),
              )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            child: Column(
              children: [
                _FilaTotal(
                  label: 'Subtotal',
                  valor: _fmt(_borrador.fold(0.0, (s, i) => s + i.subtotal)),
                  esNegrita: false,
                ),
                if (_tipoEntrega == TipoEntrega.domicilio) ...[
                  const SizedBox(height: 8),
                  const _FilaTotal(label: 'Domicilio', valor: '\$5.000', esNegrita: false),
                ],
                const SizedBox(height: 8),
                const Divider(color: AppColors.borde),
                const SizedBox(height: 8),
                _FilaTotal(
                  label: 'TOTAL',
                  valor: _fmt(
                    _borrador.fold(0.0, (s, i) => s + i.subtotal) +
                        (_tipoEntrega == TipoEntrega.domicilio ? 5000.0 : 0.0),
                  ),
                  esNegrita: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.infoTexto, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Al confirmar tu pedido, el panel Momento se actualizará con el tiempo estimado de espera.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.infoTexto, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab button manual
class _TabBtn extends StatelessWidget {
  final String label;
  final String? badge;
  final bool activo;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.activo, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.crema,
            border: Border(
              bottom: BorderSide(
                color: activo ? AppColors.terracota : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activo ? AppColors.terracota : AppColors.cafeMedio,
                  )),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.terracota,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.crema)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta producto
class _TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final VoidCallback onAgregar;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  const _TarjetaProducto({
    required this.producto,
    required this.cantidad,
    required this.onAgregar,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  @override
  Widget build(BuildContext context) {
    final enBorrador = cantidad > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enBorrador
            ? AppColors.terracota.withValues(alpha: 0.05)
            : AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enBorrador ? AppColors.terracota : AppColors.borde,
          width: enBorrador ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(producto.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                if (producto.descripcion != null) ...[
                  const SizedBox(height: 3),
                  Text(producto.descripcion!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio)),
                ],
                const SizedBox(height: 6),
                Text(producto.precioFormateado,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracota)),
              ],
            ),
          ),
          if (enBorrador)
            Row(
              children: [
                _BtnCantidad(
                  icono: cantidad == 1 ? Icons.delete_outline : Icons.remove,
                  color: cantidad == 1 ? AppColors.terracota : AppColors.cafeMedio,
                  onTap: onDecrementar,
                ),
                SizedBox(
                  width: 28,
                  child: Center(
                      child: Text('$cantidad',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro))),
                ),
                _BtnCantidad(icono: Icons.add, color: AppColors.oliva, onTap: onIncrementar),
              ],
            )
          else
            GestureDetector(
              onTap: onAgregar,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.terracota,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: AppColors.crema, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item borrador
class _ItemBorradorWidget extends StatelessWidget {
  final _ItemBorrador item;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEliminar;
  final VoidCallback onEditarNotas;
  final String subtotalFormateado;

  const _ItemBorradorWidget({
    required this.item,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEliminar,
    required this.onEditarNotas,
    required this.subtotalFormateado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(item.producto.emoji,
                          style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.producto.nombre,
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                      const SizedBox(height: 2),
                      Text(subtotalFormateado,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracota)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _BtnCantidad(
                      icono: item.cantidad == 1 ? Icons.delete_outline : Icons.remove,
                      color: item.cantidad == 1 ? AppColors.terracota : AppColors.cafeMedio,
                      onTap: onDecrementar,
                    ),
                    SizedBox(
                      width: 28,
                      child: Center(
                          child: Text('${item.cantidad}',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cafeOscuro))),
                    ),
                    _BtnCantidad(icono: Icons.add, color: AppColors.oliva, onTap: onIncrementar),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onEditarNotas,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: item.notas != null ? AppColors.alertaFondo : AppColors.cremaOscura,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.notas != null
                                ? Icons.sticky_note_2_outlined
                                : Icons.add_comment_outlined,
                            size: 14,
                            color: item.notas != null ? AppColors.alertaTexto : AppColors.cafeMedio,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.notas ?? 'Agregar notas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: item.notas != null
                                    ? AppColors.alertaTexto
                                    : AppColors.cafeMedio,
                                fontStyle: item.notas == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEliminar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.terracota.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, size: 16, color: AppColors.terracota),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón tipo entrega
class _BotonTipoEntrega extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool seleccionado;
  final Color color;
  final VoidCallback onTap;

  const _BotonTipoEntrega({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.seleccionado,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado ? color.withValues(alpha: 0.08) : AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: seleccionado ? color : AppColors.borde,
              width: seleccionado ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: seleccionado ? color : AppColors.cafeOscuro)),
            const SizedBox(height: 2),
            Text(subtitulo,
                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.cafeMedio)),
            if (seleccionado) ...[
              const SizedBox(height: 6),
              Icon(Icons.check_circle_rounded, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Fila total
class _FilaTotal extends StatelessWidget {
  final String label;
  final String valor;
  final bool esNegrita;

  const _FilaTotal({required this.label, required this.valor, required this.esNegrita});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: esNegrita
                ? AppTheme.etiqueta(size: 12)
                : GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
        Text(valor,
            style: esNegrita
                ? GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.terracota)
                : GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
      ],
    );
  }
}

// ── Botón cantidad
class _BtnCantidad extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BtnCantidad({required this.icono, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, size: 16, color: color),
      ),
    );
  }
}