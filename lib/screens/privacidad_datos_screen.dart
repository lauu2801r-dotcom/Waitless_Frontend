import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_controller.dart';
import '../services/privacidad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pagina_negocio.dart';
import 'login_screen.dart';

/// Mis datos y eliminación de cuenta (Ley 1581 de 2012: acceso y supresión).
class PrivacidadDatosScreen extends StatefulWidget {
  const PrivacidadDatosScreen({super.key});

  @override
  State<PrivacidadDatosScreen> createState() => _PrivacidadDatosScreenState();
}

class _PrivacidadDatosScreenState extends State<PrivacidadDatosScreen> {
  bool _cargandoDatos = false;

  Future<void> _verDatos() async {
    setState(() => _cargandoDatos = true);
    try {
      final json = await PrivacidadService.misDatos();
      if (!mounted) return;
      setState(() => _cargandoDatos = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Tus datos',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(json,
                  style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.cafeOscuro)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Copiado al portapapeles')),
                  );
                }
              },
              child: Text('Copiar',
                  style: GoogleFonts.inter(color: AppColors.terracota, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cerrar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoDatos = false);
      mostrarMensaje(context, limpiarError(e), error: true);
    }
  }

  Future<void> _eliminar() async {
    final pwd = TextEditingController();
    final conf = TextEditingController();
    String? error;
    bool enviando = false;
    final borrada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Eliminar mi cuenta',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.terracotaOscuro)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Se cancelarán tus reservas vigentes y se anonimizará tu cuenta. '
                'Esta acción no se puede deshacer.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pwd,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Tu contraseña'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: conf,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Escribe ELIMINAR para confirmar'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.terracotaOscuro)),
                ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
            ),
            TextButton(
              onPressed: enviando
                  ? null
                  : () async {
                      setD(() {
                        enviando = true;
                        error = null;
                      });
                      try {
                        await PrivacidadService.eliminarCuenta(pwd.text, conf.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setD(() {
                          enviando = false;
                          error = limpiarError(e);
                        });
                      }
                    },
              child: Text('Eliminar definitivamente',
                  style: GoogleFonts.inter(
                      color: AppColors.terracotaOscuro, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    // Los controladores no se liberan a mano: el diálogo todavía se está cerrando
    // (animación) y usarlos ya liberados rompe el árbol de widgets.
    if (borrada == true && mounted) {
      // Primero se sale a la pantalla de login (se destruyen estas pantallas) y
      // solo después se limpia la sesión: así nada se reconstruye a la mitad.
      final nav = Navigator.of(context);
      final auth = AuthScope.of(context);
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      await auth.cerrarSesion();
    }
  }

  Widget _tarjeta({
    required IconData icono,
    required String titulo,
    required String texto,
    required Widget boton,
    Color? color,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.superficieAdaptativa(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bordeAdaptativo(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icono, color: color ?? AppColors.terracota),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titulo,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.cafeOscuro)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(texto,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio, height: 1.45)),
          const SizedBox(height: 12),
          boton,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Mis datos y privacidad',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Según la Ley 1581 de 2012 puedes saber qué datos tuyos guarda WaitLess y pedir que los eliminemos.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio, height: 1.45),
          ),
          const SizedBox(height: 16),
          _tarjeta(
            icono: Icons.folder_open_outlined,
            titulo: 'Ver mis datos',
            texto: 'Perfil, reservas, pedidos, facturas, calificaciones y favoritos. Puedes copiarlos.',
            boton: OutlinedButton.icon(
              onPressed: _cargandoDatos ? null : _verDatos,
              icon: _cargandoDatos
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracota))
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Ver mis datos'),
            ),
          ),
          _tarjeta(
            icono: Icons.delete_forever_outlined,
            color: AppColors.terracotaOscuro,
            titulo: 'Eliminar mi cuenta',
            texto: 'Se cancelan tus reservas vigentes y se borran tus notificaciones, favoritos y comentarios. '
                'Tu nombre, correo y teléfono se anonimizan. Los pedidos y facturas se conservan sin tus datos '
                'de contacto, porque son registros contables del restaurante.',
            boton: OutlinedButton.icon(
              onPressed: _eliminar,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.terracotaOscuro,
                side: const BorderSide(color: AppColors.terracotaOscuro),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar mi cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}
