import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/pagos_service.dart';
import '../../services/inventario_service.dart' show InvExito, InvError;
import '../../services/tiempo_real_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';

IconData _iconoMetodo(String m) => switch (m) {
      'tarjeta' => Icons.credit_card,
      'billetera' => Icons.account_balance_wallet_outlined,
      'transferencia' => Icons.account_balance,
      _ => Icons.payments_outlined,
    };

Color _colorMetodo(String m) => switch (m) {
      'tarjeta' => AppColors.terracota,
      'billetera' => AppColors.cafeMedio,
      'transferencia' => AppColors.cafeOscuro,
      _ => AppColors.oliva,
    };

class AdminFacturacionScreen extends StatefulWidget {
  const AdminFacturacionScreen({super.key});

  @override
  State<AdminFacturacionScreen> createState() => _AdminFacturacionScreenState();
}

class _AdminFacturacionScreenState extends State<AdminFacturacionScreen> {
  static const _periodos = {
    'Hoy': 'hoy',
    'Semana': 'semana',
    'Mes': 'mes',
    'Año': 'anio',
  };
  String _periodo = 'Hoy';

  ResumenApi? _resumen;
  List<FacturaApi> _facturas = [];
  List<PorCobrarApi> _porCobrar = [];
  bool _cargando = true;
  String? _error;

  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _cargar();
    // Tiempo real: cuando alguien paga o se anula una factura, todo se actualiza.
    _tiempoReal = TiempoRealConexion('dashboard')..conectar();
    _suscripcion = _tiempoReal.eventos.listen((e) {
      final tipo = e['tipo'] as String? ?? '';
      if (tipo == 'pago_aprobado' ||
          tipo == 'factura_anulada' ||
          tipo == 'pedido_estado') {
        _cargar(silencioso: true);
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
    final res = await Future.wait([
      PagosService.resumen(_periodos[_periodo]!),
      PagosService.facturas(),
      PagosService.porCobrar(),
    ]);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      final r = res[0], f = res[1], p = res[2];
      if (r is InvExito<ResumenApi>) _resumen = r.datos;
      if (f is InvExito<List<FacturaApi>>) _facturas = f.datos;
      if (p is InvExito<List<PorCobrarApi>>) _porCobrar = p.datos;
      if (!silencioso) {
        if (r is InvError<ResumenApi>) {
          _error = r.mensaje;
        } else if (f is InvError<List<FacturaApi>>) {
          _error = f.mensaje;
        }
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.terracotaOscuro : AppColors.oliva,
    ));
  }

  Future<void> _abrirSheet(Widget Function(BuildContext) builder) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
    if (r != null && mounted) {
      _snack(r);
      _cargar(silencioso: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumen;
    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cafeOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Facturación',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.terracota),
            tooltip: 'Actualizar',
            onPressed: () => _cargar(),
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando && r == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.terracota))
            : _error != null && r == null
                ? _Error(mensaje: _error!, onReintentar: _cargar)
                : RefreshIndicator(
                    color: AppColors.terracota,
                    onRefresh: () => _cargar(silencioso: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Text('INGRESOS Y FACTURAS', style: AppTheme.etiqueta()),
                        const SizedBox(height: 4),
                        Text('Control financiero del restaurante',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio)),
                        const SizedBox(height: 20),
                        if (r != null) _tarjetaTotal(r),
                        const SizedBox(height: 20),
                        _selectorPeriodo(),
                        const SizedBox(height: 22),
                        _seccionPorCobrar(),
                        if (r != null) _distribucion(r),
                        _listaFacturas(),
                        const SizedBox(height: 8),
                        Text(
                          'Impuesto al consumo: 8 % · Los pagos se procesan con una pasarela simulada (no se guardan datos de tarjeta).',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.cafeMedio),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Tarjeta principal ──
  Widget _tarjetaTotal(ResumenApi r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cafeOscuro, AppColors.terracotaOscuro],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INGRESOS · ${_periodo.toUpperCase()}',
              style: AppTheme.etiqueta(color: AppColors.cremaOscura)),
          const SizedBox(height: 10),
          Text(moneda(r.totalVentas),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppColors.crema,
                  letterSpacing: -0.5)),
          const SizedBox(height: 16),
          Row(children: [
            _mini('FACTURAS', '${r.totalFacturas}'),
            _separador(),
            _mini('TICKET PROM.', moneda(r.ticketPromedio)),
            _separador(),
            _mini('POR COBRAR', '${r.porCobrar}'),
          ]),
        ],
      ),
    );
  }

  Widget _mini(String label, String valor) => Expanded(
        child: Column(children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  letterSpacing: 1,
                  color: AppColors.cremaOscura)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.crema)),
          ),
        ]),
      );

  Widget _separador() => Container(
      width: 1,
      height: 28,
      color: AppColors.cremaOscura.withValues(alpha: 0.3));

  Widget _selectorPeriodo() {
    final claves = _periodos.keys.toList();
    return Row(
      children: List.generate(claves.length, (i) {
        final p = claves[i];
        final activo = p == _periodo;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _periodo = p);
              _cargar(silencioso: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < claves.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: activo ? AppColors.terracota : AppColors.superficie,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: activo ? AppColors.terracota : AppColors.borde),
              ),
              child: Text(p,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: activo ? AppColors.crema : AppColors.cafeOscuro)),
            ),
          ),
        );
      }),
    );
  }

  // ── Pedidos por cobrar ──
  Widget _seccionPorCobrar() {
    if (_porCobrar.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('POR COBRAR', style: AppTheme.etiqueta()),
      const SizedBox(height: 12),
      ..._porCobrar.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: ListTile(
              onTap: () => _abrirSheet((_) => _CobrarSheet(pedido: p)),
              leading: const CircleAvatar(
                backgroundColor: AppColors.alertaFondo,
                child: Icon(Icons.point_of_sale, color: AppColors.terracota),
              ),
              title: Text('${p.concepto} · Pedido #${p.pedidoId}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro)),
              subtitle: Text('Total con impuesto ${moneda(p.totalEstimado)}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.cafeMedio)),
              trailing: Text('Cobrar',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracota)),
            ),
          )),
      const SizedBox(height: 14),
    ]);
  }

  // ── Distribución por método ──
  Widget _distribucion(ResumenApi r) {
    final total = r.totalVentas;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Distribución de pagos · $_periodo',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
        const SizedBox(height: 14),
        if (total <= 0)
          Text('Aún no hay pagos en este periodo.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.cafeMedio))
        else
          ...metodosPago.map((m) {
            final monto = r.totalPorMetodo[m] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BarraPago(
                label: nombreMetodo(m),
                icono: _iconoMetodo(m),
                porcentaje: monto / total,
                monto: moneda(monto),
                color: _colorMetodo(m),
              ),
            );
          }),
      ]),
    );
  }

  // ── Lista de facturas ──
  Widget _listaFacturas() {
    final desde = _desdePeriodo();
    final lista = _facturas
        .where((f) => f.pagadoEn == null || !f.pagadoEn!.isBefore(desde))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Facturas · $_periodo',
          style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro)),
      const SizedBox(height: 12),
      if (lista.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text('No hay facturas en este periodo.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.cafeMedio)),
          ),
        ),
      ...lista.map((f) => _TarjetaFactura(
            factura: f,
            onTap: () => _abrirSheet((_) => _DetalleFacturaSheet(id: f.id)),
          )),
    ]);
  }

  /// Inicio del periodo en hora local (la app y el servidor usan el mismo cálculo).
  DateTime _desdePeriodo() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    switch (_periodos[_periodo]) {
      case 'semana':
        return hoy.subtract(const Duration(days: 6));
      case 'mes':
        return DateTime(ahora.year, ahora.month, 1);
      case 'anio':
        return DateTime(ahora.year, 1, 1);
      default:
        return hoy;
    }
  }
}

