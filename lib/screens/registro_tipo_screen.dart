import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'registro_admin_screen.dart';
import 'registro_screen.dart';

class RegistroTipoScreen extends StatelessWidget {
  const RegistroTipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: AppColors.superficie,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.borde),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 16, color: AppColors.cafeOscuro),
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.terracota,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'W',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: AppColors.crema,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Crea tu cuenta', style: AppTheme.titulo(size: 30)),
                  const SizedBox(height: 6),
                  Text(
                    '¿Cómo quieres usar WaitLess?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.cafeMedio,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _OpcionRol(
                    icono: Icons.restaurant_menu,
                    etiqueta: 'PARA COMENSALES',
                    titulo: 'Soy cliente',
                    descripcion:
                        'Reserva tu mesa, haz pedidos y sigue su estado en tiempo real.',
                    oscuro: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistroScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OpcionRol(
                    icono: Icons.storefront_outlined,
                    etiqueta: 'PORTAL DE NEGOCIOS',
                    titulo: 'Tengo un restaurante',
                    descripcion:
                        'Gestiona pedidos, mesas y predicciones de afluencia.',
                    oscuro: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistroAdminScreen()),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: GoogleFonts.inter(
                              fontSize: 13.5, color: AppColors.cafeMedio),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Inicia sesión',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.terracota,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.terracota,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionRol extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String titulo;
  final String descripcion;
  final bool oscuro;
  final VoidCallback onTap;

  const _OpcionRol({
    required this.icono,
    required this.etiqueta,
    required this.titulo,
    required this.descripcion,
    required this.oscuro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTitulo = oscuro ? AppColors.crema : AppColors.cafeOscuro;
    final colorTexto = oscuro ? AppColors.cremaOscura : AppColors.cafeMedio;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: oscuro ? AppColors.cafeOscuro : AppColors.superficie,
          borderRadius: BorderRadius.circular(18),
          border: oscuro ? null : Border.all(color: AppColors.borde),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro
                  .withValues(alpha: oscuro ? 0.18 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.terracota
                    .withValues(alpha: oscuro ? 0.28 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icono,
                color: oscuro ? AppColors.crema : AppColors.terracota,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta,
                      style: AppTheme.etiqueta(size: 10, color: colorTexto)),
                  const SizedBox(height: 4),
                  Text(titulo,
                      style: AppTheme.titulo(size: 19, color: colorTitulo)),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: colorTexto, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: colorTexto),
          ],
        ),
      ),
    );
  }
}