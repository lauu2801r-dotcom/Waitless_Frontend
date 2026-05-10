import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_controller.dart';
import '../../utils/app_strings.dart';
import '../login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_pedidos_screen.dart';
import 'admin_prediccion_screen.dart';
import 'admin_perfil_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    AdminDashboardScreen(),
    AdminPedidosScreen(),
    AdminPrediccionScreen(),
    AdminPerfilScreen(),
  ];

  Future<void> _cerrarSesion() async {
    final auth = AuthScope.of(context);
    
    // Diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: Text(
          '¿Seguro que quieres cerrar sesión?',
          style: GoogleFonts.inter(color: AppColors.cafeOscuro),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: AppColors.cafeMedio),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.inter(
                color: AppColors.terracota,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await auth.cerrarSesion();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _tituloActual(),
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeOscuro,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.terracota),
            tooltip: AppStrings.t(context, 'cerrar_sesion'),
            onPressed: _cerrarSesion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.superficie,
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.superficie,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.terracota,
          unselectedItemColor: AppColors.cafeMedio,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          currentIndex: _indiceActual,
          onTap: (i) => setState(() => _indiceActual = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: AppStrings.t(context, 'panel'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: AppStrings.t(context, 'pedidos'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_graph_outlined),
              activeIcon: const Icon(Icons.auto_graph),
              label: AppStrings.t(context, 'analisis'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_outlined),
              activeIcon: const Icon(Icons.storefront),
              label: AppStrings.t(context, 'negocio'),
            ),
          ],
        ),
      ),
    );
  }

  String _tituloActual() {
    final ctx = context;
    switch (_indiceActual) {
      case 0:
        return AppStrings.t(ctx, 'panel');
      case 1:
        return AppStrings.t(ctx, 'pedidos');
      case 2:
        return AppStrings.t(ctx, 'analisis');
      case 3:
        return AppStrings.t(ctx, 'negocio');
      default:
        return 'Sabor & Datos';
    }
  }
}