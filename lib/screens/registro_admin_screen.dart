import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'verificacion_screen.dart';

class RegistroAdminScreen extends StatefulWidget {
  const RegistroAdminScreen({super.key});

  @override
  State<RegistroAdminScreen> createState() => _RegistroAdminScreenState();
}

class _RegistroAdminScreenState extends State<RegistroAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _restauranteCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _codigoNegocioCtrl = TextEditingController();

  bool _ocultarPwd = true;
  bool _ocultarConfirm = true;
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _restauranteCtrl.dispose();
    _correoCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _codigoNegocioCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _errorGeneral = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      setState(() =>
          _errorGeneral = 'Debes aceptar los términos para continuar');
      return;
    }

    setState(() => _cargando = true);
    final auth = AuthScope.of(context);
    final resultado = await auth.registrarAdministrador(
      nombreCompleto: _nombreCtrl.text,
      correo: _correoCtrl.text,
      password: _pwdCtrl.text,
      nombreRestaurante: _restauranteCtrl.text,
      codigoNegocio: _codigoNegocioCtrl.text,
    );
    if (!mounted) return;
    setState(() => _cargando = false);

    switch (resultado) {
      case AuthExito(:final datos):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificacionScreen(
              correo: _correoCtrl.text.trim().toLowerCase(),
              codigoSimulado: datos,
            ),
          ),
        );
      case AuthError(:final mensaje):
        setState(() => _errorGeneral = mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Registrar restaurante', style: AppTheme.titulo(size: 20)),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cafeOscuro,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  color: AppColors.crema, size: 20),
                              const SizedBox(width: 8),
                              Text('PORTAL DE NEGOCIOS',
                                  style: AppTheme.etiqueta(
                                      size: 11,
                                      color: AppColors.cremaOscura)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lleva tu restaurante al siguiente nivel',
                            style: AppTheme.titulo(
                                size: 22, color: AppColors.crema),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gestiona pedidos, mesas y predicciones de afluencia con datos en tiempo real.',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.cremaOscura,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_errorGeneral != null) ...[
                      _BannerError(mensaje: _errorGeneral!),
                      const SizedBox(height: 16),
                    ],

                    Text('DATOS DEL ADMINISTRADOR',
                        style: AppTheme.etiqueta()),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.nombreCompleto,
                      decoration: const InputDecoration(
                        labelText: 'NOMBRE COMPLETO',
                        hintText: 'María Rodríguez',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.correo,
                      decoration: const InputDecoration(
                        labelText: 'CORREO CORPORATIVO',
                        hintText: 'admin@turestaurante.com',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('DATOS DEL NEGOCIO', style: AppTheme.etiqueta()),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _restauranteCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) {
                          return 'El nombre del restaurante es obligatorio';
                        }
                        if (t.length < 3) return 'Nombre demasiado corto';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'NOMBRE DEL RESTAURANTE',
                        hintText: 'El Buen Sabor',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _codigoNegocioCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) {
                          return 'El código de negocio es obligatorio';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'CÓDIGO DE NEGOCIO',
                        hintText: 'WAITLESS2024',
                        helperText:
                            'Demo: usa el código WAITLESS2024 para registrarte',
                        helperStyle: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.oliva),
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('SEGURIDAD', style: AppTheme.etiqueta()),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pwdCtrl,
                      obscureText: _ocultarPwd,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.password,
                      decoration: InputDecoration(
                        labelText: 'CONTRASEÑA',
                        helperText:
                            'Mínimo 8 caracteres, una mayúscula y un número',
                        helperStyle: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.cafeMedio),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarPwd
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.cafeMedio,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarPwd = !_ocultarPwd),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPwdCtrl,
                      obscureText: _ocultarConfirm,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validadores.confirmarPassword(v, _pwdCtrl.text),
                      decoration: InputDecoration(
                        labelText: 'CONFIRMAR CONTRASEÑA',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.cafeMedio,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _ocultarConfirm = !_ocultarConfirm),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    InkWell(
                      onTap: () =>
                          setState(() => _aceptaTerminos = !_aceptaTerminos),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _aceptaTerminos
                                    ? AppColors.terracota
                                    : AppColors.superficie,
                                border: Border.all(
                                  color: _aceptaTerminos
                                      ? AppColors.terracota
                                      : AppColors.borde,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _aceptaTerminos
                                  ? const Icon(Icons.check,
                                      color: AppColors.crema, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Acepto los Términos del Portal de Negocios y autorizo el procesamiento de datos del establecimiento.',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.cafeOscuro,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.crema,
                              ),
                            )
                          : const Text('REGISTRAR MI NEGOCIO'),
                    ),

                    const SizedBox(height: 20),
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