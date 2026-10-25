import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/compras_service.dart';
import '../../services/inventario_service.dart';
import '../../services/tiempo_real_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';

// ─────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL: dos pestañas (Órdenes | Proveedores)
// ─────────────────────────────────────────────────────────────
class AdminComprasScreen extends StatelessWidget {
  const AdminComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.crema,
        appBar: AppBar(
          backgroundColor: AppColors.crema,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cafeOscuro),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Compras',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.terracota,
            unselectedLabelColor: AppColors.cafeMedio,
            indicatorColor: AppColors.terracota,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'Órdenes'), Tab(text: 'Proveedores')],
          ),
        ),
        body: const TabBarView(children: [_TabOrdenes(), _TabProveedores()]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Utilidades visuales
// ─────────────────────────────────────────────────────────────
Color _colorEstado(String e) {
  switch (e) {
    case 'completa':
      return AppColors.oliva;
    case 'parcial':
      return AppColors.terracota;
    case 'cancelada':
      return AppColors.cafeMedio;
    default:
      return const Color(0xFFB07D2B); // pendiente
  }
}

String _etiquetaEstado(String e) {
  switch (e) {
    case 'completa':
      return 'Completa';
    case 'parcial':
      return 'Parcial';
    case 'cancelada':
      return 'Cancelada';
    default:
      return 'Pendiente';
  }
}

void _avisar(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texto),
    backgroundColor: error ? AppColors.terracotaOscuro : null,
  ));
}

Widget _manijaSheet() => Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.cremaOscura,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

class _ChipEstado extends StatelessWidget {
  final String estado;
  const _ChipEstado(this.estado);

  @override
  Widget build(BuildContext context) {
    final c = _colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _etiquetaEstado(estado),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

class _MensajeError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _MensajeError({required this.mensaje, required this.onReintentar});

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

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);

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
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PESTAÑA ÓRDENES
// ─────────────────────────────────────────────────────────────
class _TabOrdenes extends StatefulWidget {
  const _TabOrdenes();

  @override
  State<_TabOrdenes> createState() => _TabOrdenesState();
}

class _TabOrdenesState extends State<_TabOrdenes> {
  List<OrdenApi> _ordenes = [];
  bool _cargando = true;
  String? _error;
  String _filtro = 'todas';

  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _cargar();
    _tiempoReal = TiempoRealConexion('dashboard')..conectar();
    _suscripcion = _tiempoReal.eventos.listen((e) {
      if (e['tipo'] == 'orden_compra_actualizada') _cargar(silencioso: true);
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
    final r = await ComprasService.ordenes();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<OrdenApi>>) {
        _ordenes = r.datos;
        _error = null;
      } else if (r is InvError<List<OrdenApi>> && !silencioso) {
        _error = r.mensaje;
      }
    });
  }

  List<OrdenApi> get _filtradas =>
      _filtro == 'todas' ? _ordenes : _ordenes.where((o) => o.estado == _filtro).toList();

  Future<void> _abrirDetalle(OrdenApi o) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetalleOrdenSheet(ordenId: o.id),
    );
    if (mounted) _cargar(silencioso: true);
  }

  Future<void> _nuevaOrden() async {
    final creada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NuevaOrdenSheet(),
    );
    if (creada == true && mounted) {
      _avisar(context, 'Orden de compra creada');
      _cargar(silencioso: true);
    }
  }

  Widget _chipFiltro(String valor, String texto) {
    final activo = _filtro == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtro = valor),
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

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaOrden,
        backgroundColor: AppColors.terracota,
        foregroundColor: AppColors.crema,
        icon: const Icon(Icons.add, size: 20),
        label: Text('Nueva orden',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _cargar(silencioso: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chipFiltro('todas', 'Todas'),
                  const SizedBox(width: 8),
                  _chipFiltro('pendiente', 'Pendientes'),
                  const SizedBox(width: 8),
                  _chipFiltro('parcial', 'Parciales'),
                  const SizedBox(width: 8),
                  _chipFiltro('completa', 'Completas'),
                  const SizedBox(width: 8),
                  _chipFiltro('cancelada', 'Canceladas'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MensajeError(mensaje: _error!, onReintentar: _cargar)
            else if (lista.isEmpty)
              const _Vacio('No hay órdenes de compra todavía.\nCrea la primera con "Nueva orden".')
            else
              ...lista.map((o) => _TarjetaOrden(orden: o, onTap: () => _abrirDetalle(o))),
          ],
        ),
      ),
    );
  }
}