// ───────────────────────── Widgets pequeños ─────────────────────────
class _Error extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _Error({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.cafeMedio),
            const SizedBox(height: 12),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.cafeOscuro)),
            const SizedBox(height: 12),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ]),
        ),
      );
}

class _BarraPago extends StatelessWidget {
  final String label;
  final IconData icono;
  final double porcentaje;
  final String monto;
  final Color color;
  const _BarraPago({
    required this.label,
    required this.icono,
    required this.porcentaje,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeOscuro)),
        ),
        Text('${(porcentaje * 100).round()}% · $monto',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: porcentaje.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: AppColors.cremaOscura,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

class _TarjetaFactura extends StatelessWidget {
  final FacturaApi factura;
  final VoidCallback onTap;
  const _TarjetaFactura({required this.factura, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = factura;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _colorMetodo(f.metodo).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconoMetodo(f.metodo),
                size: 20, color: _colorMetodo(f.metodo)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${f.numero} · ${f.concepto}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro)),
              const SizedBox(height: 2),
              Text('${nombreMetodo(f.metodo)} · ${fechaHora(f.pagadoEn)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.cafeMedio)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(moneda(f.total),
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: f.anulada
                        ? AppColors.cafeMedio
                        : AppColors.cafeOscuro,
                    decoration:
                        f.anulada ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: f.anulada ? AppColors.alertaFondo : AppColors.exitoFondo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(f.anulada ? 'Anulada' : 'Pagada',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: f.anulada
                          ? AppColors.alertaTexto
                          : AppColors.exitoTexto)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── Detalle + anular ─────────────────────────
class _DetalleFacturaSheet extends StatefulWidget {
  final int id;
  const _DetalleFacturaSheet({required this.id});

  @override
  State<_DetalleFacturaSheet> createState() => _DetalleFacturaSheetState();
}

class _DetalleFacturaSheetState extends State<_DetalleFacturaSheet> {
  FacturaApi? _f;
  String? _error;
  bool _anulando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await PagosService.factura(widget.id);
    if (!mounted) return;
    setState(() {
      if (r is InvExito<FacturaApi>) _f = r.datos;
      if (r is InvError<FacturaApi>) _error = r.mensaje;
    });
  }

  Future<void> _anular() async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _MotivoDialog(),
    );
    if (motivo == null || !mounted) return;
    setState(() => _anulando = true);
    final r = await PagosService.anular(widget.id, motivo);
    if (!mounted) return;
    if (r is InvExito<FacturaApi>) {
      Navigator.pop(context, 'Factura ${r.datos.numero} anulada');
    } else if (r is InvError<FacturaApi>) {
      setState(() {
        _anulando = false;
        _error = r.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _f;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: f == null
            ? SizedBox(
                height: 160,
                child: Center(
                  child: _error != null
                      ? Text(_error!,
                          style: GoogleFonts.inter(color: AppColors.cafeOscuro))
                      : const CircularProgressIndicator(
                          color: AppColors.terracota),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(f.numero,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: f.anulada
                            ? AppColors.alertaFondo
                            : AppColors.exitoFondo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(f.anulada ? 'Anulada' : 'Pagada',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: f.anulada
                                  ? AppColors.alertaTexto
                                  : AppColors.exitoTexto)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      '${f.concepto} · Pedido #${f.pedidoId} · ${fechaHora(f.pagadoEn)}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.cafeMedio)),
                  if (f.clienteEmail != null)
                    Text(f.clienteEmail!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.cafeMedio)),
                  const SizedBox(height: 16),
                  ...f.items.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(
                            child: Text('${i.cantidad} × ${i.nombre}',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.cafeOscuro)),
                          ),
                          Text(moneda(i.subtotal),
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.cafeOscuro)),
                        ]),
                      )),
                  const Divider(height: 24),
                  _fila('Subtotal', moneda(f.subtotal)),
                  _fila('Impuesto (${fmtNum(f.impuestoPct)}%)',
                      moneda(f.impuesto)),
                  _fila('Propina', moneda(f.propina)),
                  _fila('Método', nombreMetodo(f.metodo)),
                  _fila('Total', moneda(f.total), fuerte: true),
                  if (f.anulada) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.alertaFondo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          'Motivo: ${f.anuladaMotivo ?? '—'}\nPor: ${f.anuladaPorEmail ?? '—'}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.alertaTexto)),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.terracotaOscuro)),
                  ],
                  if (!f.anulada) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _anulando ? null : _anular,
                        icon: const Icon(Icons.block, size: 18),
                        label: Text(_anulando ? 'Anulando…' : 'Anular factura'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.terracotaOscuro,
                          side: const BorderSide(
                              color: AppColors.terracotaOscuro),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _fila(String a, String b, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a,
              style: GoogleFonts.inter(
                  fontSize: fuerte ? 15 : 13,
                  fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.cafeOscuro)),
          Text(b,
              style: GoogleFonts.inter(
                  fontSize: fuerte ? 15 : 13,
                  fontWeight: fuerte ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.cafeOscuro)),
        ]),
      );
}

