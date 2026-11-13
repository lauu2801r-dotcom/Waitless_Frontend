import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

/// Muestra una imagen del backend (ruta /static/... o enlace http) con esquinas
/// redondeadas. Si no hay imagen, o falla la carga, muestra [fallback] (el emoji de siempre).
class ImagenRed extends StatelessWidget {
  final String? url;
  final double? ancho;
  final double? alto;
  final double radio;
  final Widget fallback;

  const ImagenRed({
    super.key,
    required this.url,
    required this.fallback,
    this.ancho,
    this.alto,
    this.radio = 12,
  });

  @override
  Widget build(BuildContext context) {
    final u = ApiConfig.imagen(url);
    if (u == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: SizedBox(
        width: ancho,
        height: alto,
        child: Image.network(
          u,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progreso) => progreso == null
              ? child
              : Container(color: AppColors.cremaOscura.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
