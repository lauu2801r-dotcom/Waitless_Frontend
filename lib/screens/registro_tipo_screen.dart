import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'registro_admin_screen.dart';
import 'registro_screen.dart';

/// Selector previo al registro: ¿cliente o dueño de restaurante?
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
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
                  ),
                  const SizedBox(height: 28),
                  Text('¿Cómo quieres\nusar WaitLess?',
                      style: AppTheme.titulo(size: 30)),
                  const SizedBox(height: 8),
                  Text(
                    'Elige el tipo de cuenta que necesitas.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _TarjetaTipo(
                    icono: Icons.restaurant_menu,
                    titulo: 'Soy cliente',
                    descripcion:
                        'Reserva mesa, haz pedidos y consulta cuánto vas a esperar.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistroScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TarjetaTipo(
                    icono: Icons.storefront_outlined,
                    titulo: 'Tengo un restaurante',
                    descripcion:
                        'Gestiona pedidos, mesas y predicciones de afluencia. Requiere código de negocio.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegistroAdminScreen()),
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

class _TarjetaTipo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const _TarjetaTipo({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: AppColors.terracota, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTheme.titulo(size: 18)),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.cafeMedio,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.cafeMedio),
            ],
          ),
        ),
      ),
    );
  }
}
