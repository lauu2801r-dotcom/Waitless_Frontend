import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_controller.dart';
import '../services/pedido_service.dart';
import '../utils/app_strings.dart';
import '../services/menu_service.dart';
import '../services/restaurantes_service.dart';
import 'menu_screen.dart';
import 'reservas_screen.dart';
import '../widgets/boton_favorito.dart';
import '../widgets/notificaciones_sheet.dart';
import '../services/notificaciones_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _categoriaSeleccionada = 'Todos';
  List<RestauranteApi> _restaurantes = [];
  RestauranteApi? _restaurante;
  List<Producto> _productos = [];
  bool _cargandoRest = true;
  bool _cargandoMenu = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  RestauranteApi? _buscar(List<RestauranteApi> lista, int? id) {
    if (id == null) return null;
    for (final r in lista) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargandoRest = true;
      _cargandoMenu = true;
    });
    final lista = await RestaurantesService.listar();
    if (!mounted) return;
    final activos = lista.where((r) => r.activo).toList();
    final elegido = _buscar(activos, _restaurante?.id) ??
        _buscar(activos, Carrito().restauranteId) ??
        (activos.isNotEmpty ? activos.first : null);
    setState(() {
      _restaurantes = activos;
      _restaurante = elegido;
      _cargandoRest = false;
    });
    await _cargarMenu();
  }

  Future<void> _cargarMenu() async {
    final r = _restaurante;
    if (r == null) {
      setState(() {
        _productos = [];
        _cargandoMenu = false;
      });
      return;
    }
    setState(() => _cargandoMenu = true);
    final productos = await MenuService.obtenerMenu(restauranteId: r.id);
    if (!mounted || _restaurante?.id != r.id) return;
    setState(() {
      _productos = productos;
      _cargandoMenu = false;
    });
  }

  void _elegirRestaurante(RestauranteApi r) {
    if (_restaurante?.id == r.id) return;
    setState(() {
      _restaurante = r;
      _categoriaSeleccionada = 'Todos';
      _productos = [];
    });
    _cargarMenu();
  }

  /// Chips de categoría según lo que realmente tiene el restaurante elegido.
  List<Map<String, dynamic>> get _chipsCategorias {
    final vistas = <String>[];
    for (final p in _productos) {
      final c = p.categoria;
      if (c != null && !vistas.contains(c)) vistas.add(c);
    }
    return [
      {'nombre': 'Todos', 'emoji': '🍽️'},
      for (final c in vistas) {'nombre': c, 'emoji': Producto.emojiCategoria(c)},
    ];
  }

  List<Producto> get _productosVisibles => _categoriaSeleccionada == 'Todos'
      ? _productos
      : _productos
          .where((p) => p.categoria == _categoriaSeleccionada)
          .toList();

  void _abrirMenu() {
    final r = _restaurante;
    if (r == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuScreen(restaurante: r)),
    );
  }

  void _abrirHoja({
    required String titulo,
    required Widget contenido,
    double altura = 0.65,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: altura,
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
              Text(titulo, style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                    controller: scroll, child: contenido),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verNotificaciones() => mostrarNotificaciones(context);

  void _abrirBuscador() {
    final ctrl = TextEditingController();
    _abrirHoja(
      titulo: _restaurante == null ? 'Buscar' : 'Buscar en ${_restaurante!.nombre}',
      altura: 0.85,
      contenido: StatefulBuilder(
        builder: (ctx, setS) {
          final q = ctrl.text.toLowerCase();
          final filtrados = q.isEmpty
              ? _productos
              : _productos
                  .where((p) =>
                      p.nombre.toLowerCase().contains(q) ||
                      (p.categoria?.toLowerCase().contains(q) ?? false))
                  .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                onChanged: (_) => setS(() {}),
                decoration: const InputDecoration(
                  hintText: 'Busca un plato o categoría...',
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.cafeMedio, size: 20),
                ),
              ),
              const SizedBox(height: 18),
              Text('RESULTADOS (${filtrados.length})',
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 10),
              ...filtrados.map((p) => _ItemBusqueda(
                    emoji: p.emoji,
                    nombre: p.nombre,
                    detalle: '${p.categoria ?? ''} · ${p.precioFormateado}',
                    onTap: () {
                      Navigator.pop(ctx);
                      _abrirDetallePlato(p);
                    },
                  )),
              if (filtrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Sin resultados para "$q"',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.cafeMedio)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _abrirReservarMesa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReservasScreen()),
    );
  }

  void _abrirPedidoDomicilio() {
    _abrirHoja(
      titulo: 'Pedido a domicilio',
      altura: 0.55,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.olivaFondo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.delivery_dining,
                    color: AppColors.oliva, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tiempo estimado',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.infoTexto,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('30 – 45 minutos',
                          style: AppTheme.titulo(
                              size: 18, color: AppColors.infoTexto)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('ENVIAR A', style: AppTheme.etiqueta()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.terracota, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Casa · Cra. 11 #82-71',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cafeOscuro)),
                ),
                Text('Cambiar',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.terracota,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _abrirMenu();
            },
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('VER MENÚ COMPLETO'),
          ),
        ],
      ),
    );
  }

  void _abrirPromos() {
    _abrirHoja(
      titulo: 'Promociones de hoy',
      altura: 0.7,
      contenido: const Column(
        children: [
          _TarjetaPromo(
            emoji: '🍽️',
            titulo: '20% en platos de temporada',
            descripcion:
                'Aplica en risotto de mariscos, salmón y carpaccio. Hasta hoy 11pm.',
            badge: '20% OFF',
            color: AppColors.terracota,
          ),
          SizedBox(height: 10),
          _TarjetaPromo(
            emoji: '🍷',
            titulo: 'Botella de vino + 15%',
            descripcion: 'Reserva Malbec o Cabernet con cualquier principal.',
            badge: '15% OFF',
            color: AppColors.oliva,
          ),
          SizedBox(height: 10),
          _TarjetaPromo(
            emoji: '👥',
            titulo: 'Trae a un amigo, postres gratis',
            descripcion:
                'Comparte un plato fuerte y los postres son por la casa.',
            badge: '2x1',
            color: AppColors.cafeOscuro,
          ),
        ],
      ),
    );
  }

  void _abrirMenuCompleto() => _abrirMenu();

  void _abrirDetallePlato(Producto producto) {
    _abrirHoja(
      titulo: producto.nombre,
      altura: 0.55,
      contenido: Column(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
                child: Text(producto.emoji,
                    style: const TextStyle(fontSize: 80))),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  producto.restauranteNombre == null
                      ? ''
                      : '${_restaurante?.emoji ?? '🍴'} ${producto.restauranteNombre}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeMedio),
                ),
              ),
              BotonFavorito(productoId: producto.id),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              producto.descripcion ?? '',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              producto.precioFormateado,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracota),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.exitoFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppColors.exitoTexto, size: 18),
                const SizedBox(width: 10),
                Text('Listo en 15-20 minutos',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.exitoTexto,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await agregarAlCarrito(context, producto);
              if (ok && mounted) {
                _toast('${producto.nombre} agregado al carrito 🛒');
              }
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('AGREGAR AL CARRITO'),
          ),
        ],
      ),
    );
  }

  Widget _seccionRestaurantes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '¿Dónde quieres pedir?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_cargandoRest)
          const SizedBox(
            height: 120,
            child: Center(
                child: CircularProgressIndicator(color: AppColors.terracota)),
          )
        else if (_restaurantes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertaFondo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.alertaTexto, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('No pudimos cargar los restaurantes.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.alertaTexto)),
                  ),
                  TextButton(
                    onPressed: _cargarTodo,
                    child: Text('Reintentar',
                        style: GoogleFonts.inter(
                            color: AppColors.terracota,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _restaurantes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final r = _restaurantes[i];
                return _TarjetaRestaurante(
                  restaurante: r,
                  seleccionado: r.id == _restaurante?.id,
                  onTap: () => _elegirRestaurante(r),
                );
              },
            ),
          ),
        if (_restaurante != null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abrirMenu,
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text('MENÚ DE ${_restaurante!.nombre.toUpperCase()}'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombreUsuario =
        auth.usuario?.nombreCompleto.split(' ').first ?? 'Hola';
    final conDatos = auth.usuario?.conDatos ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header saludo ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.t(context, 'hola')} 👋',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.cafeMedio,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nombreUsuario,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: AppColors.terracota.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _verNotificaciones,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: ListenableBuilder(
                            listenable: NotificacionesCenter.instancia,
                            builder: (context, _) => Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.notifications_outlined,
                                    color: AppColors.terracota),
                                if (NotificacionesCenter.instancia.noLeidas > 0)
                                  const Positioned(
                                    top: 10,
                                    right: 12,
                                    child: _PuntoNuevo(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Buscador ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: _abrirBuscador,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: AppColors.cafeMedio, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.t(context, 'buscar_placeholder'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.cafeMedio,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.terracota,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune,
                              color: AppColors.crema, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Restaurantes ──
              _seccionRestaurantes(),
              const SizedBox(height: 24),

              // ── Banner de promo ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: _abrirPromos,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cafeOscuro,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.terracota,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  AppStrings.t(context, 'oferta_hoy'),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.crema,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '20% OFF',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.crema,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'En todos los platos\nde temporada',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.crema
                                      .withValues(alpha: 0.8),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('🍽️',
                            style: TextStyle(fontSize: 60)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Acciones rápidas (reserva, domicilio, promos) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _AccionRapida(
                        icono: Icons.event_seat_outlined,
                        titulo: AppStrings.t(context, 'reservar_mesa'),
                        color: AppColors.terracota,
                        onTap: _abrirReservarMesa,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AccionRapida(
                        icono: Icons.delivery_dining,
                        titulo: AppStrings.t(context, 'pedido_domicilio'),
                        color: AppColors.oliva,
                        onTap: _abrirPedidoDomicilio,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AccionRapida(
                        icono: Icons.local_offer_outlined,
                        titulo: AppStrings.t(context, 'promos_dia'),
                        color: AppColors.cafeMedio,
                        onTap: _abrirPromos,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Categorías ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.t(context, 'categorias'),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _chipsCategorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final cat = _chipsCategorias[index];
                    final selected =
                        _categoriaSeleccionada == cat['nombre'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _categoriaSeleccionada = cat['nombre']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.terracota
                              : AppColors.superficie,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? AppColors.terracota
                                : AppColors.borde,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat['emoji'],
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              cat['nombre'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.crema
                                    : AppColors.cafeOscuro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Destacados ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(context, 'destacados_hoy'),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    InkWell(
                      onTap: _abrirMenuCompleto,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Text(
                          AppStrings.t(context, 'ver_todos'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.terracota,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _cargandoMenu
                    ? const Center(child: CircularProgressIndicator())
                    : _productosVisibles.isEmpty
                        ? Center(
                            child: Text(
                              'Este restaurante aún no tiene platos disponibles',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.cafeMedio),
                            ),
                          )
                        : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _productosVisibles.take(6).length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, index) {
                          final p = _productosVisibles[index];
                          return _TarjetaPlatoDestacado(
                            emoji: p.emoji,
                            nombre: p.nombre,
                            categoria: p.categoria ?? '',
                            precio: p.precioFormateado,
                            rating: '4.8',
                            onTap: () => _abrirDetallePlato(p),
                          );
                        },
                      ),
              ),

              // ── Recomendados (solo si hay datos del usuario) ──
              if (conDatos) ...[
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppStrings.t(context, 'recomendados_ti'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: _productos.skip(4).take(3).map((p) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TarjetaPlatoRecomendado(
                          emoji: p.emoji,
                          nombre: p.nombre,
                          descripcion: p.descripcion ?? '',
                          precio: p.precioFormateado,
                          tiempo: '15 min',
                          onTap: () => _abrirDetallePlato(p),
                          onAdd: () async {
                            final ok = await agregarAlCarrito(context, p);
                            if (ok && mounted) {
                              _toast('${p.nombre} agregado al carrito 🛒');
                            }
                          },
                        ),
                      )
                    ).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDGETS PRIVADOS (idénticos al original)
// ─────────────────────────────────────────────────────────────

class _TarjetaRestaurante extends StatelessWidget {
  final RestauranteApi restaurante;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TarjetaRestaurante({
    required this.restaurante,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurante;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.terracota.withValues(alpha: 0.10)
              : AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? AppColors.terracota : AppColors.borde,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child:
                          Text(r.emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro)),
                      const SizedBox(height: 2),
                      Text(r.tipoCocina ?? 'Restaurante',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.cafeMedio)),
                    ],
                  ),
                ),
                if (seleccionado)
                  const Icon(Icons.check_circle,
                      color: AppColors.terracota, size: 20),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 13, color: AppColors.cafeMedio),
                const SizedBox(width: 4),
                Text('${r.totalPlatos} platos',
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: AppColors.cafeMedio)),
                const SizedBox(width: 12),
                Icon(Icons.event_seat_outlined,
                    size: 13,
                    color: r.mesasLibres > 0
                        ? AppColors.oliva
                        : AppColors.terracota),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                      r.mesasLibres > 0
                          ? '${r.mesasLibres} mesas libres'
                          : 'Sin mesas libres',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: r.mesasLibres > 0
                              ? AppColors.oliva
                              : AppColors.terracota)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionRapida extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback? onTap;

  const _AccionRapida({
    required this.icono,
    required this.titulo,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PuntoNuevo extends StatelessWidget {
  const _PuntoNuevo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.terracota,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ItemBusqueda extends StatelessWidget {
  final String emoji;
  final String nombre;
  final String detalle;
  final VoidCallback onTap;
  const _ItemBusqueda({
    required this.emoji,
    required this.nombre,
    required this.detalle,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro)),
                    const SizedBox(height: 2),
                    Text(detalle,
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.cafeMedio)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.cafeMedio),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final String emoji;
  final String nombre;
  final String precio;
  final String categoria;
  final VoidCallback? onTap;
  const _ItemMenu({
    required this.emoji,
    required this.nombre,
    required this.precio,
    required this.categoria,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                  const SizedBox(height: 2),
                  Text(categoria,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio)),
                ],
              ),
            ),
            Text(precio,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracota)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPromo extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String descripcion;
  final String badge;
  final Color color;
  const _TarjetaPromo({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(badge,
                          style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.crema,
                              letterSpacing: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(titulo,
                    style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 3),
                Text(descripcion,
                    style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.cafeMedio,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPlatoDestacado extends StatelessWidget {
  final String emoji;
  final String nombre;
  final String categoria;
  final String precio;
  final String rating;
  final VoidCallback? onTap;

  const _TarjetaPlatoDestacado({
    required this.emoji,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.12),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(rating,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(nombre,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(categoria,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.cafeMedio)),
                  const SizedBox(height: 8),
                  Text(precio,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracota)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPlatoRecomendado extends StatelessWidget {
  final String emoji;
  final String nombre;
  final String descripcion;
  final String precio;
  final String tiempo;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const _TarjetaPlatoRecomendado({
    required this.emoji,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tiempo,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                  const SizedBox(height: 4),
                  Text(descripcion,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.cafeMedio,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(precio,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracota)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.cafeMedio),
                      const SizedBox(width: 4),
                      Text(tiempo,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.cafeMedio)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.terracota,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(Icons.add,
                      color: AppColors.crema, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}