import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/inventario_service.dart' show InvExito, InvError;
import '../services/pagos_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../utils/formato.dart';

IconData _iconoMetodo(String m) => switch (m) {
      'tarjeta' => Icons.credit_card,
      'billetera' => Icons.account_balance_wallet_outlined,
      'transferencia' => Icons.account_balance,
      _ => Icons.payments_outlined,
    };

/// Abre el detalle de una factura propia (también lo usa el botón de pagar).
Future<void> abrirFacturaSheet(BuildContext context, int facturaId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _DetalleFacturaClienteSheet(id: facturaId),
  );
}

class ClienteFacturasScreen extends StatefulWidget {
  const ClienteFacturasScreen({super.key});

  @override
  State<ClienteFacturasScreen> createState() => _ClienteFacturasScreenState();
}

class _ClienteFacturasScreenState extends State<ClienteFacturasScreen> {
  static const _periodos = ['Este mes', 'Mes pasado', 'Todo'];
  String _periodo = 'Este mes';

  List<FacturaApi> _facturas = [];
  bool _cargando = true;
  String? _error;

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
    final r = await PagosService.misFacturas();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<FacturaApi>>) _facturas = r.datos;
      if (r is InvError<List<FacturaApi>>) _error = r.mensaje;
    });
  }

  List<FacturaApi> get _filtradas {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final inicioMesPasado = DateTime(ahora.year, ahora.month - 1, 1);
    return _facturas.where((f) {
      final d = f.pagadoEn;
      if (d == null) return _periodo == 'Todo';
      switch (_periodo) {
        case 'Este mes':
          return !d.isBefore(inicioMes);
        case 'Mes pasado':
          return !d.isBefore(inicioMesPasado) && d.isBefore(inicioMes);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    final validas = lista.where((f) => !f.anulada).toList();
    final total = validas.fold<double>(0, (s, f) => s + f.total);

    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cafeOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppStrings.t(context, 'mis_facturas'),
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.terracota),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.terracota))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_off,
                            size: 44, color: AppColors.cafeMedio),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppColors.cafeOscuro)),
                        TextButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ]),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.terracota,
                    onRefresh: _cargar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Text(AppStrings.t(context, 'tus_recibos').toUpperCase(),
                            style: AppTheme.etiqueta()),
                        const SizedBox(height: 4),
                        Text(AppStrings.t(context, 'historial_compras'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio)),
                        const SizedBox(height: 20),
                        _resumen(total, validas.length),
                        const SizedBox(height: 20),
                        _selector(),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppStrings.t(context, 'tus_facturas'),
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cafeOscuro)),
                            Text('${lista.length}',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: AppColors.cafeMedio)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (lista.isEmpty)
                          const _SinFacturas()
                        else
                          ...lista.map((f) => _TarjetaFacturaCliente(
                                factura: f,
                                onTap: () => abrirFacturaSheet(context, f.id),
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _resumen(double total, int cantidad) {
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('GASTO · $_periodo'.toUpperCase(),
              style: AppTheme.etiqueta(color: AppColors.cremaOscura)),
          const Icon(Icons.receipt_long,
              color: AppColors.cremaOscura, size: 18),
        ]),
        const SizedBox(height: 10),
        Text(moneda(total),
            style: GoogleFonts.playfairDisplay(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: AppColors.crema,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
            cantidad == 0
                ? 'Sin facturas en este periodo'
                : '$cantidad ${cantidad == 1 ? 'factura' : 'facturas'} · promedio ${moneda(total / cantidad)}',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.cremaOscura)),
      ]),
    );
  }

  Widget _selector() {
    return Row(
      children: List.generate(_periodos.length, (i) {
        final p = _periodos[i];
        final activo = p == _periodo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _periodo = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < _periodos.length - 1 ? 8 : 0),
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
}

class _SinFacturas extends StatelessWidget {
  const _SinFacturas();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.cafeMedio),
          const SizedBox(height: 12),
          Text('Aún no tienes facturas',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cafeOscuro)),
          const SizedBox(height: 4),
          Text('Cuando pagues un pedido, tu factura aparecerá aquí.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.cafeMedio)),
        ]),
      );
}

class _TarjetaFacturaCliente extends StatelessWidget {
  final FacturaApi factura;
  final VoidCallback onTap;
  const _TarjetaFacturaCliente({required this.factura, required this.onTap});

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
              color: AppColors.terracota.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconoMetodo(f.metodo),
                size: 20, color: AppColors.terracota),
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
                    color:
                        f.anulada ? AppColors.cafeMedio : AppColors.cafeOscuro,
                    decoration: f.anulada ? TextDecoration.lineThrough : null)),
            if (f.anulada)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.alertaFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Anulada',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.alertaTexto)),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _DetalleFacturaClienteSheet extends StatefulWidget {
  final int id;
  const _DetalleFacturaClienteSheet({required this.id});

  @override
  State<_DetalleFacturaClienteSheet> createState() =>
      _DetalleFacturaClienteSheetState();
}

class _DetalleFacturaClienteSheetState
    extends State<_DetalleFacturaClienteSheet> {
  FacturaApi? _f;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    final f = _f;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
          : SingleChildScrollView(
              child: Column(
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
                      child: Text('Anulada: ${f.anuladaMotivo ?? '—'}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.alertaTexto)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
