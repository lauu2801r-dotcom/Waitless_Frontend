import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

/// Recuperar contraseña en 2 pasos:
///  1) el usuario escribe su correo y recibe un código de 6 dígitos;
///  2) escribe el código y su nueva contraseña.
/// Al terminar vuelve al login devolviendo el correo (para dejarlo escrito).
class RecuperarPasswordScreen extends StatefulWidget {
  final String correoInicial;
  const RecuperarPasswordScreen({super.key, this.correoInicial = ''});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formCorreo = GlobalKey<FormState>();
  final _formClave = GlobalKey<FormState>();
  late final TextEditingController _correoCtrl;
  final _codigoCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  int _paso = 1; // 1 = pedir código, 2 = nueva contraseña
  bool _cargando = false;
  bool _ocultar = true;
  String? _error;

  Timer? _timer;
  int _segundos = 0;

  @override
  void initState() {
    super.initState();
    _correoCtrl = TextEditingController(text: widget.correoInicial);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  void _iniciarCuentaRegresiva() {
    _timer?.cancel();
    setState(() => _segundos = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundos <= 0) {
        t.cancel();
      } else {
        setState(() => _segundos--);
      }
    });
  }

  Future<void> _enviarCodigo({bool reenvio = false}) async {
    setState(() => _error = null);
    if (!_formCorreo.currentState!.validate()) return;

    setState(() => _cargando = true);
    final auth = AuthScope.of(context);
    final r = await auth.solicitarRecuperacion(_correoCtrl.text);
    if (!mounted) return;
    setState(() => _cargando = false);

    switch (r) {
      case AuthExito():
        _iniciarCuentaRegresiva();
        setState(() => _paso = 2);
        if (reenvio) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Te enviamos un código nuevo',
                  style: GoogleFonts.inter(color: AppColors.crema)),
              backgroundColor: AppColors.cafeOscuro,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case AuthError(:final mensaje):
        setState(() => _error = mensaje);
    }
  }

  Future<void> _cambiarPassword() async {
    setState(() => _error = null);
    if (!_formClave.currentState!.validate()) return;

    setState(() => _cargando = true);
    final auth = AuthScope.of(context);
    final r = await auth.restablecerPassword(
      correo: _correoCtrl.text,
      codigo: _codigoCtrl.text,
      nuevaPassword: _pwdCtrl.text,
    );
    if (!mounted) return;
    setState(() => _cargando = false);

    switch (r) {
      case AuthExito():
        final correo = _correoCtrl.text.trim();
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(correo);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Contraseña actualizada. Ya puedes iniciar sesión',
                style: GoogleFonts.inter(color: AppColors.crema)),
            backgroundColor: AppColors.oliva,
            behavior: SnackBarBehavior.floating,
          ),
        );
      case AuthError(:final mensaje):
        setState(() => _error = mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            if (_paso == 2 && !_cargando) {
              setState(() {
                _paso = 1;
                _error = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 16),
                  Text('Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: AppTheme.titulo(size: 26)),
                  const SizedBox(height: 8),
                  Text(
                    _paso == 1
                        ? 'Ingresa tu correo y te enviaremos un código de 6 dígitos.'
                        : 'Enviamos un código a ${_correoCtrl.text.trim()}. Escríbelo y elige tu nueva contraseña.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.cafeMedio,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    _Aviso(mensaje: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (_paso == 1) _pasoCorreo() else _pasoClave(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pasoCorreo() {
    return Form(
      key: _formCorreo,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validadores.correo,
            onFieldSubmitted: (_) => _enviarCodigo(),
            decoration: const InputDecoration(
              labelText: 'CORREO ELECTRÓNICO',
              hintText: 'tu@correo.com',
              prefixIcon: Icon(Icons.mail_outline,
                  color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargando ? null : _enviarCodigo,
            child: _cargando ? const _Cargando() : const Text('ENVIAR CÓDIGO'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cargando ? null : () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.cafeMedio, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _pasoClave() {
    return Form(
      key: _formClave,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codigoCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => (v == null || v.trim().length != 6)
                ? 'Ingresa los 6 dígitos del código'
                : null,
            style: GoogleFonts.inter(fontSize: 20, letterSpacing: 8),
            decoration: const InputDecoration(
              labelText: 'CÓDIGO',
              counterText: '',
              prefixIcon:
                  Icon(Icons.pin_outlined, color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pwdCtrl,
            obscureText: _ocultar,
            textInputAction: TextInputAction.next,
            validator: Validadores.password,
            decoration: InputDecoration(
              labelText: 'NUEVA CONTRASEÑA',
              helperText: '8 caracteres o más, una mayúscula y un número',
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _pwd2Ctrl,
            obscureText: _ocultar,
            textInputAction: TextInputAction.done,
            validator: (v) => Validadores.confirmarPassword(v, _pwdCtrl.text),
            onFieldSubmitted: (_) => _cambiarPassword(),
            decoration: const InputDecoration(
              labelText: 'CONFIRMAR CONTRASEÑA',
              prefixIcon: Icon(Icons.lock_outline,
                  color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargando ? null : _cambiarPassword,
            child: _cargando
                ? const _Cargando()
                : const Text('CAMBIAR CONTRASEÑA'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_segundos > 0 || _cargando)
                ? null
                : () => _enviarCodigo(reenvio: true),
            child: Text(
              _segundos > 0
                  ? 'Reenviar código en ${_segundos}s'
                  : 'Reenviar código',
              style: GoogleFonts.inter(
                  color: AppColors.cafeMedio, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crema),
      );
}

class _Aviso extends StatelessWidget {
  final String mensaje;
  const _Aviso({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
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
