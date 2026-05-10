import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import '../services/pedido_service.dart';
import 'home_screen.dart';
import 'pedidos_screen.dart';
import 'prediccion_screen.dart';
import 'perfil_screen.dart';
import 'carrito_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;
  final Carrito _carrito = Carrito();

  @override
  void initState() {
    super.initState();
    _carrito.addListener(_actualizarCarrito);
  }

  @override
  void dispose() {
    _carrito.removeListener(_actualizarCarrito);
    super.dispose();
  }

  void _actualizarCarrito() => setState(() {});

  void _irATab(int i) {
    if (i == 2) {
      // Tab del carrito → abre como pantalla aparte
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CarritoScreen()),
      );
      return;
    }
    setState(() => _indice = i);
  }

  @override
  Widget build(BuildContext context) {
    // 0=Inicio, 1=Pedidos, 2=Carrito(especial), 3=Momento, 4=Perfil
    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded,
          AppStrings.t(context, 'inicio'), false),
      _NavItem(Icons.receipt_long_outlined, Icons.receipt_long,
          AppStrings.t(context, 'pedidos'), false),
      _NavItem(Icons.shopping_cart_outlined, Icons.shopping_cart,
          'Carrito', true),
      _NavItem(Icons.insights_outlined, Icons.insights,
          AppStrings.t(context, 'momento'), false),
      _NavItem(Icons.person_outline, Icons.person,
          AppStrings.t(context, 'perfil'), false),
    ];

    final pantalla = switch (_indice) {
      0 => const HomeScreen(),
      1 => PedidosScreen(onIrAInicio: () => setState(() => _indice = 0)),
      3 => const PrediccionScreen(),
      _ => const PerfilScreen(),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: pantalla),
            _BarraNav(
              items: items,
              indice: _indice,
              carritoItems: _carrito.totalItems,
              onTap: _irATab,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraNav extends StatelessWidget {
  final List<_NavItem> items;
  final int indice;
  final int carritoItems;
  final ValueChanged<int> onTap;

  const _BarraNav({
    required this.items,
    required this.indice,
    required this.carritoItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactivo = AppColors.textoSecundario(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficieAdaptativa(context),
        border: Border(
          top: BorderSide(color: AppColors.bordeAdaptativo(context), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final activo = i == indice;

              // ── Tab carrito con badge ──
              if (item.esCarrito) {
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(item.icono, color: inactivo, size: 24),
                              if (carritoItems > 0)
                                Positioned(
                                  top: -6,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.terracota,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$carritoItems',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.crema,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: inactivo,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // ── Tabs normales ──
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activo ? item.iconoActivo : item.icono,
                          color: activo ? AppColors.terracota : inactivo,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: activo ? AppColors.terracota : inactivo,
                            fontWeight: activo
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icono;
  final IconData iconoActivo;
  final String label;
  final bool esCarrito;
  const _NavItem(this.icono, this.iconoActivo, this.label, this.esCarrito);
}