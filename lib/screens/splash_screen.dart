import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  /// Pantalla a la que se pasa cuando termina la animación (el login).
  final Widget destino;
  const SplashScreen({super.key, required this.destino});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _escala;
  late final Animation<double> _opacidadLogo;
  late final Animation<double> _opacidadTexto;
  late final Animation<Offset> _desliza;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _escala = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _opacidadLogo = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _opacidadTexto = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    _desliza = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.forward();
    _timer = Timer(const Duration(milliseconds: 2600), _continuar);
  }

  void _continuar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.destino,
        transitionsBuilder: (_, animacion, __, child) =>
            FadeTransition(opacity: animacion, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _opacidadLogo,
              child: ScaleTransition(
                scale: _escala,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.terracota,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.terracota.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'W',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 56,
                        fontStyle: FontStyle.italic,
                        color: AppColors.crema,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _opacidadTexto,
              child: SlideTransition(
                position: _desliza,
                child: Column(
                  children: [
                    Text('WaitLess', style: AppTheme.titulo(size: 34)),
                    const SizedBox(height: 6),
                    Text(
                      'MENOS ESPERA, MÁS SABOR',
                      style: AppTheme.etiqueta(size: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}