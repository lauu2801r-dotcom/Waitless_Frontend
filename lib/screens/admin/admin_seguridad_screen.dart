import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/negocio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';
import '../privacidad_datos_screen.dart';

/// Seguridad y acceso: cambiar la contraseña (pide la actual).
class AdminSeguridadScreen extends StatefulWidget {
  const AdminSeguridadScreen({super.key});

  @override
  State<AdminSeguridadScreen> createState() => _AdminSeguridadScreenState();
}

class _AdminSeguridadScreenState extends State<AdminSeguridadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();
  bool _ver = false;
  bool _guardando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  String? _validarNueva(String? v) {
    final t = v ?? '';
    if (t.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(t)) return 'Incluye al menos una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(t)) return 'Incluye al menos un número';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await NegocioService.cambiarPassword(_actual.text, _nueva.text);
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, limpiarError(e), error: true);
    }
  }

  InputDecoration _deco(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.cafeMedio),
        suffixIcon: IconButton(
          icon: Icon(_ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.cafeMedio),
          onPressed: () => setState(() => _ver = !_ver),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Seguridad y acceso',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('CAMBIAR CONTRASEÑA', style: AppTheme.etiqueta()),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: _actual,
                obscureText: !_ver,
                decoration: _deco('Contraseña actual'),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nueva,
                obscureText: !_ver,
                decoration: _deco('Nueva contraseña'),
                validator: _validarNueva,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repetir,
                obscureText: !_ver,
                decoration: _deco('Repite la nueva contraseña'),
                validator: (v) => v != _nueva.text ? 'Las contraseñas no coinciden' : null,
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Mínimo 8 caracteres, con una mayúscula y un número.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: AppColors.crema, strokeWidth: 2))
                : const Text('ACTUALIZAR CONTRASEÑA'),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacidadDatosScreen()),
            ),
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Mis datos y privacidad'),
          ),
          const SizedBox(height: 24),
          Text('PROTECCIÓN DE TU CUENTA', style: AppTheme.etiqueta()),
          const SizedBox(height: 10),
          _punto(Icons.lock_clock_outlined,
              'Tras 5 intentos fallidos de inicio de sesión, la cuenta se bloquea 15 minutos.'),
          _punto(Icons.fact_check_outlined,
              'Los cambios importantes (contraseña, pagos, reservas) quedan en el registro de auditoría.'),
          _punto(Icons.mark_email_read_outlined,
              '¿Olvidaste tu contraseña? Usa "¿Olvidaste tu contraseña?" en el inicio de sesión: te enviamos un código al correo.'),
        ],
      ),
    );
  }

  Widget _punto(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, size: 18, color: AppColors.terracota),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio, height: 1.4)),
          ),
        ]),
      );
}
