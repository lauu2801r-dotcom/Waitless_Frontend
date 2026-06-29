import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';
import 'admin/admin_shell.dart';
import 'main_shell.dart';

class VerificacionScreen extends StatefulWidget {
  final String correo;
  final String? codigoSimulado;

  const VerificacionScreen({
    super.key,
    required this.correo,
    this.codigoSimulado,
  });

  @override
  State<VerificacionScreen> createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focos = List.generate(6, (_) => FocusNode());

  bool _verificando = false;
  String? _error;

  Timer? _timer;
  int _segundosRestantes = 60;
  String? _codigoSimuladoActual;

  @override
  void initState() {
    super.initState();
    _codigoSimuladoActual = widget.codigoSimulado;
    _iniciarCuentaRegresiva();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focos[0].requestFocus();
    });
  }

  void _iniciarCuentaRegresiva() {
    _timer?.cancel();
    setState(() => _segundosRestantes = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 0) {
        t.cancel();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focos) {
      f.dispose();
    }
    super.dispose();
  }

  String get _codigoIngresado => _ctrls.map((c) => c.text).join();

  Future<void> _verificar() async {
    setState(() => _error = null);
    if (_codigoIngresado.length < 6) {
      setState(() => _error = 'Ingresa los 6 dígitos del código');
      return;
    }

    setState(() => _verificando = true);
    final auth = AuthScope.of(context);
    final resultado = await auth.verificarCodigo(
      correo: widget.correo,
      codigo: _codigoIngresado,
    );
    if (!mounted) return;
    setState(() => _verificando = false);

    switch (resultado) {
      case AuthExito():
        final destino = auth.esAdministrador
            ? const AdminShell()
            : const MainShell();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destino),
          (_) => false,
        );
      case AuthError(:final mensaje):
        setState(() {
          _error = mensaje;
          for (final c in _ctrls) {
            c.clear();
          }
          _focos[0].requestFocus();
        });
    }
  }

  Future<void> _reenviar() async {
    final auth = AuthScope.of(context);
    final resultado = await auth.reenviarCodigo(widget.correo);
    if (!mounted) return;
    switch (resultado) {
      case AuthExito(:final datos):
        setState(() => _codigoSimuladoActual = datos);
        _iniciarCuentaRegresiva();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nuevo código enviado',
                style: GoogleFonts.inter(color: AppColors.crema)),
            backgroundColor: AppColors.cafeOscuro,
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.cremaOscura,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined,
                          color: AppColors.terracota, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Verifica tu correo',
                      textAlign: TextAlign.center,
                      style: AppTheme.titulo(size: 26)),
                  const SizedBox(height: 8),
                  Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.cafeMedio, height: 1.5),
                      children: [
                        const TextSpan(text: 'Enviamos un código de 6 dígitos a\n'),
                        TextSpan(
                          text: widget.correo,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.cafeOscuro,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  if (_codigoSimuladoActual != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.olivaFondo,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.oliva.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.infoTexto, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.infoTexto,
                                    height: 1.4),
                                children: [
                                  const TextSpan(text: 'Modo demo: tu código es '),
                                  TextSpan(
                                    text: _codigoSimuladoActual!,
                                    style: GoogleFonts.robotoMono(
                                        fontSize: 13,
                                        color: AppColors.infoTexto,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2),
                                  ),
                                  const TextSpan(
                                      text: '. Con API real, llegará a tu correo.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  if (_error != null) ...[
                    _BannerError(mensaje: _error!),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _CampoDigito(
                          controlador: _ctrls[i],
                          foco: _focos[i],
                          onCambio: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focos[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focos[i - 1].requestFocus();
                            }
                            if (_codigoIngresado.length == 6) {
                              _verificar();
                            }
                          },
                        )),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _verificando ? null : _verificar,
                    child: _verificando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.crema,
                            ),
                          )
                        : const Text('VERIFICAR'),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: _segundosRestantes > 0
                        ? Text(
                            'Reenviar código en ${_segundosRestantes}s',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.cafeMedio),
                          )
                        : TextButton(
                            onPressed: _reenviar,
                            child: Text(
                              'Reenviar código',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.terracota,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _CampoDigito extends StatelessWidget {
  final TextEditingController controlador;
  final FocusNode foco;
  final ValueChanged<String> onCambio;

  const _CampoDigito({
    required this.controlador,
    required this.foco,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controlador,
        focusNode: foco,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontStyle: FontStyle.italic,
          color: AppColors.cafeOscuro,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borde),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borde),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.terracota, width: 1.5),
          ),
        ),
        onChanged: onCambio,
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