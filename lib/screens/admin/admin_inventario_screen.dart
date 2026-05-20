import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminInventarioScreen extends StatefulWidget {
  const AdminInventarioScreen({super.key});

  @override
  State<AdminInventarioScreen> createState() => _AdminInventarioScreenState();
}

class _AdminInventarioScreenState extends State<AdminInventarioScreen> {
  String _categoriaActiva = 'Todos';
  String _busqueda = '';

  final List<_ItemInventario> _items = const [
    _ItemInventario(
      nombre: 'Harina de trigo',
      categoria: 'Ingredientes',
      stock: 12.5,
      minimo: 15,
      unidad: 'kg',
      emoji: '🌾',
      proveedor: 'Molinos del Sur',
    ),
    _ItemInventario(
      nombre: 'Tomate fresco',
      categoria: 'Ingredientes',
      stock: 8,
      minimo: 10,
      unidad: 'kg',
      emoji: '🍅',
      proveedor: 'Plaza de Mercado',
    ),
    _ItemInventario(
      nombre: 'Queso mozzarella',
      categoria: 'Ingredientes',
      stock: 5.2,
      minimo: 8,
      unidad: 'kg',
      emoji: '🧀',
      proveedor: 'Lácteos Andinos',
    ),
    _ItemInventario(
      nombre: 'Carne de res',
      categoria: 'Ingredientes',
      stock: 22,
      minimo: 12,
      unidad: 'kg',
      emoji: '🥩',
      proveedor: 'Frigorífico Central',
    ),
    _ItemInventario(
      nombre: 'Pollo',
      categoria: 'Ingredientes',
      stock: 0,
      minimo: 10,
      unidad: 'kg',
      emoji: '🍗',
      proveedor: 'Avícola Nacional',
    ),
    _ItemInventario(
      nombre: 'Cerveza artesanal',
      categoria: 'Bebidas',
      stock: 48,
      minimo: 24,
      unidad: 'botellas',
      emoji: '🍺',
      proveedor: 'Cervecería Local',
    ),
    _ItemInventario(
      nombre: 'Vino tinto reserva',
      categoria: 'Bebidas',
      stock: 18,
      minimo: 12,
      unidad: 'botellas',
      emoji: '🍷',
      proveedor: 'Bodega del Valle',
    ),
    _ItemInventario(
      nombre: 'Agua mineral',
      categoria: 'Bebidas',
      stock: 6,
      minimo: 20,
      unidad: 'botellas',
      emoji: '💧',
      proveedor: 'Distribuidora H2O',
    ),
    _ItemInventario(
      nombre: 'Servilletas',
      categoria: 'Insumos',
      stock: 450,
      minimo: 200,
      unidad: 'unidades',
      emoji: '🧻',
      proveedor: 'Papelería Express',
    ),
    _ItemInventario(
      nombre: 'Aceite de oliva',
      categoria: 'Ingredientes',
      stock: 9.5,
      minimo: 5,
      unidad: 'litros',
      emoji: '🫒',
      proveedor: 'Importadora Mediterránea',
    ),
  ];

  List<String> get _categorias =>
      ['Todos', ...{for (final i in _items) i.categoria}];

