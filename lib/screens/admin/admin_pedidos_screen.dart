import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/mock_data.dart';
import '../../models/pedido.dart';
import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';

class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  String _filtro = 'Todos';
  late List<Pedido> _pedidos;
  bool _inicializado = false;

  static const _flujo = [
    EstadoPedido.recibido,
    EstadoPedido.enCocina,
    EstadoPedido.emplatado,
    EstadoPedido.enCamino,
    EstadoPedido.entregado,
  ];

  void _avanzarEstado(Pedido p) {
    final idx = _pedidos.indexWhere((x) => x.numero == p.numero);
    if (idx == -1) return;
    final actual = _flujo.indexOf(_pedidos[idx].estado);
    if (actual >= _flujo.length - 1) return;
    final nuevo = _flujo[actual + 1];
    setState(() {
      _pedidos[idx] = _pedidos[idx].copyWith(
        estado: nuevo,
        minutosRestantes: nuevo == EstadoPedido.entregado
            ? 0
            : (_pedidos[idx].minutosRestantes - 2).clamp(0, 99),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${p.numero} → ${nuevo.etiqueta}',
            style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: AppColors.oliva,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _cancelarPedido(Pedido p) {
    setState(() {
      _pedidos.removeWhere((x) => x.numero == p.numero);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${p.numero} cancelado',
            style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: AppColors.terracota,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _reasignarMesa(Pedido p) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: p.mesa ?? '');
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Reasignar pedido #${p.numero}',
              style: AppTheme.titulo(size: 18)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'NUEVA MESA',
              hintText: 'Mesa 12',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(color: AppColors.cafeMedio)),
            ),
            TextButton(
              onPressed: () {
                final nueva = ctrl.text.trim();
                Navigator.pop(ctx);
                if (nueva.isEmpty) return;
                final idx =
                    _pedidos.indexWhere((x) => x.numero == p.numero);
                if (idx >= 0) {
                  setState(() {
                    _pedidos[idx] = _pedidos[idx].copyWith(mesa: nueva);
                  });
                }
              },
              child: Text('Reasignar',
                  style: GoogleFonts.inter(
                      color: AppColors.terracota,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    final restauranteId = auth?.usuario?.restauranteId ?? 'rest_001';
    final conDatos = auth?.usuario?.conDatos ?? false;
    if (!_inicializado) {
      _pedidos = conDatos
          ? List<Pedido>.from(PedidosMock.porRestaurante(restauranteId))
          : <Pedido>[];
      _inicializado = true;
    }
    final pedidos = _pedidos;

    final pedidosFiltrados = _filtrarPedidos(pedidos);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pedidos', style: AppTheme.titulo(size: 30)),
                  const SizedBox(height: 4),
                  Text('GESTIONA TUS PEDIDOS DEL DÍA',
                      style: AppTheme.etiqueta()),
                  const SizedBox(height: 20),
                  // Filtros
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _ChipFiltro(
                          label: 'Todos',
                          activo: _filtro == 'Todos',
                          onTap: () => setState(() => _filtro = 'Todos'),
                          contador: pedidos.length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'En cocina',
                          activo: _filtro == 'En cocina',
                          onTap: () => setState(() => _filtro = 'En cocina'),
                          contador: pedidos
                              .where((p) =>
                                  p.estado == EstadoPedido.enCocina ||
                                  p.estado == EstadoPedido.recibido)
                              .length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'Listos',
                          activo: _filtro == 'Listos',
                          onTap: () => setState(() => _filtro = 'Listos'),
                          contador: pedidos
                              .where((p) =>
                                  p.estado == EstadoPedido.emplatado ||
                                  p.estado == EstadoPedido.enCamino)
                              .length,
                        ),
                        const SizedBox(width: 8),
                        _ChipFiltro(
                          label: 'Entregados',
                          activo: _filtro == 'Entregados',
                          onTap: () => setState(() => _filtro = 'Entregados'),
                          contador: pedidos
                              .where((p) => p.estado == EstadoPedido.entregado)
                              .length,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: pedidosFiltrados.isEmpty
                  ? _EstadoVacio(filtro: _filtro)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: pedidosFiltrados.length,
                      itemBuilder: (context, index) {
                        final pedido = pedidosFiltrados[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TarjetaPedidoAdmin(
                            pedido: pedido,
                            onAvanzar: () => _avanzarEstado(pedido),
                            onReasignar: () => _reasignarMesa(pedido),
                            onCancelar: () => _cancelarPedido(pedido),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Pedido> _filtrarPedidos(List<Pedido> todos) {
    switch (_filtro) {
      case 'En cocina':
        return todos
            .where((p) =>
                p.estado == EstadoPedido.enCocina ||
                p.estado == EstadoPedido.recibido)
            .toList();
      case 'Listos':
        return todos
            .where((p) =>
                p.estado == EstadoPedido.emplatado ||
                p.estado == EstadoPedido.enCamino)
            .toList();
      case 'Entregados':
        return todos.where((p) => p.estado == EstadoPedido.entregado).toList();
      default:
        return todos;
    }
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final int contador;

  const _ChipFiltro({
    required this.label,
    required this.activo,
    required this.onTap,
    required this.contador,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo ? AppColors.terracota : AppColors.superficie,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo ? AppColors.terracota : AppColors.borde,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activo ? AppColors.crema : AppColors.cafeOscuro,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? AppColors.crema.withValues(alpha: 0.25)
                      : AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  contador.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: activo ? AppColors.crema : AppColors.cafeMedio,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaPedidoAdmin extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onAvanzar;
  final VoidCallback? onReasignar;
  final VoidCallback? onCancelar;
  const _TarjetaPedidoAdmin({
    required this.pedido,
    this.onAvanzar,
    this.onReasignar,
    this.onCancelar,
  });

  String _fmt(double n) => n
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final esEntregado = pedido.estado == EstadoPedido.entregado;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: pedido.estado.colorAcento,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('PEDIDO #${pedido.numero}',
                            style: AppTheme.etiqueta(size: 10)),
                        const SizedBox(width: 8),
                        Text('· ${pedido.horaPedido}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(pedido.plato,
                        style: AppTheme.titulo(size: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (pedido.detalle != null && pedido.detalle!.isNotEmpty)
                      Text(pedido.detalle!,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.cafeMedio),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant_outlined,
                            size: 12, color: AppColors.cafeMedio),
                        const SizedBox(width: 4),
                        Text(pedido.mesa ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.cafeMedio)),
                        const SizedBox(width: 12),
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.cafeMedio),
                        const SizedBox(width: 4),
                        Text(pedido.clienteNombre ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.cafeMedio)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pedido.estado.colorFondo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pedido.estado.etiqueta,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: pedido.estado.colorTexto,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('\$${_fmt(pedido.precio)}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cafeOscuro)),
                  if (!esEntregado) ...[
                    const SizedBox(height: 2),
                    Text('${pedido.minutosRestantes} min',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.cafeMedio)),
                  ],
                ],
              ),
            ],
          ),
          if (!esEntregado) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pedido.estado.progreso,
                minHeight: 4,
                backgroundColor: AppColors.cremaOscura,
                valueColor:
                    AlwaysStoppedAnimation(pedido.estado.colorAcento),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAvanzar,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Avanzar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.oliva,
                      side: const BorderSide(color: AppColors.oliva),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.cafeMedio, size: 20),
                  color: AppColors.superficie,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.borde)),
                  position: PopupMenuPosition.under,
                  onSelected: (op) {
                    switch (op) {
                      case 'reasignar':
                        onReasignar?.call();
                      case 'imprimir':
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Imprimiendo comanda del pedido #${pedido.numero}',
                                style: GoogleFonts.inter(
                                    color: AppColors.crema)),
                            backgroundColor: AppColors.cafeOscuro,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      case 'cancelar':
                        onCancelar?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'reasignar',
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz,
                              size: 18, color: AppColors.oliva),
                          const SizedBox(width: 10),
                          Text('Reasignar mesa',
                              style: GoogleFonts.inter(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'imprimir',
                      child: Row(
                        children: [
                          const Icon(Icons.print_outlined,
                              size: 18, color: AppColors.cafeOscuro),
                          const SizedBox(width: 10),
                          Text('Imprimir comanda',
                              style: GoogleFonts.inter(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancelar',
                      child: Row(
                        children: [
                          const Icon(Icons.close,
                              size: 18, color: AppColors.terracota),
                          const SizedBox(width: 10),
                          Text('Cancelar pedido',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.terracota)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String filtro;
  const _EstadoVacio({required this.filtro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.cremaOscura,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.cafeMedio, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No hay pedidos $filtro',
              style: AppTheme.titulo(size: 18)),
          const SizedBox(height: 4),
          Text('Cuando lleguen pedidos, aparecerán aquí',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio)),
        ],
      ),
    );
  }
}