class _MotivoDialog extends StatefulWidget {
  const _MotivoDialog();

  @override
  State<_MotivoDialog> createState() => _MotivoDialogState();
}

class _MotivoDialogState extends State<_MotivoDialog> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.crema,
      title: Text('Anular factura',
          style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
            labelText: 'Motivo de la anulación', errorText: _err),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            final t = _ctrl.text.trim();
            if (t.length < 3) {
              setState(() => _err = 'Escribe el motivo');
              return;
            }
            Navigator.pop(context, t);
          },
          child: const Text('Anular'),
        ),
      ],
    );
  }
}

// ───────────────────────── Cobrar un pedido ─────────────────────────
class _CobrarSheet extends StatefulWidget {
  final PorCobrarApi pedido;
  const _CobrarSheet({required this.pedido});

  @override
  State<_CobrarSheet> createState() => _CobrarSheetState();
}

class _CobrarSheetState extends State<_CobrarSheet> {
  final _propinaCtrl = TextEditingController();
  String _metodo = 'efectivo';
  bool _simularRechazo = false;
  bool _procesando = false;
  String? _error;

  @override
  void dispose() {
    _propinaCtrl.dispose();
    super.dispose();
  }

  double get _propina => double.tryParse(_propinaCtrl.text.trim()) ?? 0;

