import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminFacturacionScreen extends StatefulWidget {
  const AdminFacturacionScreen({super.key});

  @override
  State<AdminFacturacionScreen> createState() =>
      _AdminFacturacionScreenState();
}

class _AdminFacturacionScreenState extends State<AdminFacturacionScreen> {
  String _periodoActivo = 'Hoy';
  final List<String> _periodos = const ['Hoy', 'Semana', 'Mes', 'Año'];

  final List<_FacturaItem> _facturas = const [
    _FacturaItem(
      numero: 'F-001284',
      mesa: 'Mesa 7',
      total: 87500,
      metodo: 'Tarjeta',
      hora: '13:42',
      estado: _EstadoFactura.pagada,
    ),
    _FacturaItem(
      numero: 'F-001283',
      mesa: 'Mesa 3',
      total: 124000,
      metodo: 'Efectivo',
      hora: '13:18',
      estado: _EstadoFactura.pagada,
    ),
    _FacturaItem(
      numero: 'F-001282',
      mesa: 'Mesa 12',
      total: 56300,
      metodo: 'Transferencia',
      hora: '12:55',
      estado: _EstadoFactura.pendiente,
    ),
    _FacturaItem(
      numero: 'F-001281',
      mesa: 'Mesa 5',
      total: 198400,
      metodo: 'Tarjeta',
      hora: '12:40',
      estado: _EstadoFactura.pagada,
    ),
    _FacturaItem(
      numero: 'F-001280',
      mesa: 'Domicilio',
      total: 42700,
      metodo: 'Efectivo',
      hora: '12:12',
      estado: _EstadoFactura.anulada,
    ),
    _FacturaItem(
      numero: 'F-001279',
      mesa: 'Mesa 9',
      total: 78900,
      metodo: 'Tarjeta',
      hora: '11:48',
      estado: _EstadoFactura.pagada,
    ),
  ];

  // ── Resúmenes ──
  double get _totalDia => _facturas
      .where((f) => f.estado == _EstadoFactura.pagada)
      .fold<double>(0, (s, f) => s + f.total);

  int get _totalFacturas =>
      _facturas.where((f) => f.estado != _EstadoFactura.anulada).length;

  double get _ticketPromedio =>
      _totalFacturas > 0 ? _totalDia / _totalFacturas : 0;

  int get _pendientes =>
      _facturas.where((f) => f.estado == _EstadoFactura.pendiente).length;