class _TarjetaOrden extends StatelessWidget {
  final OrdenApi orden;
  final VoidCallback onTap;
  const _TarjetaOrden({required this.orden, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  color: AppColors.terracota, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${orden.id} · ${orden.proveedorNombre}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    orden.fechaEsperada == null
                        ? 'Sin fecha de entrega'
                        : 'Entrega esperada: ${fechaCorta(orden.fechaEsperada)}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  moneda(orden.total),
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro),
                ),
                const SizedBox(height: 4),
                _ChipEstado(orden.estado),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DETALLE DE UNA ORDEN (recibir / cancelar)
// ─────────────────────────────────────────────────────────────
class _DetalleOrdenSheet extends StatefulWidget {
  final int ordenId;
  const _DetalleOrdenSheet({required this.ordenId});

  @override
  State<_DetalleOrdenSheet> createState() => _DetalleOrdenSheetState();
}

class _DetalleOrdenSheetState extends State<_DetalleOrdenSheet> {
  OrdenApi? _orden;
  String? _error;
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await ComprasService.orden(widget.ordenId);
    if (!mounted) return;
    setState(() {
      if (r is InvExito<OrdenApi>) {
        _orden = r.datos;
        _error = null;
      } else if (r is InvError<OrdenApi>) {
        _error = r.mensaje;
      }
    });
  }

