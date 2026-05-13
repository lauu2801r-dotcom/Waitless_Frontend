import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pedido_service.dart';
import '../services/menu_service.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';

class CarritoScreen extends StatefulWidget {
  // Tipo de entrega y dirección vienen desde CrearPedidoScreen
  final TipoEntregaApi tipoEntrega;
  final String? direccionDomicilio;

  const CarritoScreen({
    super.key,
    this.tipoEntrega = TipoEntregaApi.restaurante,
    this.direccionDomicilio,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final Carrito _carrito = Carrito();
  final _notasCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  // Tipo de entrega (editable en esta pantalla si el usuario quiere cambiar)
  late TipoEntregaApi _tipoEntrega;

  // Mesas disponibles cargadas del backend
  List<_MesaOpc> _mesas = [];
  _MesaOpc? _mesaSeleccionada;
  bool _cargandoMesas = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tipoEntrega = widget.tipoEntrega;
    _direccionCtrl.text = widget.direccionDomicilio ?? '';
    _cargarMesas();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMesas() async {
    setState(() => _cargandoMesas = true);
    final mesas = await MesaService.obtenerMesasDisponibles();
    setState(() {
      _mesas = mesas;
      _mesaSeleccionada = mesas.isNotEmpty ? mesas.first : null;
      _cargandoMesas = false;
    });
  }

  Future<void> _confirmarPedido() async {
    if (_carrito.estaVacio) {
      _snack('El carrito está vacío', esError: true);
      return;
    }
    if (_mesaSeleccionada == null) {
      _snack('Selecciona una mesa', esError: true);
      return;
    }
    if (_tipoEntrega == TipoEntregaApi.domicilio &&
        _direccionCtrl.text.trim().isEmpty) {
      _snack('Ingresa la dirección de domicilio', esError: true);
      return;
    }

    setState(() => _enviando = true);

    final resultado = await PedidoService.crearPedido(
      mesaId: _mesaSeleccionada!.id,
      items: _carrito.items.toList(),
      notas: _notasCtrl.text.trim(),
      tipoEntrega: _tipoEntrega,
      direccionDomicilio: _tipoEntrega == TipoEntregaApi.domicilio
          ? _direccionCtrl.text.trim()
          : null,
    );

    setState(() => _enviando = false);

    if (!mounted) return;

    if (resultado is PedidoExito<PedidoApi>) {
      _carrito.limpiar();
      Navigator.pop(context);
      _snack('¡Pedido #${resultado.datos.id} enviado a cocina! 🍽️');
    } else if (resultado is PedidoError<PedidoApi>) {
      _snack(resultado.mensaje, esError: true);
    }
  }

  void _snack(String msg, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: esError ? AppColors.terracota : AppColors.oliva,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _carrito,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.crema,
          appBar: AppBar(
            backgroundColor: AppColors.crema,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.cafeOscuro, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Mi pedido', style: AppTheme.titulo(size: 20)),
            actions: [
              if (!_carrito.estaVacio)
                TextButton(
                  onPressed: () => _carrito.limpiar(),
                  child: Text('Limpiar',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.terracota)),
                ),
            ],
          ),
          body: _carrito.estaVacio
              ? _CarritoVacio(onExplorar: () => Navigator.pop(context))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Lista de items ──
                            Text('TU PEDIDO', style: AppTheme.etiqueta()),
                            const SizedBox(height: 12),
                            ..._carrito.items.map((item) =>
                                _ItemCarritoWidget(
                                  item: item,
                                  onIncrementar: () =>
                                      _carrito.agregar(item.producto),
                                  onDecrementar: () =>
                                      _carrito.decrementar(item.producto.id),
                                  onEliminar: () =>
                                      _carrito.quitar(item.producto.id),
                                )),

                            const SizedBox(height: 24),

                            // ── Tipo de entrega ──
                            Text('TIPO DE ENTREGA', style: AppTheme.etiqueta()),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ChipEntrega(
                                    icono: Icons.restaurant,
                                    etiqueta: 'Restaurante',
                                    seleccionado: _tipoEntrega ==
                                        TipoEntregaApi.restaurante,
                                    onTap: () => setState(() =>
                                        _tipoEntrega =
                                            TipoEntregaApi.restaurante),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ChipEntrega(
                                    icono: Icons.delivery_dining,
                                    etiqueta: 'Domicilio',
                                    seleccionado: _tipoEntrega ==
                                        TipoEntregaApi.domicilio,
                                    onTap: () => setState(() =>
                                        _tipoEntrega =
                                            TipoEntregaApi.domicilio),
                                  ),
                                ),
                              ],
                            ),

