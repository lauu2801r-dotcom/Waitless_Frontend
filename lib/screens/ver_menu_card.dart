// ─────────────────────────────────────────────────────────────
//  VER MENÚ CARD — agregar en home_screen.dart
//  Muestra todos los productos con filtro por categoría,
//  buscador interno y detalle individual con "Agregar al carrito"
// ─────────────────────────────────────────────────────────────
//
//  INSTRUCCIONES DE INTEGRACIÓN:
//  1. Importa este archivo en home_screen.dart
//  2. Agrega _VerMenuCard como primera tarjeta en las acciones
//     rápidas (antes de Reservar mesa), o como sección dedicada.
//  3. Llama a _abrirVerMenu() desde el onTap de la tarjeta.
//
//  UBICACIÓN SUGERIDA en home_screen.dart → método build():
//  Añade ANTES de las acciones rápidas existentes:
//
//    _TarjetaAccionGrande(
//      emoji: '🍽️',
//      titulo: 'Ver Menú',
//      subtitulo: 'Todos nuestros platos',
//      color: AppColors.terracota,
//      onTap: _abrirVerMenu,
//    ),
//
//  Y el método:
//    void _abrirVerMenu() => VerMenuSheet.mostrar(context, _productos, _cargandoMenu);
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/menu_service.dart';
import '../services/pedido_service.dart';

// ─────────────────────────────────────────────────────────────
//  PUNTO DE ENTRADA ESTÁTICO
// ─────────────────────────────────────────────────────────────

class VerMenuSheet {
  static void mostrar(
    BuildContext context,
    List<Producto> productos,
    bool cargando,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _VerMenuContent(
        productos: productos,
        cargando: cargando,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CONTENIDO PRINCIPAL DEL SHEET
// ─────────────────────────────────────────────────────────────

class _VerMenuContent extends StatefulWidget {
  final List<Producto> productos;
  final bool cargando;

  const _VerMenuContent({
    required this.productos,
    required this.cargando,
  });

  @override
  State<_VerMenuContent> createState() => _VerMenuContentState();
}

class _VerMenuContentState extends State<_VerMenuContent> {
  String _categoriaActiva = 'Todos';
  String _busqueda = '';
  final TextEditingController _buscadorCtrl = TextEditingController();

  final List<Map<String, String>> _categorias = [
    {'nombre': 'Todos', 'emoji': '🍽️'},
    {'nombre': 'Entradas', 'emoji': '🥗'},
    {'nombre': 'Principales', 'emoji': '🍝'},
    {'nombre': 'Postres', 'emoji': '🍰'},
    {'nombre': 'Bebidas', 'emoji': '🍹'},
  ];

  List<Producto> get _productosFiltrados {
    var lista = widget.productos;

    if (_categoriaActiva != 'Todos') {
      lista = lista.where((p) => p.categoria == _categoriaActiva).toList();
    }

    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              (p.categoria?.toLowerCase().contains(q) ?? false) ||
              (p.descripcion?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return lista;
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  void _verDetalle(Producto p) {
    _DetalleProductoSheet.mostrar(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _productosFiltrados;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.crema,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Handle ──
            const SizedBox(height: 12),
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

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nuestro Menú', style: AppTheme.titulo(size: 24)),
                        Text(
                          '${widget.productos.length} platos disponibles',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.cafeMedio),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.cafeMedio),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Buscador ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _buscadorCtrl,
                onChanged: (v) => setState(() => _busqueda = v),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.cafeOscuro),
                decoration: InputDecoration(
                  hintText: 'Buscar en el menú...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.cafeMedio),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.cafeMedio, size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.cafeMedio, size: 18),
                          onPressed: () {
                            _buscadorCtrl.clear();
                            setState(() => _busqueda = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filtros de categoría ──
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
                    onTap: () =>
                        setState(() => _categoriaActiva = cat['nombre']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: activa
                            ? AppColors.terracota
                            : AppColors.superficie,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activa
                              ? AppColors.terracota
                              : AppColors.borde,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['emoji']!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            cat['nombre']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activa
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
            const SizedBox(height: 16),

            // ── Divider ──
            const Divider(height: 1, color: AppColors.borde),

            // ── Lista de productos ──
            Expanded(
              child: widget.cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.terracota),
                    )
                  : filtrados.isEmpty
                      ? _EmptyState(query: _busqueda)
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _TarjetaProductoMenu(
                            producto: filtrados[i],
                            onTap: () => _verDetalle(filtrados[i]),
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
//  TARJETA DE PRODUCTO EN LISTA
// ─────────────────────────────────────────────────────────────

class _TarjetaProductoMenu extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const _TarjetaProductoMenu({
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Emoji / imagen ──
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(producto.emoji,
                    style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro,
                          ),
                        ),
                      ),
                      if (producto.categoria != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cremaOscura,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            producto.categoria!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeMedio,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (producto.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      producto.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.cafeMedio,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        producto.precioFormateado,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracota,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.terracota,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ver detalle',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.crema,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DETALLE DE PRODUCTO (sub-sheet)
// ─────────────────────────────────────────────────────────────

class _DetalleProductoSheet {
  static void mostrar(BuildContext context, Producto producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleProductoContent(producto: producto),
    );
  }
}

class _DetalleProductoContent extends StatelessWidget {
  final Producto producto;

  const _DetalleProductoContent({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),

          // Imagen
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(producto.emoji,
                  style: const TextStyle(fontSize: 90)),
            ),
          ),
          const SizedBox(height: 20),

          // Nombre y categoría
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(producto.nombre, style: AppTheme.titulo(size: 22)),
              ),
              if (producto.categoria != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.olivaFondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    producto.categoria!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.oliva,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Descripción
          if (producto.descripcion != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                producto.descripcion!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                  height: 1.6,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Tiempo estimado
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
                Text(
                  'Listo en aproximadamente 15-20 minutos',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.exitoTexto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Precio y botón
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Precio',
                      style: AppTheme.etiqueta()),
                  const SizedBox(height: 2),
                  Text(
                    producto.precioFormateado,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracota,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Carrito().agregar(producto);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${producto.nombre} agregado al carrito 🛒',
                          style: GoogleFonts.inter(color: AppColors.crema),
                        ),
                        backgroundColor: AppColors.cafeOscuro,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('AGREGAR AL CARRITO'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ESTADO VACÍO
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Sin productos en esta categoría'
                  : 'Sin resultados para "$query"',
              textAlign: TextAlign.center,
              style: AppTheme.titulo(size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otra búsqueda o categoría',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDGET DE TARJETA GRANDE PARA HOME (opcional)
//  Úsala en home_screen.dart para acciones principales
// ─────────────────────────────────────────────────────────────

class TarjetaAccionGrande extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const TarjetaAccionGrande({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color),
          ],
        ),
      ),
    );
  }
}