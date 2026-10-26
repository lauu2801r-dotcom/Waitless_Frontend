import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_pedidos_screen.dart';
import '../login_screen.dart';
import 'empleado_mesas_screen.dart';

/// Vista del personal del restaurante (mesero, cocinero, cajero).
/// El cargo es solo una etiqueta: todos ven lo mismo — pedidos y mesas de SU restaurante.
class EmpleadoShell extends StatefulWidget {
  const EmpleadoShell({super.key});

  @override
  State<EmpleadoShell> createState() => _EmpleadoShellState();
}

class _EmpleadoShellState extends State<EmpleadoShell> {
  int _indice = 0;

  final List<Widget> _pantallas = const [
    AdminPedidosScreen(),
    EmpleadoMesasScreen(),
  ];

  Future<void> _cerrarSesion() async {
    final auth = AuthScope.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        content: Text('¿Seguro que quieres cerrar sesión?',
            style: GoogleFonts.inter(color: AppColors.cafeOscuro)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cerrar sesión',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
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
    final nombre = AuthScope.of(context).usuario?.primerNombre ?? '';
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _indice == 0 ? 'Pedidos' : 'Mesas',
          style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro),
        ),
        actions: [
          if (nombre.isNotEmpty)
            Center(
              child: Text('Hola, $nombre',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.cafeMedio)),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.terracota),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pantallas[_indice],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.superficie,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.terracota,
        unselectedItemColor: AppColors.cafeMedio,
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant_outlined),
            activeIcon: Icon(Icons.table_restaurant),
            label: 'Mesas',
          ),
        ],
      ),
    );
  }
}