                            // ── Dirección (solo si domicilio) ──
                            if (_tipoEntrega == TipoEntregaApi.domicilio) ...[
                              const SizedBox(height: 16),
                              Text('DIRECCIÓN DE ENTREGA',
                                  style: AppTheme.etiqueta()),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _direccionCtrl,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.cafeOscuro),
                                decoration: InputDecoration(
                                  hintText: 'Calle, barrio, ciudad...',
                                  hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.cafeMedio),
                                  prefixIcon: const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.terracota,
                                      size: 18),
                                  filled: true,
                                  fillColor: AppColors.superficie,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.borde),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.borde),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.terracota),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.all(14),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ── Seleccionar mesa ──
                            Text('MESA', style: AppTheme.etiqueta()),
                            const SizedBox(height: 10),
                            _cargandoMesas
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.terracota),
                                    ),
                                  )
                                : _mesas.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.alertaFondo,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline,
                                                color: AppColors.alertaTexto,
                                                size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'No hay mesas disponibles ahora. Intenta más tarde.',
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .alertaTexto),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _cargarMesas,
                                              child: Text('Reintentar',
                                                  style: GoogleFonts.inter(
                                                      color: AppColors
                                                          .terracota,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            )
                                          ],
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _mesas
                                            .map((m) => _ChipMesa(
                                                  mesa: m,
                                                  seleccionada:
                                                      _mesaSeleccionada
                                                              ?.id ==
                                                          m.id,
                                                  onTap: () => setState(() =>
                                                      _mesaSeleccionada = m),
                                                ))
                                            .toList(),
                                      ),

                            const SizedBox(height: 24),

                            // ── Notas opcionales ──
                            Text('NOTAS (opcional)',
                                style: AppTheme.etiqueta()),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notasCtrl,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.cafeOscuro),
                              decoration: InputDecoration(
                                hintText:
                                    'Alergias, preferencias de cocción...',
                                hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.cafeMedio),
                                filled: true,
                                fillColor: AppColors.superficie,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.borde),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.borde),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.terracota),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // ── Barra inferior con total y botón ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cafeOscuro.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Badge tipo de entrega
                          Row(
                            children: [
                              Icon(
                                _tipoEntrega == TipoEntregaApi.restaurante
                                    ? Icons.restaurant
                                    : Icons.delivery_dining,
                                size: 14,
                                color: AppColors.cafeMedio,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tipoEntrega.etiqueta,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.cafeMedio),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: AppColors.cafeMedio)),
                              Text(
                                _carrito.totalFormateado,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracota,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_enviando ||
                                      _mesaSeleccionada == null ||
                                      _cargandoMesas)
                                  ? null
                                  : _confirmarPedido,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracota,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _enviando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.crema),
                                    )
                                  : Text(
                                      'CONFIRMAR PEDIDO · ${_carrito.totalFormateado}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.crema,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WIDGETS PRIVADOS
// ─────────────────────────────────────────────────────────────

class _ChipEntrega extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipEntrega({
    required this.icono,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.terracota : AppColors.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: seleccionado ? AppColors.terracota : AppColors.borde),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono,
                size: 18,
                color:
                    seleccionado ? AppColors.crema : AppColors.cafeMedio),
            const SizedBox(width: 8),
            Text(
              etiqueta,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    seleccionado ? AppColors.crema : AppColors.cafeOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCarritoWidget extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEliminar;

  const _ItemCarritoWidget({
    required this.item,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = item.subtotal.toInt();
    final subtotalStr = '\$${subtotal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.producto.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro),
                ),
                const SizedBox(height: 2),
                Text(
                  subtotalStr,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.terracota),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _BotonCantidad(
                icono:
                    item.cantidad == 1 ? Icons.delete_outline : Icons.remove,
                color: item.cantidad == 1
                    ? AppColors.terracota
                    : AppColors.cafeMedio,
                onTap: onDecrementar,
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '${item.cantidad}',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cafeOscuro),
                  ),
                ),
              ),
              _BotonCantidad(
                icono: Icons.add,
                color: AppColors.oliva,
                onTap: onIncrementar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonCantidad({
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, size: 16, color: color),
      ),
    );
  }
}

class _ChipMesa extends StatelessWidget {
  final _MesaOpc mesa;
  final bool seleccionada;
  final VoidCallback onTap;

  const _ChipMesa({
    required this.mesa,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.terracota : AppColors.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  seleccionada ? AppColors.terracota : AppColors.borde),
        ),
        child: Column(
          children: [
            Text(
              'Mesa ${mesa.numero}',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: seleccionada
                      ? AppColors.crema
                      : AppColors.cafeOscuro),
            ),
            Text(
              '${mesa.capacidad} pers.',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: seleccionada
                      ? AppColors.crema.withValues(alpha: 0.8)
                      : AppColors.cafeMedio),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarritoVacio extends StatelessWidget {
  final VoidCallback onExplorar;
  const _CarritoVacio({required this.onExplorar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.terracota, size: 38),
            ),
            const SizedBox(height: 20),
            Text('Tu carrito está vacío', style: AppTheme.titulo(size: 20)),
            const SizedBox(height: 8),
            Text(
              'Explora el menú y agrega los platos que quieras pedir',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.cafeMedio, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onExplorar,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Ver menú'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODELO LIGERO PARA MESAS
// ─────────────────────────────────────────────────────────────

class _MesaOpc {
  final int id;
  final int numero;
  final int capacidad;
  const _MesaOpc(
      {required this.id, required this.numero, required this.capacidad});
}

// ─────────────────────────────────────────────────────────────
//  SERVICIO DE MESAS (solo disponibles)
// ─────────────────────────────────────────────────────────────

class MesaService {
  static String get _base => ApiConfig.baseUrl;

  static Future<List<_MesaOpc>> obtenerMesasDisponibles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('waitless.token');
      final response = await http
          .get(
            Uri.parse('$_base/mesas/disponibles'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((j) => _MesaOpc(
                  id: j['id'] as int,
                  numero: j['numero'] as int,
                  capacidad: j['capacidad'] as int,
                ))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('MesaService ERROR: $e');
      return [];
    }
  }
}