import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';

class ClienteFacturasScreen extends StatefulWidget {
  const ClienteFacturasScreen({super.key});

  @override
  State<ClienteFacturasScreen> createState() => _ClienteFacturasScreenState();
}

class _ClienteFacturasScreenState extends State<ClienteFacturasScreen> {
  String _periodoActivo = 'Este mes';
  final List<String> _periodos = const ['Este mes', 'Mes pasado', 'Todo'];

  final List<_FacturaCliente> _facturas = const [
    _FacturaCliente(
      numero: 'F-001284',
      restaurante: 'La Trattoria',
      ubicacion: 'Mesa 7',
      total: 87500,
      metodo: 'Visa ••• 4242',
      iconoMetodo: Icons.credit_card,
      fecha: 'Hoy · 13:42',
      items: [
        _LineaFactura(nombre: 'Pasta carbonara', cantidad: 2, precio: 28500),
        _LineaFactura(nombre: 'Limonada de coco', cantidad: 2, precio: 9500),
        _LineaFactura(nombre: 'Tiramisú casero', cantidad: 1, precio: 12000),
      ],
    ),
    _FacturaCliente(
      numero: 'F-001210',
      restaurante: 'Burger House',
      ubicacion: 'Domicilio',
      total: 54300,
      metodo: 'Efectivo',
      iconoMetodo: Icons.payments,
      fecha: 'Ayer · 20:15',
      items: [
        _LineaFactura(nombre: 'Burguer doble queso', cantidad: 1, precio: 32000),
        _LineaFactura(nombre: 'Papas crispy', cantidad: 1, precio: 12000),
        _LineaFactura(nombre: 'Coca-Cola', cantidad: 1, precio: 8000),
      ],
    ),
    _FacturaCliente(
      numero: 'F-001185',
      restaurante: 'Sushi Zen',
      ubicacion: 'Mesa 3',
      total: 142000,
      metodo: 'Mastercard ••• 8801',
      iconoMetodo: Icons.credit_card,
      fecha: '12 may · 19:48',
      items: [
        _LineaFactura(nombre: 'Combo sashimi 24p', cantidad: 1, precio: 89000),
        _LineaFactura(nombre: 'Roll California', cantidad: 1, precio: 32000),
        _LineaFactura(nombre: 'Té verde frío', cantidad: 2, precio: 10500),
      ],
    ),
    _FacturaCliente(
      numero: 'F-001142',
      restaurante: 'La Trattoria',
      ubicacion: 'Mesa 12',
      total: 68400,
      metodo: 'Transferencia',
      iconoMetodo: Icons.account_balance,
      fecha: '8 may · 14:20',
      items: [
        _LineaFactura(nombre: 'Risotto de hongos', cantidad: 1, precio: 32000),
        _LineaFactura(nombre: 'Vino copa tinto', cantidad: 2, precio: 14000),
        _LineaFactura(nombre: 'Bruschetta', cantidad: 1, precio: 8400),
      ],
    ),
    _FacturaCliente(
      numero: 'F-001098',
      restaurante: 'Café del Centro',
      ubicacion: 'Domicilio',
      total: 32500,
      metodo: 'Visa ••• 4242',
      iconoMetodo: Icons.credit_card,
      fecha: '3 may · 09:32',
      items: [
        _LineaFactura(nombre: 'Capuchino doble', cantidad: 2, precio: 9500),
        _LineaFactura(nombre: 'Croissant relleno', cantidad: 1, precio: 8500),
        _LineaFactura(nombre: 'Jugo natural', cantidad: 1, precio: 5000),
      ],
    ),
  ];

  double get _totalMes =>
      _facturas.fold<double>(0, (s, f) => s + f.total);

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
          AppStrings.t(context, 'mis_facturas'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.terracota),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t(context, 'tus_recibos').toUpperCase(),
                style: AppTheme.etiqueta(),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.t(context, 'historial_compras'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjeta resumen ──
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
                          'GASTO · $_periodoActivo'.toUpperCase(),
                          style: AppTheme.etiqueta(
                            color: AppColors.cremaOscura,
                          ),
                        ),
                        const Icon(
                          Icons.receipt_long,
                          color: AppColors.cremaOscura,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _fmt(_totalMes),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crema,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_facturas.length} facturas · promedio ${_fmt(_totalMes / _facturas.length)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.cremaOscura,
                      ),
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

