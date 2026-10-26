import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/menu_service.dart';
import '../services/pedido_service.dart';
import '../services/restaurantes_service.dart';
import '../widgets/boton_favorito.dart';
import 'carrito_screen.dart';

/// Agrega un plato al carrito. Cada pedido es de un solo restaurante: si el carrito ya tiene
/// platos de otro, pregunta si se vacía para empezar uno nuevo. Devuelve true si el plato quedó agregado.
Future<bool> agregarAlCarrito(BuildContext context, Producto producto) async {
  final carrito = Carrito();
  if (carrito.aceptaProducto(producto)) {
    carrito.agregar(producto);
    return true;
  }
  final cambiar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Cambiar de restaurante?'),
      content: Text(
        'Tu carrito tiene platos de ${carrito.restauranteNombre ?? 'otro restaurante'}. '
        'Cada pedido es de un solo restaurante.\n\n'
        '¿Vaciar el carrito y empezar uno nuevo en ${producto.restauranteNombre ?? 'este restaurante'}?',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vaciar y cambiar')),
      ],
    ),
  );
  if (cambiar == true) {
    carrito.limpiar();
    carrito.agregar(producto);
    return true;
  }
  return false;
}

/// Menú completo de un restaurante, clasificado por tipo de comida.
class MenuScreen extends StatefulWidget {
  final RestauranteApi restaurante;
  const MenuScreen({super.key, required this.restaurante});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _orden = [
    'Entradas',
    'Hamburguesas',
    'Perros calientes',
    'Principales',
    'Combos',
    'Acompañantes',
    'Postres',
    'Bebidas',
  ];

