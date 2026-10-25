import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/inventario_service.dart';
import '../../services/tiempo_real_service.dart';
import '../../theme/app_theme.dart';
import 'admin_compras_screen.dart';

String _fmt(double n) {
  if (n == n.roundToDouble()) return n.toStringAsFixed(0);
  return n.toStringAsFixed(1);
}

String _moneda(double n) {
  final t = n.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '\$$t';
}

String _fechaHora(DateTime? d) {
  if (d == null) return '';
  final hoy = DateTime.now();
  final h = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  final mismoDia = (DateTime x, DateTime y) =>
      x.year == y.year && x.month == y.month && x.day == y.day;
  if (mismoDia(d, hoy)) return 'Hoy $h';
  if (mismoDia(d, hoy.subtract(const Duration(days: 1)))) return 'Ayer $h';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} $h';
}

class AdminInventarioScreen extends StatefulWidget {
  const AdminInventarioScreen({super.key});

  @override
  State<AdminInventarioScreen> createState() => _AdminInventarioScreenState();
}

class _AdminInventarioScreenState extends State<AdminInventarioScreen> {
  String _categoriaActiva = 'Todos';
  String _busqueda = '';

  List<_ItemInventario> _items = [];
  bool _cargando = true;
  String? _error;

  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Tiempo real: si alguien registra un movimiento, la lista se actualiza sola.
    _tiempoReal = TiempoRealConexion('dashboard')..conectar();
    _suscripcion = _tiempoReal.eventos.listen((evento) {
      final tipo = evento['tipo'] as String? ?? '';
      if (tipo == 'inventario_actualizado' || tipo == 'stock_bajo') {
        _cargar(silencioso: true);
      }
      if (tipo == 'stock_bajo' && mounted) {
        _snack(evento['mensaje'] as String? ?? 'Stock bajo');
      }
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tiempoReal.cerrar();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    final r = await InventarioService.insumos();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<InsumoApi>>) {
        _items = r.datos.map(_ItemInventario.new).toList();
        _error = null;
      } else if (r is InvError<List<InsumoApi>>) {
        if (!silencioso) _error = r.mensaje;
      }
    });
  }

  void _snack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: error ? AppColors.terracotaOscuro : null,
    ));
  }

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
  int get _bajoStock => _items.where((i) => i.estado == _EstadoStock.bajo).length;
  int get _agotados => _items.where((i) => i.estado == _EstadoStock.agotado).length;
  double get _valorTotal => _items.fold(0.0, (s, i) => s + i.valor);

  // ── Registrar entrada / salida ──
  Future<void> _registrarMovimiento(_ItemInventario item, bool esEntrada) async {
    // El cuadro devuelve la cantidad registrada (o null si se canceló).
    final cantidad = await showDialog<double>(
      context: context,
      builder: (_) => _DialogoMovimiento(item: item, esEntrada: esEntrada),
    );
    if (cantidad == null || !mounted) return;
    _snack('${esEntrada ? 'Entrada' : 'Salida'} registrada: '
        '${_fmt(cantidad)} ${item.unidad} de ${item.nombre}');
    _cargar(silencioso: true);
  }

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
            icon: const Icon(Icons.local_shipping_outlined, color: AppColors.terracota),
            tooltip: 'Compras y proveedores',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminComprasScreen()),
            ),
          ),
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
              child: RefreshIndicator(
                onRefresh: () => _cargar(silencioso: true),
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      'Valor en bodega: ${_moneda(_valorTotal)}',
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
                    if (_cargando)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorInventario(mensaje: _error!, onReintentar: _cargar)
                    else if (filtrados.isEmpty)
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
  Future<void> _abrirDetalle(BuildContext context, _ItemInventario item) async {
    // La hoja se cierra devolviendo true (entrada) / false (salida) / null.
    final esEntrada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DetalleItemSheet(
        item: item,
        onMover: (entrada) => Navigator.pop(ctx, entrada),
      ),
    );
    if (esEntrada == null || !mounted) return;
    await _registrarMovimiento(item, esEntrada);
  }

  Future<void> _abrirNuevoItem(BuildContext context) async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _NuevoItemSheet(),
    );
    if (creado == true) {
      _snack('Producto agregado al inventario');
      _cargar(silencioso: true);
    }
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
// CUADRO ENTRADA / SALIDA (maneja sus propios campos de texto)
// ─────────────────────────────────────────────────────────────
class _DialogoMovimiento extends StatefulWidget {
  final _ItemInventario item;
  final bool esEntrada;
  const _DialogoMovimiento({required this.item, required this.esEntrada});

