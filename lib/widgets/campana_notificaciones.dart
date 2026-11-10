import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notificaciones_service.dart';
import '../theme/app_theme.dart';
import 'notificaciones_sheet.dart';

/// Campanita con contador de no leídas. Abre la hoja de notificaciones.
class CampanaNotificaciones extends StatelessWidget {
  const CampanaNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificacionesCenter.instancia,
      builder: (context, _) {
        final n = NotificacionesCenter.instancia.noLeidas;
        return IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => mostrarNotificaciones(context),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.terracota),
              if (n > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.terracotaOscuro,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      n > 9 ? '9+' : '$n',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Envuelve una pantalla: mantiene viva la conexión de notificaciones mientras
/// esté abierta y muestra un aviso (toast) cuando llega una nueva en vivo.
class AvisosEnVivo extends StatefulWidget {
  final Widget child;
  const AvisosEnVivo({super.key, required this.child});

  @override
  State<AvisosEnVivo> createState() => _AvisosEnVivoState();
}

class _AvisosEnVivoState extends State<AvisosEnVivo> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    final centro = NotificacionesCenter.instancia..iniciar();
    _sub = centro.avisos.listen((titulo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('🔔 $titulo'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    NotificacionesCenter.instancia.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