  final _busquedaCtrl = TextEditingController();
  List<Producto> _productos = [];
  bool _cargando = true;
  String _categoria = 'Todos';
  String _q = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final p = await MenuService.obtenerMenu(restauranteId: widget.restaurante.id);
    if (!mounted) return;
    setState(() {
      _productos = p;
      _cargando = false;
    });
  }

  static int _peso(String c) {
    final i = _orden.indexWhere((o) => o.toLowerCase() == c.toLowerCase());
    return i < 0 ? _orden.length : i;
  }

  String _catDe(Producto p) => p.categoria ?? 'Otros';

  List<String> get _categorias {
    final set = _productos.map(_catDe).toSet().toList();
    set.sort((a, b) {
      final d = _peso(a) - _peso(b);
      return d != 0 ? d : a.compareTo(b);
    });
    return set;
  }

  List<Producto> get _filtrados {
    final q = _q.trim().toLowerCase();
    return _productos.where((p) {
      if (_categoria != 'Todos' && _catDe(p) != _categoria) return false;
      if (q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(q) ||
          (p.descripcion?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _abrirDetalle(Producto p) {
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
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                  child: Text(p.emoji, style: const TextStyle(fontSize: 70))),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text(p.nombre, style: AppTheme.titulo(size: 22))),
                BotonFavorito(productoId: p.id),
              ],
            ),
            const SizedBox(height: 2),
            Text('${widget.restaurante.emoji} ${widget.restaurante.nombre} · ${_catDe(p)}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.cafeMedio)),
            if ((p.descripcion ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(p.descripcion!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.cafeMedio, height: 1.5)),
            ],
            const SizedBox(height: 10),
            Text(p.precioFormateado,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracota)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await agregarAlCarrito(context, p);
              },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('AGREGAR AL CARRITO'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurante;
    final filtrados = _filtrados;
    final cats = _categorias;

    // Platos agrupados por tipo de comida, en el orden definido.
    final secciones = <Widget>[];
    for (final cat in cats) {
      final delaCat = filtrados.where((p) => _catDe(p) == cat).toList();
      if (delaCat.isEmpty) continue;
      secciones.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: Row(
          children: [
            Text(Producto.emojiCategoria(cat),
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(cat, style: AppTheme.titulo(size: 18)),
            const SizedBox(width: 8),
            Text('(${delaCat.length})',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.cafeMedio)),
          ],
        ),
      ));
      for (final p in delaCat) {
        secciones.add(_FilaPlato(
          producto: p,
          onTap: () => _abrirDetalle(p),
          onAgregar: () => agregarAlCarrito(context, p),
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.cafeOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${r.emoji} ${r.nombre}', style: AppTheme.titulo(size: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((r.tipoCocina ?? '').isNotEmpty)
                  Text(r.tipoCocina!.toUpperCase(), style: AppTheme.etiqueta()),
                if ((r.descripcion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.descripcion!,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.cafeMedio,
                          height: 1.4)),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _busquedaCtrl,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar en el menú de ${r.nombre}...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.cafeMedio, size: 20),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _busquedaCtrl.clear();
                              setState(() => _q = '');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (cats.length > 1)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final nombre = i == 0 ? 'Todos' : cats[i - 1];
                  final emoji =
                      i == 0 ? '🍽️' : Producto.emojiCategoria(cats[i - 1]);
                  final sel = _categoria == nombre;
                  return GestureDetector(
                    onTap: () => setState(() => _categoria = nombre),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.terracota : AppColors.superficie,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppColors.terracota : AppColors.borde),
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(nombre,
                              style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? AppColors.crema
                                      : AppColors.cafeOscuro)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.terracota))
                : RefreshIndicator(
                    color: AppColors.terracota,
                    onRefresh: _cargar,
                    child: ListenableBuilder(
                      listenable: Carrito(),
                      builder: (context, _) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: filtrados.isEmpty
                            ? [
                                const SizedBox(height: 60),
                                Center(
                                  child: Text(
                                    _productos.isEmpty
                                        ? 'Este restaurante aún no tiene platos disponibles'
                                        : 'Sin resultados',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.cafeMedio),
                                  ),
                                ),
                              ]
                            : secciones,
                      ),
                    ),
                  ),
          ),
          // ── Barra del carrito ──
          ListenableBuilder(
            listenable: Carrito(),
            builder: (context, _) {
              final c = Carrito();
              if (c.estaVacio) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              '${c.totalItems} ${c.totalItems == 1 ? 'plato' : 'platos'} · ${c.restauranteNombre ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.cafeMedio)),
                          Text(c.totalFormateado,
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracota)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CarritoScreen()),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text('VER CARRITO'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilaPlato extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  final Future<bool> Function() onAgregar;

  const _FilaPlato({
    required this.producto,
    required this.onTap,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final carrito = Carrito();
    return ListenableBuilder(
      listenable: carrito,
      builder: (context, _) => _contenido(carrito),
    );
  }

  Widget _contenido(Carrito carrito) {
    final cant = carrito.cantidadDe(producto.id);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cant > 0
                  ? AppColors.terracota.withValues(alpha: 0.5)
                  : AppColors.borde),
        ),
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
                  child: Text(producto.emoji,
                      style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre,
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                  if ((producto.descripcion ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(producto.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cafeMedio,
                            height: 1.3)),
                  ],
                  const SizedBox(height: 4),
                  Text(producto.precioFormateado,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracota)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            cant == 0
                ? _BotonRedondo(icono: Icons.add, relleno: true, onTap: onAgregar)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BotonRedondo(
                          icono: cant == 1 ? Icons.delete_outline : Icons.remove,
                          onTap: () async => carrito.decrementar(producto.id)),
                      SizedBox(
                        width: 26,
                        child: Center(
                          child: Text('$cant',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cafeOscuro)),
                        ),
                      ),
                      _BotonRedondo(
                          icono: Icons.add,
                          relleno: true,
                          onTap: () async => carrito.agregar(producto)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  final IconData icono;
  final bool relleno;
  final Future<dynamic> Function() onTap;

  const _BotonRedondo({
    required this.icono,
    required this.onTap,
    this.relleno = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: relleno
              ? AppColors.terracota
              : AppColors.terracota.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono,
            size: 18, color: relleno ? AppColors.crema : AppColors.terracota),
      ),
    );
  }
}