  @override
  State<_DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends State<_DialogoMovimiento> {
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final cantidad =
        double.tryParse(_cantidadCtrl.text.trim().replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      setState(() => _error = 'Escribe una cantidad mayor que 0');
      return;
    }
    setState(() {
      _error = null;
      _enviando = true;
    });
    final r = await InventarioService.registrarMovimiento(
      insumoId: widget.item.id,
      esEntrada: widget.esEntrada,
      cantidad: cantidad,
      motivo: _motivoCtrl.text,
    );
    if (!mounted) return;
    if (r is InvError<MovimientoApi>) {
      setState(() {
        _error = r.mensaje;
        _enviando = false;
      });
      return;
    }
    Navigator.pop(context, cantidad);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final esEntrada = widget.esEntrada;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '${esEntrada ? 'Entrada' : 'Salida'} · ${item.nombre}',
        style: AppTheme.titulo(size: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hay ${_fmt(item.stock)} ${item.unidad} en bodega',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cantidadCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'CANTIDAD (${item.unidad})',
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _motivoCtrl,
              decoration: InputDecoration(
                labelText: 'MOTIVO (OPCIONAL)',
                hintText: esEntrada ? 'Ej. Compra semanal' : 'Ej. Uso en cocina',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: Text('Cancelar',
              style: GoogleFonts.inter(color: AppColors.cafeMedio)),
        ),
        TextButton(
          onPressed: _enviando ? null : _registrar,
          child: Text(
            _enviando ? 'Guardando…' : 'Registrar',
            style: GoogleFonts.inter(
                color: AppColors.terracota, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELO INTERNO (envuelve lo que manda el servidor)
// ─────────────────────────────────────────────────────────────
class _ItemInventario {
  final InsumoApi api;
  const _ItemInventario(this.api);

  int get id => api.id;
  String get nombre => api.nombre;
  String get categoria => api.categoria;
  double get stock => api.stockActual;
  double get minimo => api.stockMinimo;
  String get unidad => api.unidad;
  String get emoji => api.emoji;
  String get proveedor => api.proveedorNombre ?? 'Sin proveedor';
  double get valor => api.valor;

  _EstadoStock get estado {
    switch (api.estado) {
      case 'agotado':
        return _EstadoStock.agotado;
      case 'bajo':
        return _EstadoStock.bajo;
      default:
        return _EstadoStock.ok;
    }
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
// ERROR
// ─────────────────────────────────────────────────────────────
class _ErrorInventario extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorInventario({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.alertaTexto, size: 32),
          const SizedBox(height: 8),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.alertaTexto)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
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
  final void Function(bool esEntrada) onMover;
  const _DetalleItemSheet({required this.item, required this.onMover});

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
                  child: Text(item.emoji, style: const TextStyle(fontSize: 38)),
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
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio),
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
                      Container(width: 1, height: 32, color: AppColors.borde),
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
                      valueColor: AlwaysStoppedAnimation<Color>(estado.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FilaInfo(label: 'Proveedor', valor: item.proveedor),
            _FilaInfo(label: 'Categoría', valor: item.categoria),
            _FilaInfo(label: 'Unidad de medida', valor: item.unidad),
            _FilaInfo(label: 'Costo por unidad', valor: _moneda(item.api.costoUnitario)),
            _FilaInfo(label: 'Valor en bodega', valor: _moneda(item.valor)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onMover(false),
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
                    onPressed: () => onMover(true),
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
class _NuevoItemSheet extends StatefulWidget {
  const _NuevoItemSheet();

  @override
  State<_NuevoItemSheet> createState() => _NuevoItemSheetState();
}

class _NuevoItemSheetState extends State<_NuevoItemSheet> {
  final _nombre = TextEditingController();
  final _categoria = TextEditingController(text: 'Ingredientes');
  final _unidad = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _minimo = TextEditingController(text: '0');
  final _costo = TextEditingController(text: '0');
  List<ProveedorApi> _proveedores = [];
  int? _proveedorId;
  String? _error;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    InventarioService.proveedores().then((r) {
      if (!mounted) return;
      if (r is InvExito<List<ProveedorApi>>) setState(() => _proveedores = r.datos);
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _categoria.dispose();
    _unidad.dispose();
    _stock.dispose();
    _minimo.dispose();
    _costo.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final unidad = _unidad.text.trim();
    final stock = _num(_stock);
    final minimo = _num(_minimo);
    final costo = _num(_costo);

    if (nombre.isEmpty) return setState(() => _error = 'Escribe el nombre del producto');
    if (_categoria.text.trim().isEmpty) return setState(() => _error = 'Escribe la categoría');
    if (unidad.isEmpty) return setState(() => _error = 'Escribe la unidad (kg, litros, unidades…)');
    if (stock == null || stock < 0) return setState(() => _error = 'El stock inicial no es válido');
    if (minimo == null || minimo < 0) return setState(() => _error = 'El stock mínimo no es válido');
    if (costo == null || costo < 0) return setState(() => _error = 'El costo no es válido');

    setState(() {
      _error = null;
      _guardando = true;
    });
    final r = await InventarioService.crearInsumo(
      nombre: nombre,
      categoria: _categoria.text.trim(),
      unidad: unidad,
      stockInicial: stock,
      stockMinimo: minimo,
      costoUnitario: costo,
      proveedorId: _proveedorId,
    );
    if (!mounted) return;
    if (r is InvError<InsumoApi>) {
      setState(() {
        _error = r.mensaje;
        _guardando = false;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text('Nuevo producto', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 4),
            Text(
              'Agrega un ingrediente, bebida o insumo a tu inventario.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'NOMBRE DEL PRODUCTO',
                hintText: 'Ej. Tomate fresco',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoria,
              decoration: const InputDecoration(
                labelText: 'CATEGORÍA',
                hintText: 'Ingredientes / Bebidas / Insumos',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'STOCK INICIAL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unidad,
                    decoration: const InputDecoration(
                      labelText: 'UNIDAD',
                      hintText: 'kg / unidades',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minimo,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'STOCK MÍNIMO',
                      hintText: 'Alerta al llegar aquí',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costo,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'COSTO POR UNIDAD',
                      prefixText: '\$ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _proveedorId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'PROVEEDOR (OPCIONAL)'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sin proveedor')),
                ..._proveedores.map(
                  (p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.nombre)),
                ),
              ],
              onChanged: (v) => setState(() => _proveedorId = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.terracotaOscuro,
                    fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'GUARDANDO…' : 'AGREGAR PRODUCTO'),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// SHEET MOVIMIENTOS (historial real)
// ─────────────────────────────────────────────────────────────
class _MovimientosSheet extends StatefulWidget {
  const _MovimientosSheet();

  @override
  State<_MovimientosSheet> createState() => _MovimientosSheetState();
}

class _MovimientosSheetState extends State<_MovimientosSheet> {
  List<MovimientoApi> _movs = [];
  bool _cargando = true;
  String? _error;
  bool? _soloEntradas; // null = todos
  DateTimeRange? _rango;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final r = await InventarioService.movimientos(
      soloEntradas: _soloEntradas,
      desde: _rango?.start,
      // incluir todo el último día del rango
      hasta: _rango == null
          ? null
          : DateTime(_rango!.end.year, _rango!.end.month, _rango!.end.day, 23, 59, 59),
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<MovimientoApi>>) {
        _movs = r.datos;
      } else if (r is InvError<List<MovimientoApi>>) {
        _error = r.mensaje;
      }
    });
  }

  Future<void> _elegirRango() async {
    final hoy = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 2),
      lastDate: hoy,
      initialDateRange: _rango,
    );
    if (r != null) {
      _rango = r;
      _cargar();
    }
  }

  Widget _chip(String texto, bool? valor) {
    final activo = _soloEntradas == valor;
    return GestureDetector(
      onTap: () {
        _soloEntradas = valor;
        _cargar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? AppColors.terracota : AppColors.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? AppColors.terracota : AppColors.borde),
        ),
        child: Text(
          texto,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activo ? AppColors.crema : AppColors.cafeOscuro,
          ),
        ),
      ),
    );
  }

  String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: AppColors.terracota, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Historial de movimientos', style: AppTheme.titulo(size: 20)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('Todos', null),
                _chip('Entradas', true),
                _chip('Salidas', false),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(_rango == null
                      ? 'Rango de fechas'
                      : '${_fechaCorta(_rango!.start)} – ${_fechaCorta(_rango!.end)}'),
                  onPressed: _elegirRango,
                ),
                if (_rango != null)
                  ActionChip(
                    label: const Text('Quitar fechas'),
                    onPressed: () {
                      _rango = null;
                      _cargar();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.bordeSuave),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _ErrorInventario(mensaje: _error!, onReintentar: _cargar),
                        ),
                      )
                    : _movs.isEmpty
                        ? Center(
                            child: Text('Sin movimientos',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.cafeMedio)),
                          )
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            itemCount: _movs.length,
                            itemBuilder: (_, i) => _FilaMovimiento(m: _movs[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  final MovimientoApi m;
  const _FilaMovimiento({required this.m});

  @override
  Widget build(BuildContext context) {
    final color = m.esEntrada ? AppColors.oliva : AppColors.terracota;
    final detalle = [
      _fechaHora(m.creadoEn),
      if (m.usuarioEmail != null) m.usuarioEmail!,
      if (m.motivo != null) m.motivo!,
    ].where((s) => s.isNotEmpty).join(' · ');

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
              m.esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
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
                  '${m.esEntrada ? 'Entrada' : 'Salida'} · ${m.insumoNombre}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${m.esEntrada ? '+' : '-'}${_fmt(m.cantidad)} ${m.unidad}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'quedan ${_fmt(m.stockResultante)}',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.cafeMedio),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
