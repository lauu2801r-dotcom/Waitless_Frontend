import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_controller.dart';
import '../../services/dashboard_service.dart';
import '../../utils/app_strings.dart';
import '../../utils/formato.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardApi? _datos;
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
    final resultado = await DashboardService.obtenerDashboard();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resultado is DashboardExito) {
        _datos = resultado.datos;
      } else if (resultado is DashboardError) {
        _error = resultado.mensaje;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final nombre = auth.usuario?.nombreRestaurante ?? 'Mi Restaurante';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.terracota,
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${AppStrings.t(context, 'hola')} 👋',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.cafeOscuro.withValues(alpha: 0.6))),
                        const SizedBox(height: 4),
                        Text(nombre,
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cafeOscuro)),
                        const SizedBox(height: 4),
                        Text(AppStrings.t(context, 'resumen_hoy'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio)),
                      ],
                    ),
                    IconButton(
                      onPressed: _cargar,
                      icon: const Icon(Icons.refresh, color: AppColors.terracota),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Estados ──
                if (_cargando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.terracota),
                    ),
                  )
                else if (_error != null)
                  _ErrorWidget(mensaje: _error!, onReintentar: _cargar)
                else if (_datos != null)
                  _CuerpoDashboard(datos: _datos!, onCargar: _cargar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CUERPO DASHBOARD
// ─────────────────────────────────────────────────────────────
class _CuerpoDashboard extends StatelessWidget {
  final DashboardApi datos;
  final VoidCallback onCargar;

  const _CuerpoDashboard({
    required this.datos,
    required this.onCargar,
  });

  String _emojiEstado(String estado) {
    switch (estado) {
      case 'pendiente':      return 'Nuevo';
      case 'en_preparacion': return 'Preparando';
      case 'listo':          return 'Listo';
      case 'entregado':      return 'Entregado';
      default:               return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':      return AppColors.oliva;
      case 'en_preparacion': return AppColors.terracotaOscuro;
      case 'listo':          return AppColors.terracota;
      case 'entregado':      return AppColors.exitoTexto;
      default:               return AppColors.cafeMedio;
    }
  }

  String _emojiPlato(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('pasta') || n.contains('carbona')) return '🍝';
    if (n.contains('pizza')) return '🍕';
    if (n.contains('carne') || n.contains('bife') || n.contains('chorizo')) return '🥩';
    if (n.contains('ensalada') || n.contains('entrada')) return '🥗';
    if (n.contains('postre') || n.contains('torta') || n.contains('helado')) return '🍰';
    if (n.contains('bebida') || n.contains('jugo') || n.contains('agua')) return '🍹';
    if (n.contains('pollo')) return '🍗';
    if (n.contains('burguer') || n.contains('hamburguesa')) return '🍔';
    return '🍽️';
  }

  void _hoja(BuildContext context, List<Widget> hijos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 16),
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaDato(String etiqueta, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio)),
          Text(valor,
              style: destacado
                  ? GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracota)
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro)),
        ],
      ),
    );
  }

  void _detallePedido(BuildContext context, PedidoRecienteApi p) {
    final color = _colorEstado(p.estado);
    _hoja(context, [
      Row(
        children: [
          Expanded(
              child: Text('Pedido #${p.id}', style: AppTheme.titulo(size: 22))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_emojiEstado(p.estado),
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text('Mesa ${p.mesaVisible} · ${p.tiempoFormateado}',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
      const SizedBox(height: 16),
      Text('DETALLE DEL PEDIDO', style: AppTheme.etiqueta()),
      const SizedBox(height: 10),
      if (p.items.isEmpty)
        Text('Sin detalle disponible',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio))
      else
        ...p.items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${i.cantidad}x ${i.nombre}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.cafeOscuro)),
                  ),
                  Text(moneda(i.subtotal),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cafeOscuro)),
                ],
              ),
            )),
      if ((p.notas ?? '').isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('NOTAS', style: AppTheme.etiqueta()),
        const SizedBox(height: 4),
        Text(p.notas!,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.cafeOscuro)),
      ],
      const Divider(height: 28),
      _filaDato('Total', moneda(p.total), destacado: true),
    ]);
  }

  void _detallePlato(BuildContext context, TopPlatoApi t) {
    final promedio = t.vendidos == 0 ? 0.0 : t.ingresos / t.vendidos;
    _hoja(context, [
      Center(
          child: Text(_emojiPlato(t.nombre),
              style: const TextStyle(fontSize: 56))),
      const SizedBox(height: 8),
      Center(child: Text(t.nombre, style: AppTheme.titulo(size: 22))),
      const SizedBox(height: 16),
      _filaDato('Vendidos hoy', '${t.vendidos}'),
      _filaDato('Precio promedio', moneda(promedio)),
      const Divider(height: 24),
      _filaDato('Ingresos del día', moneda(t.ingresos), destacado: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final d = datos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Métricas ──
        Row(
          children: [
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.attach_money,
                titulo: AppStrings.t(context, 'ventas_hoy'),
                valor: d.ventasFormateado,
                color: AppColors.terracota,
                tendencia: d.ventasHoy > 0 ? '+hoy' : '\$0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.receipt_long,
                titulo: AppStrings.t(context, 'pedidos_activos'),
                valor: '${d.pedidosActivos}',
                color: AppColors.oliva,
                tendencia: d.pedidosActivos > 0 ? '+${d.pedidosActivos}' : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.table_restaurant,
                titulo: AppStrings.t(context, 'mesas_ocupadas'),
                valor: d.mesasFormateado,
                color: AppColors.terracotaOscuro,
                tendencia: d.porcentajeMesas,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TarjetaMetrica(
                icono: Icons.people,
                titulo: AppStrings.t(context, 'clientes_hoy'),
                valor: '${d.clientesHoy}',
                color: AppColors.cafeMedio,
                tendencia: d.clientesHoy > 0 ? '+${d.clientesHoy}' : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Pedidos recientes ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppStrings.t(context, 'pedidos_recientes'),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro)),
            Text(AppStrings.t(context, 'ver_todos'),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.terracota,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 12),

        if (d.pedidosRecientes.isEmpty)
          const _SinDatos(mensaje: 'No hay pedidos recientes hoy')
        else
          ...d.pedidosRecientes.map((p) => GestureDetector(
                onTap: () => _detallePedido(context, p),
                child: _TarjetaPedidoReciente(
                  id: p.id,
                  mesaId: p.mesaVisible,
                  total: p.total,
                  estado: _emojiEstado(p.estado),
                  tiempo: p.tiempoFormateado,
                  colorEstado: _colorEstado(p.estado),
                ),
              )),

        const SizedBox(height: 28),

        // ── Top platos ──
        Text('Top platos del día',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
        const SizedBox(height: 12),

        if (d.topPlatos.isEmpty)
          const _SinDatos(mensaje: 'Sin ventas registradas hoy')
        else
          ...d.topPlatos.asMap().entries.map((e) => GestureDetector(
                onTap: () => _detallePlato(context, e.value),
                child: _TarjetaTopPlato(
                  posicion: e.key + 1,
                  emoji: _emojiPlato(e.value.nombre),
                  nombre: e.value.nombre,
                  vendidos: e.value.vendidos,
                  ingresos: e.value.ingresosFormateado,
                ),
              )),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA MÉTRICA
// ─────────────────────────────────────────────────────────────
class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final String tendencia;

  const _TarjetaMetrica({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
    required this.tendencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tendencia,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(valor,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cafeOscuro)),
          const SizedBox(height: 2),
          Text(titulo,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA PEDIDO RECIENTE
// ─────────────────────────────────────────────────────────────
class _TarjetaPedidoReciente extends StatelessWidget {
  final int id;
  final int mesaId;
  final double total;
  final String estado;
  final String tiempo;
  final Color colorEstado;

  const _TarjetaPedidoReciente({
    required this.id,
    required this.mesaId,
    required this.total,
    required this.estado,
    required this.tiempo,
    required this.colorEstado,
  });

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: colorEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('#$mesaId',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorEstado)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mesa $mesaId · Pedido #$id',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(estado,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorEstado)),
                    ),
                    const SizedBox(width: 6),
                    Text('· $tiempo',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.cafeMedio)),
                  ],
                ),
              ],
            ),
          ),
          Text('\$${_fmt(total)}',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracota)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TARJETA TOP PLATO
// ─────────────────────────────────────────────────────────────
class _TarjetaTopPlato extends StatelessWidget {
  final int posicion;
  final String emoji;
  final String nombre;
  final int vendidos;
  final String ingresos;

  const _TarjetaTopPlato({
    required this.posicion,
    required this.emoji,
    required this.nombre,
    required this.vendidos,
    required this.ingresos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$posicion',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracota)),
            ),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 2),
                Text('$vendidos vendidos',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.cafeMedio)),
              ],
            ),
          ),
          Text(ingresos,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracota)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SIN DATOS
// ─────────────────────────────────────────────────────────────
class _SinDatos extends StatelessWidget {
  final String mensaje;
  const _SinDatos({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Text(mensaje,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR
// ─────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorWidget({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.cafeMedio, size: 36),
          const SizedBox(height: 12),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onReintentar,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.terracota),
          ),
        ],
      ),
    );
  }
}