  String _fmt(double n) => '\$${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

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
        title: Text(
          'Facturación',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.terracota,
            ),
            tooltip: 'Exportar',
            onPressed: () => _abrirExportar(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Subtítulo ──
              Text('INGRESOS Y FACTURAS', style: AppTheme.etiqueta()),
              const SizedBox(height: 4),
              Text(
                'Control financiero del restaurante',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjeta total destacada ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cafeOscuro,
                      AppColors.terracotaOscuro,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cafeOscuro.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INGRESOS · $_periodoActivo',
                          style: AppTheme.etiqueta(
                            color: AppColors.cremaOscura,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.oliva.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: AppColors.olivaSuave,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+12.4%',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.olivaSuave,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fmt(_totalDia),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crema,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'vs. ayer · ${_fmt(_totalDia * 0.88)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.cremaOscura,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetricaOscura(
                            label: 'FACTURAS',
                            valor: '$_totalFacturas',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.cremaOscura.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _MiniMetricaOscura(
                            label: 'TICKET PROM.',
                            valor: _fmt(_ticketPromedio),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: AppColors.cremaOscura.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _MiniMetricaOscura(
                            label: 'PENDIENTES',
                            valor: '$_pendientes',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Selector de periodo ──
              Row(
                children: List.generate(_periodos.length, (i) {
                  final p = _periodos[i];
                  final activo = p == _periodoActivo;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _periodoActivo = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: i < _periodos.length - 1 ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: activo
                              ? AppColors.terracota
                              : AppColors.superficie,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activo
                                ? AppColors.terracota
                                : AppColors.borde,
                          ),
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
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
                }),
              ),
              const SizedBox(height: 22),

              // ── Accesos rápidos ──
              Text('ACCESOS RÁPIDOS', style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AccesoRapido(
                      icono: Icons.add_card,
                      titulo: 'Nueva factura',
                      color: AppColors.terracota,
                      onTap: () => _abrirNuevaFactura(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccesoRapido(
                      icono: Icons.receipt_outlined,
                      titulo: 'Impuestos',
                      color: AppColors.oliva,
                      onTap: () => _abrirConfigImpuestos(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AccesoRapido(
                      icono: Icons.payments_outlined,
                      titulo: 'Pagos',
                      color: AppColors.cafeMedio,
                      onTap: () => _abrirMetodosPago(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Métodos de pago resumen ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Distribución de pagos',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro,
                          ),
                        ),
                        Text(
                          _periodoActivo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cafeMedio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _BarraPago(
                      label: 'Tarjeta',
                      icono: Icons.credit_card,
                      porcentaje: 0.58,
                      monto: _fmt(_totalDia * 0.58),
                      color: AppColors.terracota,
                    ),
                    const SizedBox(height: 10),
                    _BarraPago(
                      label: 'Efectivo',
                      icono: Icons.payments,
                      porcentaje: 0.27,
                      monto: _fmt(_totalDia * 0.27),
                      color: AppColors.oliva,
                    ),
                    const SizedBox(height: 10),
                    _BarraPago(
                      label: 'Transferencia',
                      icono: Icons.account_balance,
                      porcentaje: 0.15,
                      monto: _fmt(_totalDia * 0.15),
                      color: AppColors.cafeMedio,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Lista facturas recientes ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Facturas recientes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Ver todas',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.terracota,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._facturas.map((f) => _TarjetaFactura(
                    factura: f,
                    onTap: () => _abrirDetalleFactura(context, f),
                  )),

              const SizedBox(height: 24),

              // ── Configuración facturación ──
              Text('CONFIGURACIÓN', style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              _GrupoConfig(items: [
                _OpcionConfig(
                  icono: Icons.bolt_outlined,
                  titulo: 'Facturación electrónica',
                  subtitulo: 'DIAN · Activa',
                  estado: _EstadoConfig.activo,
                  onTap: () => _abrirFacturaElectronica(context),
                ),
                _OpcionConfig(
                  icono: Icons.percent,
                  titulo: 'Impuestos',
                  subtitulo: 'IVA 19% · INC 8%',
                  estado: _EstadoConfig.activo,
                  onTap: () => _abrirConfigImpuestos(context),
                ),
                _OpcionConfig(
                  icono: Icons.savings_outlined,
                  titulo: 'Propinas sugeridas',
                  subtitulo: '8% · 10% · 12%',
                  estado: _EstadoConfig.activo,
                  onTap: () => _abrirConfigPropinas(context),
                ),
                _OpcionConfig(
                  icono: Icons.credit_card,
                  titulo: 'Métodos de pago',
                  subtitulo: '3 activos',
                  estado: _EstadoConfig.activo,
                  onTap: () => _abrirMetodosPago(context),
                ),
                _OpcionConfig(
                  icono: Icons.email_outlined,
                  titulo: 'Envío automático',
                  subtitulo: 'Por correo al cliente',
                  estado: _EstadoConfig.inactivo,
                  onTap: () {},
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheets ───────────────────────────────────────────────
  void _abrirDetalleFactura(BuildContext context, _FacturaItem f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetalleFacturaSheet(factura: f),
    );
  }

  void _abrirNuevaFactura(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NuevaFacturaSheet(),
    );
  }

  void _abrirConfigImpuestos(BuildContext context) {
    _abrirSheetSimple(
      context,
      titulo: 'Impuestos',
      icono: Icons.percent,
      descripcion:
          'Define el IVA, INC y otros impuestos aplicados automáticamente a cada factura.',
    );
  }

  void _abrirConfigPropinas(BuildContext context) {
    _abrirSheetSimple(
      context,
      titulo: 'Propinas sugeridas',
      icono: Icons.savings_outlined,
      descripcion:
          'Configura los porcentajes de propina que verán los clientes al pagar.',
    );
  }

  void _abrirMetodosPago(BuildContext context) {
    _abrirSheetSimple(
      context,
      titulo: 'Métodos de pago',
      icono: Icons.credit_card,
      descripcion:
          'Habilita tarjeta, efectivo, transferencia y pasarelas digitales aceptadas.',
    );
  }

  void _abrirFacturaElectronica(BuildContext context) {
    _abrirSheetSimple(
      context,
      titulo: 'Facturación electrónica',
      icono: Icons.bolt_outlined,
      descripcion:
          'Conecta con la DIAN para emitir facturas electrónicas válidas legalmente.',
    );
  }

  void _abrirExportar(BuildContext context) {
    _abrirSheetSimple(
      context,
      titulo: 'Exportar facturación',
      icono: Icons.file_download_outlined,
      descripcion:
          'Descarga un reporte en PDF o Excel con todas las facturas del periodo seleccionado.',
    );
  }

  void _abrirSheetSimple(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required String descripcion,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icono, color: AppColors.terracota, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTheme.titulo(size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.cafeMedio,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELOS INTERNOS
// ─────────────────────────────────────────────────────────────
enum _EstadoFactura { pagada, pendiente, anulada }

extension on _EstadoFactura {
  Color get color {
    switch (this) {
      case _EstadoFactura.pagada:
        return AppColors.oliva;
      case _EstadoFactura.pendiente:
        return AppColors.terracotaOscuro;
      case _EstadoFactura.anulada:
        return AppColors.cafeMedio;
    }
  }

  String get etiqueta {
    switch (this) {
      case _EstadoFactura.pagada:
        return 'Pagada';
      case _EstadoFactura.pendiente:
        return 'Pendiente';
      case _EstadoFactura.anulada:
        return 'Anulada';
    }
  }
}

class _FacturaItem {
  final String numero;
  final String mesa;
  final double total;
  final String metodo;
  final String hora;
  final _EstadoFactura estado;

  const _FacturaItem({
    required this.numero,
    required this.mesa,
    required this.total,
    required this.metodo,
    required this.hora,
    required this.estado,
  });

  IconData get iconoMetodo {
    switch (metodo) {
      case 'Tarjeta':
        return Icons.credit_card;
      case 'Efectivo':
        return Icons.payments;
      case 'Transferencia':
        return Icons.account_balance;
      default:
        return Icons.attach_money;
    }
  }
}

enum _EstadoConfig { activo, inactivo }

class _OpcionConfig {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final _EstadoConfig estado;
  final VoidCallback onTap;

  _OpcionConfig({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.estado,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────
// MINI MÉTRICA OSCURA (sobre tarjeta cafe)
// ─────────────────────────────────────────────────────────────
class _MiniMetricaOscura extends StatelessWidget {
  final String label;
  final String valor;
  const _MiniMetricaOscura({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.crema,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.cremaOscura,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACCESO RÁPIDO
// ─────────────────────────────────────────────────────────────
class _AccesoRapido extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.icono,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BARRA DE PAGO
// ─────────────────────────────────────────────────────────────
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
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        monto,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(porcentaje * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.cafeMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: porcentaje,
                  minHeight: 5,
                  backgroundColor: AppColors.bordeSuave,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA FACTURA
// ─────────────────────────────────────────────────────────────
class _TarjetaFactura extends StatelessWidget {
  final _FacturaItem factura;
  final VoidCallback onTap;

  const _TarjetaFactura({required this.factura, required this.onTap});

  String _fmt(double n) => '\$${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  @override
  Widget build(BuildContext context) {
    final color = factura.estado.color;

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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(factura.iconoMetodo, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        factura.numero,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          factura.estado.etiqueta,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${factura.mesa} · ${factura.metodo} · ${factura.hora}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _fmt(factura.total),
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: factura.estado == _EstadoFactura.anulada
                    ? AppColors.cafeMedio
                    : AppColors.terracota,
                decoration: factura.estado == _EstadoFactura.anulada
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRUPO CONFIGURACIÓN
// ─────────────────────────────────────────────────────────────
class _GrupoConfig extends StatelessWidget {
  final List<_OpcionConfig> items;
  const _GrupoConfig({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final op = items[i];
          final ultimo = i == items.length - 1;
          final activo = op.estado == _EstadoConfig.activo;

          return InkWell(
            onTap: op.onTap,
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : ultimo
                    ? const BorderRadius.vertical(bottom: Radius.circular(14))
                    : BorderRadius.zero,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: ultimo
                      ? BorderSide.none
                      : const BorderSide(
                          color: AppColors.bordeSuave, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cremaOscura,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      op.icono,
                      color: AppColors.cafeOscuro,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op.titulo,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          op.subtitulo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cafeMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: activo
                          ? AppColors.olivaFondo
                          : AppColors.cremaOscura,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activo ? 'ACTIVO' : 'INACTIVO',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: activo ? AppColors.oliva : AppColors.cafeMedio,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.cafeMedio,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET DETALLE FACTURA
// ─────────────────────────────────────────────────────────────
class _DetalleFacturaSheet extends StatelessWidget {
  final _FacturaItem factura;
  const _DetalleFacturaSheet({required this.factura});

  String _fmt(double n) => '\$${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  @override
  Widget build(BuildContext context) {
    final subtotal = factura.total / 1.19;
    final iva = factura.total - subtotal;
    final color = factura.estado.color;

    return SingleChildScrollView(
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                factura.estado.etiqueta.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            factura.numero,
            textAlign: TextAlign.center,
            style: AppTheme.titulo(size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            '${factura.mesa} · ${factura.hora}',
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
                _FilaTotal(label: 'Subtotal', valor: _fmt(subtotal)),
                _FilaTotal(label: 'IVA 19%', valor: _fmt(iva)),
                const Divider(color: AppColors.bordeSuave, height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    Text(
                      _fmt(factura.total),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracota,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cremaOscura,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(factura.iconoMetodo,
                    color: AppColors.cafeOscuro, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Pagado con ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.cafeMedio,
                  ),
                ),
                Text(
                  factura.metodo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Compartir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cafeOscuro,
                    side: const BorderSide(color: AppColors.borde),
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
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Descargar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String label;
  final String valor;
  const _FilaTotal({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.cafeMedio,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.inter(
              fontSize: 14,
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
// SHEET NUEVA FACTURA
// ─────────────────────────────────────────────────────────────
class _NuevaFacturaSheet extends StatelessWidget {
  const _NuevaFacturaSheet();

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
            Text('Nueva factura', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 4),
            Text(
              'Genera una factura manual para un pedido o consumo.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.cafeMedio,
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'MESA O CLIENTE',
                hintText: 'Mesa 7 / Domicilio',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'CONCEPTO',
                hintText: 'Detalle del consumo',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'TOTAL (\$)',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'MÉTODO DE PAGO',
                hintText: 'Tarjeta / Efectivo / Transferencia',
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GENERAR FACTURA'),
            ),
          ],
        ),
      ),
    );
  }
}