  List<_ItemInventario> get _itemsFiltrados {
    return _items.where((i) {
      final coincideCategoria =
          _categoriaActiva == 'Todos' || i.categoria == _categoriaActiva;
      final coincideBusqueda = _busqueda.isEmpty ||
          i.nombre.toLowerCase().contains(_busqueda.toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  int get _totalItems => _items.length;
  int get _bajoStock =>
      _items.where((i) => i.stock > 0 && i.stock < i.minimo).length;
  int get _agotados => _items.where((i) => i.stock == 0).length;

  @override
  Widget build(BuildContext context) {
    final filtrados = _itemsFiltrados;

    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cafeOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inventario',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.terracota),
            tooltip: 'Movimientos',
            onPressed: () => _abrirMovimientos(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subtítulo ──
                    Text(
                      'CONTROL DE STOCK',
                      style: AppTheme.etiqueta(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu inventario en tiempo real',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.cafeMedio,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Métricas ──
                    Row(
                      children: [
                        Expanded(
                          child: _TarjetaResumen(
                            icono: Icons.inventory_2_outlined,
                            titulo: 'Productos',
                            valor: '$_totalItems',
                            color: AppColors.terracota,
                            sufijo: 'totales',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TarjetaResumen(
                            icono: Icons.warning_amber_rounded,
                            titulo: 'Bajo stock',
                            valor: '$_bajoStock',
                            color: AppColors.oliva,
                            sufijo: 'avisos',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TarjetaResumen(
                            icono: Icons.remove_shopping_cart_outlined,
                            titulo: 'Agotados',
                            valor: '$_agotados',
                            color: AppColors.terracotaOscuro,
                            sufijo: 'urgente',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Alertas críticas ──
                    if (_agotados > 0) _BannerAlerta(cantidad: _agotados),

                    // ── Buscador ──
                    TextField(
                      onChanged: (v) => setState(() => _busqueda = v),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.cafeOscuro,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto…',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.cafeMedio,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Filtros por categoría ──
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categorias.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categorias[i];
                          final activo = cat == _categoriaActiva;
                          return GestureDetector(
                            onTap: () => setState(() => _categoriaActiva = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: activo
                                    ? AppColors.terracota
                                    : AppColors.superficie,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: activo
                                      ? AppColors.terracota
                                      : AppColors.borde,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: activo
                                        ? AppColors.crema
                                        : AppColors.cafeOscuro,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Lista de items ──
                    if (filtrados.isEmpty)
                      const _SinResultados()
                    else
                      ...filtrados.map((it) => _TarjetaItem(
                            item: it,
                            onTap: () => _abrirDetalle(context, it),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirNuevoItem(context),
        backgroundColor: AppColors.terracota,
        foregroundColor: AppColors.crema,
        elevation: 4,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Nuevo producto',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ── Sheets ─────────────────────────────────────────────────
  void _abrirDetalle(BuildContext context, _ItemInventario item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DetalleItemSheet(item: item),
    );
  }

  void _abrirNuevoItem(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _NuevoItemSheet(),
    );
  }

  void _abrirMovimientos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _MovimientosSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELO INTERNO
// ─────────────────────────────────────────────────────────────
class _ItemInventario {
  final String nombre;
  final String categoria;
  final double stock;
  final double minimo;
  final String unidad;
  final String emoji;
  final String proveedor;

  const _ItemInventario({
    required this.nombre,
    required this.categoria,
    required this.stock,
    required this.minimo,
    required this.unidad,
    required this.emoji,
    required this.proveedor,
  });

  _EstadoStock get estado {
    if (stock == 0) return _EstadoStock.agotado;
    if (stock < minimo) return _EstadoStock.bajo;
    return _EstadoStock.ok;
  }

  double get porcentaje {
    if (minimo == 0) return 1;
    final p = stock / (minimo * 1.5);
    return p > 1 ? 1 : p;
  }
}

enum _EstadoStock { ok, bajo, agotado }

extension on _EstadoStock {
  Color get color {
    switch (this) {
      case _EstadoStock.ok:
        return AppColors.oliva;
      case _EstadoStock.bajo:
        return AppColors.terracotaOscuro;
      case _EstadoStock.agotado:
        return AppColors.terracota;
    }
  }

  String get etiqueta {
    switch (this) {
      case _EstadoStock.ok:
        return 'En stock';
      case _EstadoStock.bajo:
        return 'Bajo';
      case _EstadoStock.agotado:
        return 'Agotado';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA RESUMEN
// ─────────────────────────────────────────────────────────────
class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String sufijo;
  final Color color;

  const _TarjetaResumen({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.sufijo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          Text(
            sufijo,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BANNER ALERTA
// ─────────────────────────────────────────────────────────────
class _BannerAlerta extends StatelessWidget {
  final int cantidad;
  const _BannerAlerta({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.terracota.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.terracota,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productos agotados',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.alertaTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cantidad producto${cantidad == 1 ? '' : 's'} requieren reposición inmediata',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.alertaTexto.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.alertaTexto,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA ITEM
// ─────────────────────────────────────────────────────────────
class _TarjetaItem extends StatelessWidget {
  final _ItemInventario item;
  final VoidCallback onTap;

  const _TarjetaItem({required this.item, required this.onTap});

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final estado = item.estado;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.cremaOscura,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.proveedor,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.cafeMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _fmt(item.stock),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: estado.color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item.unidad,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cafeMedio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: estado.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estado.etiqueta,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: estado.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progreso
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.porcentaje,
                      minHeight: 6,
                      backgroundColor: AppColors.bordeSuave,
                      valueColor: AlwaysStoppedAnimation<Color>(estado.color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mín: ${_fmt(item.minimo)} ${item.unidad}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.cafeMedio,
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
// SIN RESULTADOS
// ─────────────────────────────────────────────────────────────
class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            color: AppColors.cafeMedio,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin coincidencias',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET DETALLE ITEM
// ─────────────────────────────────────────────────────────────
class _DetalleItemSheet extends StatelessWidget {
  final _ItemInventario item;
  const _DetalleItemSheet({required this.item});

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final estado = item.estado;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 38)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              item.nombre,
              textAlign: TextAlign.center,
              style: AppTheme.titulo(size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              item.categoria,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.cafeMedio,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borde),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DatoColumna(
                          titulo: 'STOCK ACTUAL',
                          valor: '${_fmt(item.stock)} ${item.unidad}',
                          color: estado.color,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.borde,
                      ),
                      Expanded(
                        child: _DatoColumna(
                          titulo: 'MÍNIMO',
                          valor: '${_fmt(item.minimo)} ${item.unidad}',
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.porcentaje,
                      minHeight: 8,
                      backgroundColor: AppColors.bordeSuave,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(estado.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FilaInfo(label: 'Proveedor', valor: item.proveedor),
            _FilaInfo(label: 'Categoría', valor: item.categoria),
            _FilaInfo(label: 'Unidad de medida', valor: item.unidad),
            const _FilaInfo(label: 'Último movimiento', valor: 'Hace 2 horas'),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Salida'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracotaOscuro,
                      side: BorderSide(
                        color: AppColors.terracota.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Entrada'),
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

class _DatoColumna extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  const _DatoColumna({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: AppTheme.etiqueta(),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final String label;
  final String valor;
  const _FilaInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.cafeMedio,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET NUEVO ITEM
// ─────────────────────────────────────────────────────────────
class _NuevoItemSheet extends StatelessWidget {
  const _NuevoItemSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 20),
            Text(
              'Nuevo producto',
              style: AppTheme.titulo(size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              'Agrega un ingrediente, bebida o insumo a tu inventario.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.cafeMedio,
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'NOMBRE DEL PRODUCTO',
                hintText: 'Ej. Tomate fresco',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'CATEGORÍA',
                hintText: 'Ingredientes / Bebidas / Insumos',
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'STOCK INICIAL',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'UNIDAD',
                      hintText: 'kg / unid.',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'STOCK MÍNIMO',
                hintText: 'Te alertaremos al llegar a este valor',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'PROVEEDOR (OPCIONAL)',
                hintText: 'Nombre del proveedor',
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('AGREGAR PRODUCTO'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET MOVIMIENTOS
// ─────────────────────────────────────────────────────────────
class _MovimientosSheet extends StatelessWidget {
  const _MovimientosSheet();

  @override
  Widget build(BuildContext context) {
    final movimientos = [
      ('Entrada · Tomate fresco', '+5 kg', 'Hoy 10:24', true),
      ('Salida · Queso mozzarella', '-1.2 kg', 'Hoy 09:15', false),
      ('Entrada · Carne de res', '+8 kg', 'Ayer 18:40', true),
      ('Salida · Aceite de oliva', '-0.5 lt', 'Ayer 14:20', false),
      ('Entrada · Vino tinto reserva', '+12 botellas', 'Ayer 11:08', true),
      ('Salida · Cerveza artesanal', '-6 botellas', 'Ayer 09:33', false),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: AppColors.terracota,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Movimientos recientes',
                    style: AppTheme.titulo(size: 20),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.bordeSuave),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: movimientos.length,
              itemBuilder: (_, i) {
                final (descripcion, cantidad, tiempo, esEntrada) =
                    movimientos[i];
                final color =
                    esEntrada ? AppColors.oliva : AppColors.terracota;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          esEntrada
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              descripcion,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cafeOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tiempo,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        cantidad,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
