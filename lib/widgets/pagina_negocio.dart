import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Estructura común de las pantallas del módulo Negocio.
class PaginaNegocio extends StatelessWidget {
  final String titulo;
  final Widget child;
  final List<Widget>? acciones;
  final Widget? botonInferior;

  const PaginaNegocio({
    super.key,
    required this.titulo,
    required this.child,
    this.acciones,
    this.botonInferior,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondo(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cafeOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titulo, style: AppTheme.titulo(size: 22)),
        actions: acciones,
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: botonInferior == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: botonInferior,
              ),
            ),
    );
  }
}

void mostrarMensaje(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
      backgroundColor: error ? AppColors.terracotaOscuro : AppColors.cafeOscuro,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
}

String limpiarError(Object e) => e.toString().replaceFirst('Exception: ', '');
