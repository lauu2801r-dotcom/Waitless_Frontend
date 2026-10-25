import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/cliente_facturas_screen.dart';
import '../services/inventario_service.dart' show InvExito, InvError;
import '../services/pagos_service.dart';
import '../services/pedido_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// Tarjeta que aparece en el detalle del pedido del cliente:
///  - si el pedido está listo/entregado y sin pagar → botón "Pagar".
///  - si ya está pagado → muestra la factura.
class PagarPedido extends StatefulWidget {
  final PedidoApi pedido;
  const PagarPedido({super.key, required this.pedido});

  @override
  State<PagarPedido> createState() => _PagarPedidoState();
}

class _PagarPedidoState extends State<PagarPedido> {
  bool _cargando = true;
  FacturaApi? _factura; // factura pagada (si ya se pagó)

  bool get _puedePagar =>
      widget.pedido.estado == EstadoPedidoApi.listo ||
      widget.pedido.estado == EstadoPedidoApi.entregado;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    final r = await PagosService.pagosDePedido(widget.pedido.id);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<PagoApi>>) {
        for (final p in r.datos) {
          if (p.aprobado && p.factura != null && !p.factura!.anulada) {
            _factura = p.factura;
            break;
          }
        }
      }
    });
  }

  Future<void> _pagar() async {
    final factura = await showModalBottomSheet<FacturaApi>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PagarSheet(pedido: widget.pedido),
    );
    if (factura != null && mounted) {
      setState(() => _factura = factura);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pago aprobado · ${factura.numero}'),
        backgroundColor: AppColors.oliva,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const SizedBox.shrink();

    final f = _factura;
    if (f != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.exitoFondo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle, color: AppColors.exitoTexto),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Pedido pagado · ${f.numero} · ${moneda(f.total)}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.exitoTexto)),
          ),
          TextButton(
            onPressed: () => abrirFacturaSheet(context, f.id),
            child: const Text('Ver factura'),
          ),
        ]),
      );
    }

    if (!_puedePagar) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _pagar,
          icon: const Icon(Icons.payment),
          label: Text('Pagar ${widget.pedido.totalFormateado}'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terracota,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hoja de pago ─────────────────────────
class _PagarSheet extends StatefulWidget {
  final PedidoApi pedido;
  const _PagarSheet({required this.pedido});

  @override
  State<_PagarSheet> createState() => _PagarSheetState();
}

class _PagarSheetState extends State<_PagarSheet> {
  // El cliente paga en línea: el efectivo lo cobra el personal.
  static const _metodos = ['tarjeta', 'billetera', 'transferencia'];
  static const _impuestoPct = 8;

  final _propinaCtrl = TextEditingController();
  String _metodo = 'tarjeta';
  bool _simularRechazo = false;
  bool _procesando = false;
  String? _error;

  @override
  void dispose() {
    _propinaCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => widget.pedido.total;
  double get _impuesto => (_subtotal * _impuestoPct / 100).roundToDouble();
  double get _propina => double.tryParse(_propinaCtrl.text.trim()) ?? 0;
  double get _total => _subtotal + _impuesto + _propina;

  void _propinaSugerida(int pct) {
    setState(() => _propinaCtrl.text = (_subtotal * pct / 100).round().toString());
  }

  Future<void> _confirmar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    final r = await PagosService.pagar(
      pedidoId: widget.pedido.id,
      metodo: _metodo,
      propina: _propina,
      simularRechazo: _simularRechazo,
    );
    if (!mounted) return;
    if (r is InvExito<PagoApi>) {
      if (r.datos.aprobado && r.datos.factura != null) {
        Navigator.pop(context, r.datos.factura);
        return;
      }
      setState(() {
        _procesando = false;
        _error = '${r.datos.motivoRechazo ?? 'Pago rechazado'}. Intenta de nuevo o cambia el método.';
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pagar pedido #${widget.pedido.id}',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro)),
            const SizedBox(height: 14),
            _fila('Subtotal', moneda(_subtotal)),
            _fila('Impuesto al consumo ($_impuestoPct%)', moneda(_impuesto)),
            _fila('Propina', moneda(_propina)),
            _fila('Total', moneda(_total), fuerte: true),
            const SizedBox(height: 16),
            Text('MÉTODO DE PAGO', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _metodos.map((m) {
                final activo = m == _metodo;
                return ChoiceChip(
                  selected: activo,
                  onSelected:
                      _procesando ? null : (_) => setState(() => _metodo = m),
                  label: Text(nombreMetodo(m)),
                  selectedColor: AppColors.terracota,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: activo ? AppColors.crema : AppColors.cafeOscuro),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text('PROPINA', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ActionChip(label: const Text('Sin propina'), onPressed: () => setState(() => _propinaCtrl.clear())),
              ActionChip(label: const Text('8%'), onPressed: () => _propinaSugerida(8)),
              ActionChip(label: const Text('10%'), onPressed: () => _propinaSugerida(10)),
              ActionChip(label: const Text('12%'), onPressed: () => _propinaSugerida(12)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _propinaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'Otro valor de propina', prefixText: '\$ '),
            ),
            // Solo visible al correr la app en modo desarrollo (para demostrar el reintento).
            if (kDebugMode)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _simularRechazo,
                onChanged: _procesando
                    ? null
                    : (v) => setState(() => _simularRechazo = v),
                activeThumbColor: AppColors.terracota,
                title: Text('Simular rechazo (solo pruebas)',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.cafeMedio)),
              ),
            const SizedBox(height: 6),
            Text(
              'Pago simulado: no se guardan datos de tarjeta. Al aprobarse recibirás la factura en tu correo.',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertaFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.alertaTexto)),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _procesando ? null : _confirmar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracota,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_procesando
                    ? 'Procesando…'
                    : (_error != null
                        ? 'Reintentar pago'
                        : 'Pagar ${moneda(_total)}')),
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