  Future<void> _cobrar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    final r = await PagosService.pagar(
      pedidoId: widget.pedido.pedidoId,
      metodo: _metodo,
      propina: _propina,
      simularRechazo: _simularRechazo,
    );
    if (!mounted) return;
    if (r is InvExito<PagoApi>) {
      if (r.datos.aprobado) {
        Navigator.pop(context,
            'Pago aprobado · ${r.datos.factura?.numero ?? ''}');
        return;
      }
      setState(() {
        _procesando = false;
        _error = '${r.datos.motivoRechazo ?? 'Pago rechazado'}. Puedes reintentar.';
      });
    } else if (r is InvError<PagoApi>) {
      setState(() {
        _procesando = false;
        _error = r.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cobrar ${p.concepto}',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro)),
            Text('Pedido #${p.pedidoId}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.cafeMedio)),
            const SizedBox(height: 16),
            _fila('Subtotal', moneda(p.subtotal)),
            _fila('Impuesto (8%)', moneda(p.impuesto)),
            _fila('Propina', moneda(_propina)),
            _fila('Total a cobrar',
                moneda(p.totalEstimado + _propina),
                fuerte: true),
            const SizedBox(height: 16),
            Text('MÉTODO DE PAGO', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metodosPago.map((m) {
                final activo = m == _metodo;
                return ChoiceChip(
                  selected: activo,
                  onSelected: _procesando
                      ? null
                      : (_) => setState(() => _metodo = m),
                  avatar: Icon(_iconoMetodo(m),
                      size: 16,
                      color: activo ? AppColors.crema : _colorMetodo(m)),
                  label: Text(nombreMetodo(m)),
                  selectedColor: AppColors.terracota,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: activo ? AppColors.crema : AppColors.cafeOscuro),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _propinaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'Propina (opcional)', prefixText: '\$ '),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _simularRechazo,
              onChanged:
                  _procesando ? null : (v) => setState(() => _simularRechazo = v),
              activeThumbColor: AppColors.terracota,
              title: Text('Simular rechazo (solo pruebas)',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.cafeMedio)),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertaFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.alertaTexto)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : _cobrar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracota,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_procesando
                    ? 'Procesando…'
                    : (_error != null ? 'Reintentar pago' : 'Cobrar')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(String a, String b, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a,
              style: GoogleFonts.inter(
                  fontSize: fuerte ? 15 : 13,
                  fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.cafeOscuro)),
          Text(b,
              style: GoogleFonts.inter(
                  fontSize: fuerte ? 15 : 13,
                  fontWeight: fuerte ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.cafeOscuro)),
        ]),
      );
}