  Future<void> _recibir() async {
    final orden = _orden!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoRecepcion(orden: orden),
    );
    if (ok == true && mounted) {
      _avisar(context, 'Recepción registrada. El inventario se actualizó.');
      _cargar();
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar orden', style: AppTheme.titulo(size: 18)),
        content: Text(
          '¿Cancelar la orden #${_orden!.id}? Lo que ya llegó se conserva en el inventario.',
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
    if (confirmar != true || !mounted) return;
    setState(() => _trabajando = true);
    final r = await ComprasService.cancelar(_orden!.id);
    if (!mounted) return;
    setState(() => _trabajando = false);
    if (r is InvError<OrdenApi>) {
      _avisar(context, r.mensaje, error: true);
    } else {
      _avisar(context, 'Orden cancelada');
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _orden;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        if (o == null) {
          return Center(
            child: _error == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: _MensajeError(mensaje: _error!, onReintentar: _cargar),
                  ),
          );
        }
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _manijaSheet(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Orden #${o.id}', style: AppTheme.titulo(size: 22)),
                ),
                _ChipEstado(o.estado),
              ],
            ),
            const SizedBox(height: 4),
            Text(o.proveedorNombre,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
            const SizedBox(height: 14),
            _Fila('Entrega esperada', fechaCorta(o.fechaEsperada)),
            if (o.fechaCumplimiento != null)
              _Fila('Completada el', fechaHora(o.fechaCumplimiento)),
            _Fila('Creada por', o.creadoPorEmail ?? '—'),
            _Fila('Total', moneda(o.total)),
            if (o.notas != null && o.notas!.isNotEmpty) _Fila('Notas', o.notas!),
            const SizedBox(height: 14),
            Text('PRODUCTOS', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            ...o.items.map((it) {
              final p = it.pedida == 0 ? 0.0 : (it.recibida / it.pedida).clamp(0.0, 1.0);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(it.insumoNombre,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cafeOscuro)),
                        ),
                        Text(moneda(it.subtotal),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.cafeMedio)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p,
                        minHeight: 6,
                        backgroundColor: AppColors.bordeSuave,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.oliva),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Llegaron ${fmtNum(it.recibida)} de ${fmtNum(it.pedida)} ${it.unidad}'
                        ' · ${moneda(it.costo)} c/u',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            Text('HISTORIAL', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            ...o.historial.reversed.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colorEstado(h.estado),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.detalle,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cafeOscuro)),
                            Text(
                              [fechaHora(h.creadoEn), h.usuarioEmail ?? '']
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.cafeMedio),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (o.sePuedeRecibir) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _trabajando ? null : _cancelar,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotaOscuro,
                        side: BorderSide(
                            color: AppColors.terracota.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _trabajando ? null : _recibir,
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Recibir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  const _Fila(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CUADRO "RECIBIR MERCANCÍA" (maneja sus propios campos)
// ─────────────────────────────────────────────────────────────
class _DialogoRecepcion extends StatefulWidget {
  final OrdenApi orden;
  const _DialogoRecepcion({required this.orden});

  @override
  State<_DialogoRecepcion> createState() => _DialogoRecepcionState();
}

class _DialogoRecepcionState extends State<_DialogoRecepcion> {
  late final List<ItemOrdenApi> _pendientes;
  late final Map<int, TextEditingController> _ctrls;
  String? _error;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _pendientes = widget.orden.items.where((i) => i.falta > 0).toList();
    // Por defecto sugerimos recibir todo lo que falta.
    _ctrls = {
      for (final i in _pendientes) i.id: TextEditingController(text: fmtNum(i.falta)),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    final recepcion = <({int itemId, double cantidad})>[];
    for (final it in _pendientes) {
      final texto = _ctrls[it.id]!.text.trim().replaceAll(',', '.');
      if (texto.isEmpty) continue;
      final v = double.tryParse(texto);
      if (v == null || v < 0) {
        setState(() => _error = 'Revisa la cantidad de ${it.insumoNombre}');
        return;
      }
      if (v > it.falta + 1e-9) {
        setState(() => _error =
            'De ${it.insumoNombre} solo faltan ${fmtNum(it.falta)} ${it.unidad}');
        return;
      }
      if (v > 0) recepcion.add((itemId: it.id, cantidad: v));
    }
    if (recepcion.isEmpty) {
      setState(() => _error = 'Escribe al menos una cantidad mayor que 0');
      return;
    }
    setState(() {
      _error = null;
      _enviando = true;
    });
    final r = await ComprasService.recibir(widget.orden.id, recepcion);
    if (!mounted) return;
    if (r is InvError<OrdenApi>) {
      setState(() {
        _error = r.mensaje;
        _enviando = false;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Recibir mercancía', style: AppTheme.titulo(size: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe cuánto llegó de cada producto. Se sumará al inventario.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio),
            ),
            const SizedBox(height: 12),
            ..._pendientes.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _ctrls[it.id],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${it.insumoNombre.toUpperCase()} (${it.unidad})',
                      helperText: 'Faltan ${fmtNum(it.falta)}',
                    ),
                  ),
                )),
            if (_error != null)
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.terracotaOscuro,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
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
// NUEVA ORDEN
// ─────────────────────────────────────────────────────────────
class _FilaNuevaOrden {
  InsumoApi? insumo;
  final cantidad = TextEditingController();
  final costo = TextEditingController();

  void dispose() {
    cantidad.dispose();
    costo.dispose();
  }
}

class _NuevaOrdenSheet extends StatefulWidget {
  const _NuevaOrdenSheet();

  @override
  State<_NuevaOrdenSheet> createState() => _NuevaOrdenSheetState();
}

class _NuevaOrdenSheetState extends State<_NuevaOrdenSheet> {
  List<ProveedorFullApi> _proveedores = [];
  List<InsumoApi> _insumos = [];
  int? _proveedorId;
  DateTime? _fecha;
  final _notas = TextEditingController();
  final List<_FilaNuevaOrden> _filas = [_FilaNuevaOrden()];
  final List<_FilaNuevaOrden> _descartadas = [];
  String? _error;
  bool _guardando = false;
  bool _cargandoDatos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final res = await Future.wait([
      ComprasService.proveedores(),
      InventarioService.insumos(),
    ]);
    if (!mounted) return;
    setState(() {
      _cargandoDatos = false;
      final p = res[0];
      final i = res[1];
      if (p is InvExito<List<ProveedorFullApi>>) _proveedores = p.datos;
      if (i is InvExito<List<InsumoApi>>) _insumos = i.datos;
      if (p is InvError || i is InvError) {
        _error = 'No se pudieron cargar proveedores o productos';
      }
    });
  }

  @override
  void dispose() {
    _notas.dispose();
    for (final f in [..._filas, ..._descartadas]) {
      f.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  double get _total =>
      _filas.fold(0.0, (s, f) => s + _num(f.cantidad) * _num(f.costo));

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy.add(const Duration(days: 3)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (_proveedorId == null) {
      setState(() => _error = 'Elige un proveedor');
      return;
    }
    final items = <({int insumoId, double cantidad, double costo})>[];
    final usados = <int>{};
    for (final f in _filas) {
      if (f.insumo == null) {
        setState(() => _error = 'Elige el producto en todas las filas');
        return;
      }
      final cantidad = _num(f.cantidad);
      if (cantidad <= 0) {
        setState(() => _error = 'Escribe una cantidad mayor que 0 para ${f.insumo!.nombre}');
        return;
      }
      if (!usados.add(f.insumo!.id)) {
        setState(() => _error = '${f.insumo!.nombre} está repetido en la orden');
        return;
      }
      items.add((insumoId: f.insumo!.id, cantidad: cantidad, costo: _num(f.costo)));
    }
    setState(() {
      _error = null;
      _guardando = true;
    });
    final r = await ComprasService.crearOrden(
      proveedorId: _proveedorId!,
      fechaEsperada: _fecha,
      notas: _notas.text,
      items: items,
    );
    if (!mounted) return;
    if (r is InvError<OrdenApi>) {
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
            _manijaSheet(),
            const SizedBox(height: 20),
            Text('Nueva orden de compra', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 4),
            Text(
              'Pide productos a un proveedor. Cuando lleguen, los recibes y el inventario sube solo.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio),
            ),
            const SizedBox(height: 18),
            if (_cargandoDatos)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              DropdownButtonFormField<int>(
                value: _proveedorId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'PROVEEDOR'),
                items: _proveedores
                    .map((p) => DropdownMenuItem<int>(value: p.id, child: Text(p.nombre)))
                    .toList(),
                onChanged: (v) => setState(() => _proveedorId = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.event, size: 18),
                label: Text(_fecha == null
                    ? 'Fecha de entrega esperada (opcional)'
                    : 'Entrega esperada: ${fechaCorta(_fecha)}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cafeOscuro,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notas,
                decoration: const InputDecoration(
                  labelText: 'NOTAS (OPCIONAL)',
                  hintText: 'Ej. Reposición urgente',
                ),
              ),
              const SizedBox(height: 18),
              Text('PRODUCTOS', style: AppTheme.etiqueta()),
              const SizedBox(height: 8),
              ...List.generate(_filas.length, (idx) {
                final f = _filas[idx];
                return Container(
                  key: ObjectKey(f),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: f.insumo?.id,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'PRODUCTO'),
                              items: _insumos
                                  .map((i) => DropdownMenuItem<int>(
                                      value: i.id,
                                      child: Text('${i.emoji} ${i.nombre}')))
                                  .toList(),
                              onChanged: (id) => setState(() {
                                f.insumo = _insumos.firstWhere((i) => i.id == id);
                                f.costo.text = fmtNum(f.insumo!.costoUnitario);
                              }),
                            ),
                          ),
                          if (_filas.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.terracotaOscuro),
                              onPressed: () => setState(() {
                                _filas.removeAt(idx);
                                _descartadas.add(f); // se libera al cerrar
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: f.cantidad,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                labelText: 'CANTIDAD',
                                suffixText: f.insumo?.unidad,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: f.costo,
                              onChanged: (_) => setState(() {}),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'COSTO UNIDAD',
                                prefixText: '\$ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _filas.add(_FilaNuevaOrden())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar otro producto'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total estimado',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
                  Text(moneda(_total),
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro)),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.terracotaOscuro,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: (_guardando || _cargandoDatos) ? null : _guardar,
              child: Text(_guardando ? 'GUARDANDO…' : 'CREAR ORDEN'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PESTAÑA PROVEEDORES
// ─────────────────────────────────────────────────────────────
class _TabProveedores extends StatefulWidget {
  const _TabProveedores();

  @override
  State<_TabProveedores> createState() => _TabProveedoresState();
}

class _TabProveedoresState extends State<_TabProveedores> {
  List<ProveedorFullApi> _proveedores = [];
  Map<int, MetricasApi> _metricas = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    final res = await Future.wait([
      ComprasService.proveedores(),
      ComprasService.metricas(),
    ]);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      final p = res[0];
      final m = res[1];
      if (p is InvExito<List<ProveedorFullApi>>) {
        _proveedores = p.datos;
        _error = null;
      } else if (p is InvError<List<ProveedorFullApi>> && !silencioso) {
        _error = p.mensaje;
      }
      if (m is InvExito<List<MetricasApi>>) {
        _metricas = {for (final x in m.datos) x.proveedorId: x};
      }
    });
  }

  Future<void> _nuevo() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NuevoProveedorSheet(),
    );
    if (creado == true && mounted) {
      _avisar(context, 'Proveedor agregado');
      _cargar(silencioso: true);
    }
  }

  Future<void> _detalle(ProveedorFullApi p) async {
    final cambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetalleProveedorSheet(proveedor: p, metricas: _metricas[p.id]),
    );
    if (cambio == true && mounted) _cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        backgroundColor: AppColors.terracota,
        foregroundColor: AppColors.crema,
        icon: const Icon(Icons.add, size: 20),
        label: Text('Nuevo proveedor',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _cargar(silencioso: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MensajeError(mensaje: _error!, onReintentar: _cargar)
            else if (_proveedores.isEmpty)
              const _Vacio('Aún no hay proveedores.\nAgrega el primero con "Nuevo proveedor".')
            else
              ..._proveedores.map((p) {
                final m = _metricas[p.id];
                return GestureDetector(
                  onTap: () => _detalle(p),
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cremaOscura,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.storefront_outlined,
                              color: AppColors.terracota, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nombre,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cafeOscuro)),
                              const SizedBox(height: 3),
                              Text(
                                [p.contacto, p.telefono]
                                    .whereType<String>()
                                    .where((s) => s.isNotEmpty)
                                    .join(' · ')
                                    .ifEmpty('Sin datos de contacto'),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.cafeMedio),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (m == null || m.totalOrdenes == 0)
                                  ? 'Sin órdenes'
                                  : '${fmtNum(m.cumplimientoPct)}%',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cafeOscuro),
                            ),
                            Text(
                              (m == null || m.totalOrdenes == 0) ? '' : 'cumplimiento',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.cafeMedio),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String otro) => isEmpty ? otro : this;
}

class _DetalleProveedorSheet extends StatefulWidget {
  final ProveedorFullApi proveedor;
  final MetricasApi? metricas;
  const _DetalleProveedorSheet({required this.proveedor, this.metricas});

  @override
  State<_DetalleProveedorSheet> createState() => _DetalleProveedorSheetState();
}

class _DetalleProveedorSheetState extends State<_DetalleProveedorSheet> {
  bool _trabajando = false;

  Future<void> _desactivar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Desactivar proveedor', style: AppTheme.titulo(size: 18)),
        content: Text(
          '${widget.proveedor.nombre} dejará de aparecer en la lista y no podrás crearle órdenes nuevas.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, desactivar',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _trabajando = true);
    final r = await ComprasService.desactivarProveedor(widget.proveedor.id);
    if (!mounted) return;
    setState(() => _trabajando = false);
    if (r is InvError<ProveedorFullApi>) {
      _avisar(context, r.mensaje, error: true);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proveedor;
    final m = widget.metricas;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _manijaSheet(),
          const SizedBox(height: 16),
          Text(p.nombre, style: AppTheme.titulo(size: 22)),
          const SizedBox(height: 14),
          _Fila('Contacto', p.contacto ?? '—'),
          _Fila('Teléfono', p.telefono ?? '—'),
          _Fila('Correo', p.email ?? '—'),
          _Fila('Productos que ofrece', p.productosOfrecidos ?? '—'),
          _Fila('Condiciones comerciales', p.condiciones ?? '—'),
          const SizedBox(height: 16),
          Text('CUMPLIMIENTO', style: AppTheme.etiqueta()),
          const SizedBox(height: 8),
          if (m == null || m.totalOrdenes == 0)
            Text('Todavía no tiene órdenes de compra.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio))
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borde),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _Dato('${fmtNum(m.cumplimientoPct)}%', 'Cumplimiento')),
                      Expanded(
                        child: _Dato(
                          m.puntualidadPct == null ? '—' : '${fmtNum(m.puntualidadPct!)}%',
                          'Puntualidad',
                        ),
                      ),
                      Expanded(
                        child: _Dato(
                          m.diasPromedio == null
                              ? '—'
                              : (m.diasPromedio! < 1 ? '< 1' : fmtNum(m.diasPromedio!)),
                          'Días promedio',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${m.totalOrdenes} órdenes: ${m.completas} completas · '
                    '${m.parciales} parciales · ${m.pendientes} pendientes · '
                    '${m.canceladas} canceladas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _trabajando ? null : _desactivar,
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Desactivar proveedor'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.terracotaOscuro,
              side: BorderSide(color: AppColors.terracota.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String titulo;
  const _Dato(this.valor, this.titulo);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro)),
        const SizedBox(height: 2),
        Text(titulo,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.cafeMedio)),
      ],
    );
  }
}

class _NuevoProveedorSheet extends StatefulWidget {
  const _NuevoProveedorSheet();

