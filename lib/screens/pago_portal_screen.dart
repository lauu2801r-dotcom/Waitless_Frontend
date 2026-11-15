import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_config.dart';
import '../theme/app_theme.dart';

/// Resultado que devuelve el portal de pago (WaitLess Pay) al terminar.
class ResultadoPortal {
  final String estado; // aprobado | rechazado | cancelado
  final String metodo; // tarjeta | transferencia | billetera | '' (si no se eligió)
  final String referencia;
  final String motivoTexto; // por qué se rechazó (si aplica)

  const ResultadoPortal({
    required this.estado,
    required this.metodo,
    required this.referencia,
    this.motivoTexto = '',
  });

  bool get aprobado => estado == 'aprobado';
  bool get cancelado => estado == 'cancelado';

  /// El portal usa credit | debit | pse; el backend usa tarjeta | transferencia.
  static String _aMetodoApi(String m) => switch (m) {
        'credit' || 'debit' || 'card' => 'tarjeta',
        'pse' || 'bank' => 'transferencia',
        _ => '',
      };

  factory ResultadoPortal.desdeJson(String texto) {
    final j = jsonDecode(texto) as Map<String, dynamic>;
    return ResultadoPortal(
      estado: (j['estado'] ?? 'cancelado').toString(),
      metodo: _aMetodoApi((j['metodo'] ?? '').toString()),
      referencia: (j['ref'] ?? '').toString(),
      motivoTexto: (j['motivo_texto'] ?? '').toString(),
    );
  }
}

/// Abre el portal de pago simulado (WaitLess Pay) dentro de la app.
/// Devuelve un [ResultadoPortal] con Navigator.pop (o null si se cierra sin resultado).
class PagoPortalScreen extends StatefulWidget {
  final double monto;
  final String restaurante;
  final String pedido; // referencia que se muestra en el portal
  final String tipo; // pedido | domicilio | reserva

  const PagoPortalScreen({
    super.key,
    required this.monto,
    required this.restaurante,
    required this.pedido,
    this.tipo = 'pedido',
  });

  @override
  State<PagoPortalScreen> createState() => _PagoPortalScreenState();
}

class _PagoPortalScreenState extends State<PagoPortalScreen> {
  late final WebViewController _controller;
  bool _cargando = true;
  bool _error = false;
  bool _cerrado = false;

  Uri get _url =>
      Uri.parse('${ApiConfig.baseUrl}/static/pago-simulado/index.html').replace(
        queryParameters: {
          'monto': widget.monto.round().toString(),
          'restaurante': widget.restaurante,
          'pedido': widget.pedido,
          'tipo': widget.tipo,
        },
      );

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.crema)
      ..addJavaScriptChannel(
        'WaitLessPay',
        onMessageReceived: (m) {
          try {
            _cerrar(ResultadoPortal.desdeJson(m.message));
          } catch (_) {
            _cerrar(null);
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _cargando = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _cargando = false);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) {
            if (mounted) {
              setState(() {
                _error = true;
                _cargando = false;
              });
            }
          }
        },
      ))
      ..loadRequest(_url);
  }

  void _cerrar(ResultadoPortal? r) {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    Navigator.of(context).pop(r);
  }

  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar el pago?'),
        content: const Text('No se hará ningún cobro.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir pagando')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar pago')),
        ],
      ),
    );
    if (salir == true) {
      _cerrar(const ResultadoPortal(
          estado: 'cancelado', metodo: '', referencia: ''));
    }
  }

  /// Botón "atrás": primero retrocede un paso dentro del portal; si ya está en la
  /// primera pantalla (o en el resultado), pregunta si se quiere cancelar el pago.
  Future<void> _atras() async {
    var manejado = false;
    try {
      final r = await _controller
          .runJavaScriptReturningResult('window.WL_atras ? window.WL_atras() : false');
      manejado = r.toString().toLowerCase() == 'true';
    } catch (_) {}
    if (!manejado) await _confirmarSalida();
  }

  void _reintentar() {
    setState(() {
      _error = false;
      _cargando = true;
    });
    _controller.loadRequest(_url);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _atras();
      },
      child: Scaffold(
        backgroundColor: AppColors.crema,
        appBar: AppBar(
          backgroundColor: AppColors.crema,
          elevation: 0,
          foregroundColor: AppColors.cafeOscuro,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
            onPressed: _atras,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar pago',
              onPressed: _confirmarSalida,
            ),
          ],
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 18),
            const SizedBox(width: 6),
            Text('Pago seguro',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          centerTitle: true,
        ),
        body: Stack(children: [
          if (!_error) WebViewWidget(controller: _controller),
          if (_cargando && !_error)
            Container(
              color: AppColors.crema,
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: AppColors.terracota),
                const SizedBox(height: 16),
                Text('Conectando con WaitLess Pay…',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.cafeMedio)),
                const SizedBox(height: 4),
                Text('La primera vez puede tardar un momento.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.cafeMedio)),
              ]),
            ),
          if (_error)
            Container(
              color: AppColors.crema,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 44, color: AppColors.cafeMedio),
                const SizedBox(height: 14),
                Text('No pudimos abrir el portal de pago',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 6),
                Text('Revisa tu conexión e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.cafeMedio)),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _reintentar,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.terracota),
                  child: const Text('Reintentar'),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
