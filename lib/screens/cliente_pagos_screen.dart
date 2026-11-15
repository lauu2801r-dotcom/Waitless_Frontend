import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/inventario_service.dart' show InvExito, InvError;
import '../services/pagos_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// Historial de intentos de pago del cliente: aprobados y rechazados.
class ClientePagosScreen extends StatefulWidget {
  const ClientePagosScreen({super.key});

  @override
  State<ClientePagosScreen> createState() => _ClientePagosScreenState();
}

class _ClientePagosScreenState extends State<ClientePagosScreen> {
  List<PagoApi> _pagos = [];
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
    final r = await PagosService.misPagos();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<PagoApi>>) _pagos = r.datos;
      if (r is InvError<List<PagoApi>>) _error = r.mensaje;
    });
  }

  Widget _tarjeta(PagoApi p) {
    final ok = p.aprobado;
    final color = ok ? AppColors.exitoTexto : AppColors.alertaTexto;
    final fondo = ok ? AppColors.exitoFondo : AppColors.alertaFondo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cremaOscura),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
          child: Icon(ok ? Icons.check : Icons.close, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${moneda(p.monto)} · ${nombreMetodo(p.metodo)}',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro)),
            const SizedBox(height: 2),
            Text('Pedido #${p.pedidoId} · ${fechaHora(p.creadoEn)}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
            if (p.referencia != null && p.referencia!.isNotEmpty)
              Text('Ref. ${p.referencia}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
            if (!ok && (p.motivoRechazo ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(p.motivoRechazo!,
                    style: GoogleFonts.inter(fontSize: 12, color: color)),
              ),
            if (ok && p.factura != null)
              Text('Factura ${p.factura!.numero}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration:
              BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
          child: Text(ok ? 'Aprobado' : 'Rechazado',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cafeOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Historial de pagos',
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
                            style: GoogleFonts.inter(color: AppColors.cafeOscuro)),
                        TextButton(
                            onPressed: _cargar, child: const Text('Reintentar')),
                      ]),
                    ),
                  )
                : _pagos.isEmpty
                    ? Center(
                        child: Text('Aún no tienes intentos de pago.',
                            style: GoogleFonts.inter(color: AppColors.cafeMedio)),
                      )
                    : RefreshIndicator(
                        color: AppColors.terracota,
                        onRefresh: _cargar,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          children: _pagos.map(_tarjeta).toList(),
                        ),
                      ),
      ),
    );
  }
}