  @override
  State<_NuevoProveedorSheet> createState() => _NuevoProveedorSheetState();
}

class _NuevoProveedorSheetState extends State<_NuevoProveedorSheet> {
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _productos = TextEditingController();
  final _condiciones = TextEditingController();
  String? _error;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _telefono.dispose();
    _email.dispose();
    _productos.dispose();
    _condiciones.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().length < 2) {
      setState(() => _error = 'Escribe el nombre del proveedor');
      return;
    }
    setState(() {
      _error = null;
      _guardando = true;
    });
    final r = await ComprasService.crearProveedor(
      nombre: _nombre.text,
      contacto: _contacto.text,
      telefono: _telefono.text,
      email: _email.text,
      productosOfrecidos: _productos.text,
      condiciones: _condiciones.text,
    );
    if (!mounted) return;
    if (r is InvError<ProveedorFullApi>) {
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
            _manijaSheet(),
            const SizedBox(height: 20),
            Text('Nuevo proveedor', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 18),
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'NOMBRE'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contacto,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'PERSONA DE CONTACTO'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _telefono,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'TELÉFONO'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'CORREO'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productos,
              decoration: const InputDecoration(
                labelText: 'PRODUCTOS QUE OFRECE',
                hintText: 'Ej. Harinas, azúcar',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _condiciones,
              decoration: const InputDecoration(
                labelText: 'CONDICIONES COMERCIALES',
                hintText: 'Ej. Pago a 30 días, entrega en 48 h',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.terracotaOscuro,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'GUARDANDO…' : 'AGREGAR PROVEEDOR'),
            ),
          ],
        ),
      ),
    );
  }
}
