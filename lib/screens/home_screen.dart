import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_controller.dart';
import '../services/pedido_service.dart';
import '../utils/app_strings.dart';
import '../services/menu_service.dart';
import 'reservas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _categoriaSeleccionada = 'Todos';
  List<Producto> _productos = [];
  bool _cargandoMenu = true;

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Todos', 'emoji': '🍽️'},
    {'nombre': 'Entradas', 'emoji': '🥗'},
    {'nombre': 'Principales', 'emoji': '🍝'},
    {'nombre': 'Postres', 'emoji': '🍰'},
    {'nombre': 'Bebidas', 'emoji': '🍹'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarMenu();
  }

  Future<void> _cargarMenu() async {
    setState(() => _cargandoMenu = true);
    final productos = await MenuService.obtenerMenu();
    setState(() {
      _productos = productos;
      _cargandoMenu = false;
    });
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

  void _verNotificaciones() {
    _abrirHoja(
      titulo: 'Notificaciones',
      altura: 0.6,
      contenido: const Column(
        children: [
          _ItemNotificacion(
            icono: Icons.local_dining,
            titulo: 'Tu pedido está en camino',
            detalle: 'Pasta al pesto · llegando en 4 min',
            tiempo: 'hace 2 min',
            esNuevo: true,
          ),
          _ItemNotificacion(
            icono: Icons.local_offer,
            titulo: '20% en platos de temporada',
            detalle: 'Solo hoy, aprovecha la oferta',
            tiempo: 'hace 1 h',
            esNuevo: true,
          ),
          _ItemNotificacion(
            icono: Icons.star,
            titulo: '¿Cómo estuvo tu última visita?',
            detalle: 'Califica tu experiencia y gana puntos',
            tiempo: 'ayer',
          ),
          _ItemNotificacion(
            icono: Icons.event,
            titulo: 'Recordatorio de reserva',
            detalle: 'Mañana a las 8:00 pm · 4 personas',
            tiempo: 'hace 2 días',
          ),
        ],
      ),
    );
  }

  void _abrirBuscador() {
    final ctrl = TextEditingController();
    _abrirHoja(
      titulo: 'Buscar',
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
                  hintText: 'Pasta, postre, italiana...',
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
              _toast('Explora el menú y agrega al carrito');
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

  // ── NUEVO: abre Ver Menú completo ──
  void _abrirVerMenu() {
    VerMenuSheet.mostrar(context, _productos, _cargandoMenu);
  }

  // ── NUEVO: navega a Crear Pedido ──
  void _abrirCrearPedido() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CrearPedidoScreen(),
    ),
  );
}

  void _abrirMenuCompleto() {
    _abrirHoja(
      titulo: 'Menú completo',
      altura: 0.85,
      contenido: _cargandoMenu
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: _productos
                  .map((p) => _ItemMenu(
                        emoji: p.emoji,
                        nombre: p.nombre,
                        precio: p.precioFormateado,
                        categoria: p.categoria ?? '',
                        onTap: () => _abrirDetallePlato(p),
                      ))
                  .toList(),
            ),
    );
  }

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
          const SizedBox(height: 16),
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
            onPressed: () {
              Navigator.pop(context);
              Carrito().agregar(producto);
              _toast('${producto.nombre} agregado al carrito 🛒');
            },
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('AGREGAR AL CARRITO'),
          ),
        ],
      ),
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
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.notifications_outlined,
                                  color: AppColors.terracota),
                              Positioned(
                                top: 10,
                                right: 12,
                                child: _PuntoNuevo(),
                              ),
                            ],
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
              const SizedBox(height: 20),

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

              // ════════════════════════════════════════════════
              //  NUEVAS TARJETAS GRANDES: Ver Menú + Crea Pedido
              // ════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TarjetaAccionGrande(
                      emoji: '🍽️',
                      titulo: 'Ver Menú',
                      subtitulo: 'Explora todos nuestros platos',
                      color: AppColors.terracota,
                      onTap: _abrirVerMenu,
                    ),
                    const SizedBox(height: 10),
                    TarjetaAccionGrande(
                      emoji: '📝',
                      titulo: 'Crea tu Pedido',
                      subtitulo: 'Arma tu pedido y elige cómo recibirlo',
                      color: AppColors.oliva,
                      onTap: _abrirCrearPedido,
                    ),
                  ],
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
                  itemCount: _categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final cat = _categorias[index];
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
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _productos.take(4).length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, index) {
                          final p = _productos[index];
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
                          onAdd: () {
                            Carrito().agregar(p);
                            _toast('${p.nombre} agregado al carrito 🛒');
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

class _ItemNotificacion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final String tiempo;
  final bool esNuevo;
  const _ItemNotificacion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.tiempo,
    this.esNuevo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esNuevo ? AppColors.alertaFondo : AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esNuevo
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
            child: Icon(icono, color: AppColors.terracota, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(titulo,
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                    ),
                    if (esNuevo) const _PuntoNuevo(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(detalle,
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: AppColors.cafeMedio)),
                const SizedBox(height: 4),
                Text(tiempo,
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