import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import 'verificacion_screen.dart';
import 'registro_admin_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _ocultarPwd = true;
  bool _ocultarConfirm = true;
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _errorGeneral;
  int _fortaleza = 0;

  @override
  void initState() {
    super.initState();
    _pwdCtrl.addListener(() {
      setState(() {
        _fortaleza = Validadores.fortalezaPassword(_pwdCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _errorGeneral = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      setState(() => _errorGeneral =
          'Debes aceptar los términos y condiciones para continuar');
      return;
    }

    setState(() => _cargando = true);
    final auth = AuthScope.of(context);
    final resultado = await auth.registrarCliente(
        nombreCompleto: _nombreCtrl.text,
        correo: _correoCtrl.text,
        password: _pwdCtrl.text,
        telefono: _telefonoCtrl.text.isEmpty ? null : _telefonoCtrl.text,
      );
    if (!mounted) return;
    setState(() => _cargando = false);

    switch (resultado) {
      case AuthExito(:final datos):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificacionScreen(
              correo: _correoCtrl.text.trim().toLowerCase(),
              codigoSimulado: null,
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Encabezado con botón volver y logo
                    _Encabezado(onVolver: () => Navigator.pop(context)),
                    const SizedBox(height: 20),

                    // Título principal
                    Text(
                      'Crea tu cuenta',
                      style: AppTheme.titulo(size: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Únete y reserva tu mesa en los mejores restaurantes.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.cafeMedio,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Banner de error general
                    if (_errorGeneral != null) ...[
                      _BannerError(mensaje: _errorGeneral!),
                      const SizedBox(height: 16),
                    ],

                    // Tarjeta con el formulario
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borde),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.cafeOscuro.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nombre completo
                          const _EtiquetaCampo(
                            texto: 'Nombre completo',
                            icono: Icons.person_outline,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nombreCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: Validadores.nombreCompleto,
                            decoration: const InputDecoration(
                              hintText: 'Ej. Laura González',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.cafeMedio,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Correo electrónico
                          const _EtiquetaCampo(
                            texto: 'Correo electrónico',
                            icono: Icons.mail_outline,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _correoCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validadores.correo,
                            decoration: const InputDecoration(
                              hintText: 'tu@correo.com',
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                color: AppColors.cafeMedio,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Teléfono
                          const _EtiquetaCampo(
                            texto: 'Teléfono',
                            icono: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _telefonoCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Ej. 3001234567',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppColors.cafeMedio,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Contraseña
                          const _EtiquetaCampo(
                            texto: 'Contraseña',
                            icono: Icons.lock_outline,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _pwdCtrl,
                            obscureText: _ocultarPwd,
                            textInputAction: TextInputAction.next,
                            validator: Validadores.password,
                            decoration: InputDecoration(
                              hintText: 'Mínimo 8 caracteres',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.cafeMedio,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarPwd
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.cafeMedio,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _ocultarPwd = !_ocultarPwd),
                              ),
                            ),
                          ),
                          if (_pwdCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MedidorFortaleza(nivel: _fortaleza),
                            const SizedBox(height: 12),
                            _RequisitosPassword(password: _pwdCtrl.text),
                          ] else ...[
                            const SizedBox(height: 6),
                            Text(
                              'Usa al menos 8 caracteres, una mayúscula y un número.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.cafeMedio,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Confirmar contraseña
                          const _EtiquetaCampo(
                            texto: 'Confirmar contraseña',
                            icono: Icons.lock_outline,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPwdCtrl,
                            obscureText: _ocultarConfirm,
                            textInputAction: TextInputAction.done,
                            validator: (v) => Validadores.confirmarPassword(
                                v, _pwdCtrl.text),
                            onFieldSubmitted: (_) => _registrar(),
                            decoration: InputDecoration(
                              hintText: 'Repite tu contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.cafeMedio,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.cafeMedio,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _ocultarConfirm = !_ocultarConfirm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Términos y condiciones
                          InkWell(
                            onTap: () => setState(
                                () => _aceptaTerminos = !_aceptaTerminos),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(top: 1),
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
                                        ? const Icon(
                                            Icons.check,
                                            color: AppColors.crema,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: AppColors.cafeOscuro,
                                          height: 1.45,
                                        ),
                                        children: const [
                                          TextSpan(text: 'Acepto los '),
                                          TextSpan(
                                            text: 'Términos y Condiciones',
                                            style: TextStyle(
                                              color: AppColors.terracota,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' y la '),
                                          TextSpan(
                                            text: 'Política de Privacidad',
                                            style: TextStyle(
                                              color: AppColors.terracota,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                              text: ' de Sabor & Datos.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón principal
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _registrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracota,
                          foregroundColor: AppColors.crema,
                          disabledBackgroundColor:
                              AppColors.terracota.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _cargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.crema,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREAR MI CUENTA',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: AppColors.crema,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward,
                                      size: 18, color: AppColors.crema),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Separador para el registro de negocio
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.borde)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '¿ERES UN NEGOCIO?',
                            style: AppTheme.etiqueta(size: 10),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.borde)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta para registro de administrador
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegistroAdminScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.cafeOscuro,
                              Color(0xFF52341F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cafeOscuro
                                  .withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.terracota
                                    .withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.terracota
                                      .withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: AppColors.crema,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registra tu restaurante',
                                    style: AppTheme.titulo(
                                      size: 17,
                                      color: AppColors.crema,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Gestiona pedidos, mesas y predicciones',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.cremaOscura,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.crema.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.crema,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Enlace iniciar sesión
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.cafeMedio,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Inicia sesión',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.terracota,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.terracota,
                                decorationThickness: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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

/// Encabezado con botón de volver y logo a la derecha.
class _Encabezado extends StatelessWidget {
  final VoidCallback onVolver;
  const _Encabezado({required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botón volver
        Material(
          color: AppColors.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borde),
          ),
          child: InkWell(
            onTap: onVolver,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
        ),
        // Logo decorativo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.terracota,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.terracota.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'S',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: AppColors.crema,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta pequeña con tracking encima de cada campo.
class _EtiquetaCampo extends StatelessWidget {
  final String texto;
  final IconData icono;
  const _EtiquetaCampo({required this.texto, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        letterSpacing: 1.1,
        color: AppColors.cafeOscuro,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Medidor visual de fortaleza de la contraseña.
class _MedidorFortaleza extends StatelessWidget {
  final int nivel;
  const _MedidorFortaleza({required this.nivel});

  @override
  Widget build(BuildContext context) {
    final colores = [
      AppColors.cremaOscura,
      AppColors.terracotaOscuro,
      AppColors.terracota,
      const Color(0xFFD9B896),
      AppColors.oliva,
    ];
    final etiquetas = [
      'Muy débil',
      'Débil',
      'Aceptable',
      'Buena',
      'Excelente',
    ];
    final color = colores[nivel];
    return Row(
      children: [
        ...List.generate(4, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < nivel ? color : AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text(
            etiquetas[nivel],
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lista visual de requisitos que cumple/no cumple la contraseña.
class _RequisitosPassword extends StatelessWidget {
  final String password;
  const _RequisitosPassword({required this.password});

  @override
  Widget build(BuildContext context) {
    final reqs = [
      ('8 caracteres o más', password.length >= 8),
      ('Una mayúscula', RegExp(r'[A-Z]').hasMatch(password)),
      ('Un número', RegExp(r'[0-9]').hasMatch(password)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: reqs.map((r) => _Requisito(texto: r.$1, ok: r.$2)).toList(),
    );
  }
}

class _Requisito extends StatelessWidget {
  final String texto;
  final bool ok;
  const _Requisito({required this.texto, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ok ? AppColors.exitoFondo : AppColors.cremaOscura,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: ok ? AppColors.exitoTexto : AppColors.cafeMedio,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: ok ? AppColors.exitoTexto : AppColors.cafeMedio,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.alertaFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.terracota.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.terracotaOscuro,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.terracotaOscuro,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