              // ── Lista facturas ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t(context, 'tus_facturas'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  Text(
                    '${_facturas.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_facturas.isEmpty)
                const _SinFacturas()
              else
                ..._facturas.map((f) => _TarjetaFacturaCliente(
                      factura: f,
                      onTap: () => _abrirDetalle(context, f),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalle(BuildContext context, _FacturaCliente f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetalleFacturaClienteSheet(factura: f),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODELOS INTERNOS
// ─────────────────────────────────────────────────────────────
class _FacturaCliente {
  final String numero;
  final String restaurante;
  final String ubicacion;
  final double total;
  final String metodo;
  final IconData iconoMetodo;
  final String fecha;
  final List<_LineaFactura> items;

  const _FacturaCliente({
    required this.numero,
    required this.restaurante,
    required this.ubicacion,
    required this.total,
    required this.metodo,
    required this.iconoMetodo,
    required this.fecha,
    required this.items,
  });
}

class _LineaFactura {
  final String nombre;
  final int cantidad;
  final double precio;
  const _LineaFactura({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });

  double get subtotal => precio * cantidad;
}

// ─────────────────────────────────────────────────────────────
// TARJETA FACTURA
// ─────────────────────────────────────────────────────────────
class _TarjetaFacturaCliente extends StatelessWidget {
  final _FacturaCliente factura;
  final VoidCallback onTap;

  const _TarjetaFacturaCliente({required this.factura, required this.onTap});

  String _fmt(double n) => '\$${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppColors.cafeOscuro,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    factura.restaurante,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${factura.numero} · ${factura.ubicacion}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        factura.iconoMetodo,
                        size: 11,
                        color: AppColors.cafeMedio,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        factura.fecha,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.cafeMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(factura.total),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracota,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.cafeMedio,
                  size: 16,
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
// SIN FACTURAS
// ─────────────────────────────────────────────────────────────
class _SinFacturas extends StatelessWidget {
  const _SinFacturas();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.cafeMedio,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes facturas',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando hagas tu primer pedido,\naquí aparecerán tus recibos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.cafeMedio,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHEET DETALLE
// ─────────────────────────────────────────────────────────────
class _DetalleFacturaClienteSheet extends StatelessWidget {
  final _FacturaCliente factura;
  const _DetalleFacturaClienteSheet({required this.factura});

  String _fmt(double n) => '\$${n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = factura.total / 1.19;
    final iva = factura.total - subtotal;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
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
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.terracota.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.terracota,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    factura.restaurante,
                    textAlign: TextAlign.center,
                    style: AppTheme.titulo(size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${factura.numero} · ${factura.fecha}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Items ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'DETALLE DEL CONSUMO',
                          style: AppTheme.etiqueta(),
                        ),
                        const SizedBox(height: 12),
                        ...factura.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.cremaOscura,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.cantidad}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.cafeOscuro,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.nombre,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.cafeOscuro,
                                    ),
                                  ),
                                ),
                                Text(
                                  _fmt(item.subtotal),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cafeOscuro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                            color: AppColors.bordeSuave, height: 22),
                        _FilaTotal(label: 'Subtotal', valor: _fmt(subtotal)),
                        _FilaTotal(label: 'IVA 19%', valor: _fmt(iva)),
                        const SizedBox(height: 8),
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

                  // ── Método de pago ──
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
                        Expanded(
                          child: Text(
                            factura.metodo,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Acciones ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toast(context, 'Factura reenviada a tu correo');
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Reenviar'),
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
                          onPressed: () {
                            Navigator.pop(context);
                            _toast(context, 'Descargando PDF…');
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Descargar PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
