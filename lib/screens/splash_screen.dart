import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pantalla de bienvenida: muestra el logo "W" con rebote y luego
/// cambia sola a [destino] (la pantalla que decide login o inicio).
class SplashScreen extends StatefulWidget {
  final Widget destino;
  const SplashScreen({super.key, required this.destino});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _escala;
  late final Animation<double> _opacidad;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _escala = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 40,
      ),
    ]).animate(_ctrl);
    _opacidad = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _listo
          ? KeyedSubtree(key: const ValueKey('destino'), child: widget.destino)
          : Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: AppColors.crema,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _escala,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.terracota,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.terracota.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'W',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 52,
                              fontStyle: FontStyle.italic,
                              color: AppColors.crema,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _opacidad,
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
                  ],
                ),
              ),
            ),
    );
  }
}
