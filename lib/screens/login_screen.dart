import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'main_shell.dart';
import 'admin/admin_shell.dart';
import 'registro_screen.dart';
import 'verificacion_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  bool _ocultar = true;
  bool _cargando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _olvideContrasena(BuildContext context) {
    final correoCtrl = TextEditingController(text: _correoCtrl.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset,
                    color: AppColors.terracota, size: 32),
              ),
            ),
            const SizedBox(height: 14),
            Text('Recuperar contraseña',
                textAlign: TextAlign.center,
                style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 6),
            Text(
              'Ingresa tu correo y te enviaremos un enlace para crear una nueva contraseña.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.cafeMedio,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'CORREO ELECTRÓNICO',
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.mail_outline,
                    color: AppColors.cafeMedio, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final correo = correoCtrl.text.trim();
                Navigator.pop(ctx);
                if (correo.isEmpty) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Si la cuenta existe, te enviamos un enlace a $correo',
                      style: GoogleFonts.inter(color: AppColors.crema),
                    ),
                    backgroundColor: AppColors.oliva,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Text('ENVIAR ENLACE'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: AppColors.cafeMedio,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ingresar() async {
    setState(() => _errorGeneral = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final auth = AuthScope.of(context);
    final resultado = await auth.iniciarSesion(
      correo: _correoCtrl.text,
      password: _pwdCtrl.text,
    );
    if (!mounted) return;
    setState(() => _cargando = false);

    switch (resultado) {
      case AuthExito(:final datos):
        // Detectar el rol y redirigir a la pantalla correcta
        if (datos.esAdministrador) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      case AuthError(:final mensaje):
        if (mensaje.contains('verificado')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerificacionScreen(correo: _correoCtrl.text),
            ),
          );
        } else {
          setState(() => _errorGeneral = mensaje);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.terracota,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracota.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'W',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42,
                              fontStyle: FontStyle.italic,
                              color: AppColors.crema,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Bienvenido',
                        textAlign: TextAlign.center,
                        style: AppTheme.titulo(size: 32)),
                    const SizedBox(height: 6),
                    Text('TU MESA TE ESPERA',
                        textAlign: TextAlign.center,
                        style: AppTheme.etiqueta(size: 11)),
                    const SizedBox(height: 48),
                    if (_errorGeneral != null) ...[
                      _BannerError(mensaje: _errorGeneral!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.correo,
                      decoration: const InputDecoration(
                        labelText: 'CORREO ELECTRÓNICO',
                        hintText: 'tu@correo.com',
                        prefixIcon: Icon(Icons.mail_outline,
                            color: AppColors.cafeMedio, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pwdCtrl,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'CONTRASEÑA',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.cafeMedio, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultar ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.cafeMedio,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _olvideContrasena(context),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.cafeMedio,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.crema,
                              ),
                            )
                          : const Text('INICIAR SESIÓN'),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.borde)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio,
                                letterSpacing: 1),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.borde)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¿Nuevo por aquí? ',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegistroScreen()),
                            );
                          },
                          child: Text(
                            'Regístrate',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.terracota,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  final String mensaje;
  const _BannerError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.terracotaOscuro, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.terracotaOscuro,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
