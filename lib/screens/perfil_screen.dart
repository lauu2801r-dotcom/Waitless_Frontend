import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import '../utils/app_strings.dart';
import 'login_screen.dart';
import 'cliente_facturas_screen.dart';
import 'pedidos_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _notifPedidos = true;
  bool _notifPromos = true;
  bool _notifReservas = false;

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Cerrar sesión?', style: AppTheme.titulo(size: 20)),
        content: Text(
          'Tendrás que iniciar sesión de nuevo para ver tus pedidos.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar sesión',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await AuthScope.of(context).cerrarSesion();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  void _abrirHoja({required String titulo, required Widget contenido}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
              const SizedBox(height: 16),
              Text(titulo, style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: contenido,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFavoritos() {
    _abrirHoja(
      titulo: 'Tus favoritos',
      contenido: const Column(
        children: [
          _ItemFavorito(emoji: '🍝', nombre: 'Pasta al pesto', precio: '\$28.500'),
          _ItemFavorito(emoji: '🐟', nombre: 'Salmón a las hierbas', precio: '\$38.500'),
          _ItemFavorito(emoji: '🍰', nombre: 'Tiramisú casero', precio: '\$14.000'),
          _ItemFavorito(emoji: '🥥', nombre: 'Limonada de coco', precio: '\$9.500'),
          _ItemFavorito(emoji: '🍚', nombre: 'Risotto de hongos', precio: '\$32.000'),
        ],
      ),
    );
  }

  void _mostrarMetodosPago() {
    _abrirHoja(
      titulo: 'Métodos de pago',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TarjetaPago(
            tipo: 'Visa',
            ultimos: '••• 4242',
            principal: true,
            color: Color(0xFF1A1F71),
          ),
          const SizedBox(height: 10),
          const _TarjetaPago(
            tipo: 'Mastercard',
            ultimos: '••• 8801',
            color: Color(0xFFEB001B),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _formAgregarTarjeta();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.terracota),
              foregroundColor: AppColors.terracota,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('AGREGAR MÉTODO'),
          ),
        ],
      ),
    );
  }

  void _formAgregarTarjeta() {
    final numCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    _abrirHoja(
      titulo: 'Nueva tarjeta',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: numCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'NÚMERO',
              hintText: '4242 4242 4242 4242',
              prefixIcon:
                  Icon(Icons.credit_card, color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'NOMBRE EN LA TARJETA',
              hintText: 'LAURA GONZALEZ',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fechaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'VENCE',
                    hintText: 'MM/AA',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cvvCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _toast('Tarjeta agregada correctamente');
            },
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('GUARDAR TARJETA'),
          ),
        ],
      ),
    );
  }

  void _formAgregarDireccion() {
    final etiqCtrl = TextEditingController();
    final dirCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    _abrirHoja(
      titulo: 'Nueva dirección',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: etiqCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'ETIQUETA',
              hintText: 'CASA, OFICINA, GIMNASIO...',
              prefixIcon: Icon(Icons.label_outline,
                  color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dirCtrl,
            decoration: const InputDecoration(
              labelText: 'DIRECCIÓN',
              hintText: 'Cra. 11 #82-71, apto 502',
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: AppColors.cafeMedio, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notasCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'NOTAS PARA EL DOMICILIARIO',
              hintText: 'Portería del 2do piso, casa azul...',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _toast('Dirección guardada');
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('GUARDAR DIRECCIÓN'),
          ),
        ],
      ),
    );
  }

  void _editarFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
            Text('Foto de perfil',
                textAlign: TextAlign.center,
                style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 16),
            _OpcionFoto(
              icono: Icons.camera_alt_outlined,
              titulo: 'Tomar foto',
              onTap: () {
                Navigator.pop(ctx);
                _toast('Cámara abierta');
              },
            ),
            _OpcionFoto(
              icono: Icons.photo_library_outlined,
              titulo: 'Elegir de galería',
              onTap: () {
                Navigator.pop(ctx);
                _toast('Galería abierta');
              },
            ),
            _OpcionFoto(
              icono: Icons.delete_outline,
              titulo: 'Quitar foto actual',
              destructivo: true,
              onTap: () {
                Navigator.pop(ctx);
                _toast('Foto eliminada');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDirecciones() {
    _abrirHoja(
      titulo: 'Mis direcciones',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ItemDireccion(
            etiqueta: 'CASA',
            direccion: 'Cra. 11 #82-71, Bogotá',
            principal: true,
          ),
          const SizedBox(height: 10),
          const _ItemDireccion(
            etiqueta: 'OFICINA',
            direccion: 'Calle 100 #19-54, Bogotá',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _formAgregarDireccion();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.terracota),
              foregroundColor: AppColors.terracota,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('AGREGAR DIRECCIÓN'),
          ),
        ],
      ),
    );
  }

  void _mostrarNotificaciones() {
    _abrirHoja(
      titulo: 'Notificaciones',
      contenido: StatefulBuilder(
        builder: (ctx, setS) => Column(
          children: [
            _SwitchOpcion(
              titulo: 'Estado de pedidos',
              descripcion: 'Recibe alertas cuando cambia el estado',
              valor: _notifPedidos,
              onCambio: (v) => setS(() {
                _notifPedidos = v;
                setState(() {});
              }),
            ),
            _SwitchOpcion(
              titulo: 'Promociones',
              descripcion: 'Ofertas y descuentos del restaurante',
              valor: _notifPromos,
              onCambio: (v) => setS(() {
                _notifPromos = v;
                setState(() {});
              }),
            ),
            _SwitchOpcion(
              titulo: 'Recordatorio de reservas',
              descripcion: '1 hora antes de tu reserva',
              valor: _notifReservas,
              onCambio: (v) => setS(() {
                _notifReservas = v;
                setState(() {});
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelector(
      String titulo, List<String> opciones, String actual, void Function(String) onSelect) {
    _abrirHoja(
      titulo: titulo,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: opciones.map((op) {
          final selec = op == actual;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                onSelect(op);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selec
                      ? AppColors.terracota.withValues(alpha: 0.08)
                      : AppColors.superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selec ? AppColors.terracota : AppColors.borde,
                    width: selec ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        op,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: selec ? FontWeight.w600 : FontWeight.w400,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                    ),
                    if (selec)
                      const Icon(Icons.check_circle,
                          color: AppColors.terracota, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _mostrarAyuda() {
    _abrirHoja(
      titulo: 'Centro de ayuda',
      contenido: const Column(
        children: [
          _ItemAyuda(
              pregunta: '¿Cómo hago una reserva?',
              respuesta:
                  'Desde la pestaña Inicio, toca "Reservar mesa" y elige fecha, hora y número de personas.'),
          _ItemAyuda(
              pregunta: '¿Cómo cancelo un pedido?',
              respuesta:
                  'Solo se pueden cancelar pedidos en estado "Recibido". Ve a Pedidos > toca el pedido > Cancelar.'),
          _ItemAyuda(
              pregunta: '¿Qué métodos de pago aceptan?',
              respuesta:
                  'Aceptamos Visa, Mastercard, American Express, PSE y Nequi.'),
          _ItemAyuda(
              pregunta: '¿Cómo subo de nivel?',
              respuesta:
                  'Acumula visitas y pedidos. Cada nivel desbloquea descuentos y experiencias exclusivas.'),
        ],
      ),
    );
  }

  void _mostrarPrivacidad() {
    _abrirHoja(
      titulo: 'Privacidad',
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'En WaitLess, tu información es tuya. Solo recopilamos lo necesario para mejorar tu experiencia gastronómica.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.cafeOscuro,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...const [
            _PuntoPrivacidad(
                texto: 'Nunca vendemos tus datos personales a terceros.'),
            _PuntoPrivacidad(
                texto: 'Cifrado de extremo a extremo en pagos y mensajes.'),
            _PuntoPrivacidad(
                texto:
                    'Puedes solicitar la eliminación de tu cuenta cuando quieras.'),
            _PuntoPrivacidad(
                texto:
                    'Las predicciones de afluencia usan datos anónimos agregados.'),
          ],
        ],
      ),
    );
  }

  void _mostrarAcercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'WaitLess',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.terracota,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'W',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontStyle: FontStyle.italic,
              color: AppColors.crema,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      applicationLegalese:
          '© 2026 WaitLess\nReserva tu mesa, conoce el momento ideal y vive la mejor experiencia gastronómica.',
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthScope.of(context).usuario;
    final nombre = usuario?.nombreCompleto ?? 'Invitado';
    final inicial = usuario?.inicial ?? '?';
    final fechaReg = usuario?.fechaRegistro;
    final anoReg = fechaReg?.year.toString() ?? '—';
    final conDatos = usuario?.conDatos ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppColors.terracota,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.terracota
                                    .withValues(alpha: 0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              inicial,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 44,
                                fontStyle: FontStyle.italic,
                                color: AppColors.crema,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: AppColors.cafeOscuro,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _editarFoto,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.crema, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    color: AppColors.crema, size: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(nombre, style: AppTheme.titulo(size: 22)),
                    if (usuario != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        usuario.correo,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.cafeMedio),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.t(context, 'cliente_desde')} $anoReg',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.cafeMedio),
                    ),
                    if (conDatos) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cremaOscura,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.t(context, 'miembro'),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: AppColors.cafeMedio,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Oro',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.terracota,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                      child: _EstadisticaTarjeta(
                          valor: conDatos ? '12' : '0',
                          etiqueta:
                              AppStrings.t(context, 'visitas'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _EstadisticaTarjeta(
                          valor: conDatos ? '4.8' : '—',
                          etiqueta:
                              AppStrings.t(context, 'calif_prom'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _EstadisticaTarjeta(
                          valor: conDatos ? '5' : '0',
                          etiqueta:
                              AppStrings.t(context, 'favoritos').toUpperCase())),
                ],
              ),

              const SizedBox(height: 24),

              if (conDatos) Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cafeOscuro, Color(0xFF52341F)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium,
                            color: Color(0xFFD9B896), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PROGRESO A NIVEL PLATINO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: AppColors.cremaOscura,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '12',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: AppColors.crema,
                          ),
                        ),
                        Text(
                          '/20 visitas',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.cremaOscura,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: 12 / 20,
                        minHeight: 7,
                        backgroundColor:
                            AppColors.crema.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFD9B896)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Te faltan 8 visitas para subir de nivel y desbloquear ventajas exclusivas.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.cremaOscura,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              if (conDatos) const SizedBox(height: 28),

              Text(AppStrings.t(context, 'cuenta'), style: AppTheme.etiqueta()),
              const SizedBox(height: 10),
              _GrupoOpciones(opciones: [
                _OpcionMenu(Icons.receipt_long_outlined,
                    AppStrings.t(context, 'mis_pedidos'),
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PedidosScreen(),
                          ),
                        )),
                _OpcionMenu(Icons.description_outlined,
                    AppStrings.t(context, 'mis_facturas'),
                    valor: conDatos ? '5' : '0',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClienteFacturasScreen(),
                          ),
                        )),
                _OpcionMenu(Icons.favorite_border,
                    AppStrings.t(context, 'favoritos'),
                    valor: conDatos ? '5' : '0',
                    onTap: _mostrarFavoritos),
                _OpcionMenu(Icons.credit_card_outlined,
                    AppStrings.t(context, 'metodos_pago'),
                    valor: conDatos ? '2' : '0',
                    onTap: _mostrarMetodosPago),
                _OpcionMenu(Icons.location_on_outlined,
                    AppStrings.t(context, 'direcciones'),
                    valor: conDatos ? '2' : '0',
                    onTap: _mostrarDirecciones),
              ]),

              const SizedBox(height: 20),

              Text(AppStrings.t(context, 'preferencias'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 10),
              Builder(builder: (ctx) {
                final settings = AppSettingsScope.of(ctx);
                return _GrupoOpciones(opciones: [
                  _OpcionMenu(Icons.notifications_outlined,
                      AppStrings.t(ctx, 'notificaciones'),
                      onTap: _mostrarNotificaciones),
                  _OpcionMenu(
                      Icons.language, AppStrings.t(ctx, 'idioma'),
                      valor: settings.idiomaLabel,
                      onTap: () => _mostrarSelector(
                            AppStrings.t(ctx, 'idioma'),
                            const ['Español', 'English', 'Português'],
                            settings.idiomaLabel,
                            (v) => settings.setIdioma(v),
                          )),
                  _OpcionMenu(Icons.dark_mode_outlined,
                      AppStrings.t(ctx, 'apariencia'),
                      valor: settings.aparienciaLabel,
                      onTap: () => _mostrarSelector(
                            AppStrings.t(ctx, 'apariencia'),
                            const ['Claro', 'Oscuro', 'Sistema'],
                            settings.aparienciaLabel,
                            (v) => settings.setApariencia(v),
                          )),
                ]);
              }),

              const SizedBox(height: 20),

              Text(AppStrings.t(context, 'soporte'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 10),
              _GrupoOpciones(opciones: [
                _OpcionMenu(Icons.help_outline,
                    AppStrings.t(context, 'ayuda'),
                    onTap: _mostrarAyuda),
                _OpcionMenu(Icons.privacy_tip_outlined,
                    AppStrings.t(context, 'privacidad'),
                    onTap: _mostrarPrivacidad),
                _OpcionMenu(Icons.info_outline,
                    AppStrings.t(context, 'acerca_de'),
                    onTap: _mostrarAcercaDe),
              ]),

              const SizedBox(height: 28),

              InkWell(
                onTap: _cerrarSesion,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppStrings.t(context, 'cerrar_sesion'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.terracota,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'v 1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.cafeMedio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadisticaTarjeta extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _EstadisticaTarjeta({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: [
          Text(valor, style: AppTheme.titulo(size: 24)),
          const SizedBox(height: 2),
          Text(etiqueta, style: AppTheme.etiqueta(size: 9)),
        ],
      ),
    );
  }
}

class _GrupoOpciones extends StatelessWidget {
  final List<_OpcionMenu> opciones;
  const _GrupoOpciones({required this.opciones});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        children: List.generate(opciones.length, (i) {
          final op = opciones[i];
          final ultimo = i == opciones.length - 1;
          return InkWell(
            onTap: op.onTap,
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : ultimo
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(14))
                    : BorderRadius.zero,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: ultimo
                      ? BorderSide.none
                      : const BorderSide(
                          color: AppColors.bordeSuave, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(op.icono, color: AppColors.cafeOscuro, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(op.titulo,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.cafeOscuro)),
                  ),
                  if (op.valor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        op.valor!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.cafeMedio),
                      ),
                    ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.cafeMedio, size: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OpcionMenu {
  final IconData icono;
  final String titulo;
  final String? valor;
  final VoidCallback? onTap;
  _OpcionMenu(this.icono, this.titulo, {this.valor, this.onTap});
}

class _ItemFavorito extends StatelessWidget {
  final String emoji;
  final String nombre;
  final String precio;
  const _ItemFavorito({
    required this.emoji,
    required this.nombre,
    required this.precio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 4),
                Text(precio,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracota)),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: AppColors.terracota, size: 20),
        ],
      ),
    );
  }
}

class _TarjetaPago extends StatelessWidget {
  final String tipo;
  final String ultimos;
  final Color color;
  final bool principal;
  const _TarjetaPago({
    required this.tipo,
    required this.ultimos,
    required this.color,
    this.principal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tipo,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.crema)),
              if (principal)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.crema.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('PRINCIPAL',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.crema,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(ultimos,
              style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: AppColors.crema)),
        ],
      ),
    );
  }
}

class _ItemDireccion extends StatelessWidget {
  final String etiqueta;
  final String direccion;
  final bool principal;
  const _ItemDireccion({
    required this.etiqueta,
    required this.direccion,
    this.principal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.terracota.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on,
                color: AppColors.terracota, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(etiqueta,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cafeOscuro)),
                    if (principal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.olivaFondo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Principal',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: AppColors.infoTexto,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(direccion,
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.cafeMedio)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchOpcion extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final bool valor;
  final ValueChanged<bool> onCambio;
  const _SwitchOpcion({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cafeOscuro)),
                const SizedBox(height: 2),
                Text(descripcion,
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: AppColors.cafeMedio)),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onCambio,
            activeThumbColor: AppColors.crema,
            activeTrackColor: AppColors.terracota,
          ),
        ],
      ),
    );
  }
}

class _ItemAyuda extends StatelessWidget {
  final String pregunta;
  final String respuesta;
  const _ItemAyuda({required this.pregunta, required this.respuesta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: AppColors.terracota,
        collapsedIconColor: AppColors.cafeMedio,
        title: Text(pregunta,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.cafeOscuro)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(respuesta,
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.cafeMedio,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _PuntoPrivacidad extends StatelessWidget {
  final String texto;
  const _PuntoPrivacidad({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle,
                color: AppColors.oliva, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.cafeOscuro,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _OpcionFoto extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;
  final bool destructivo;
  const _OpcionFoto({
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.destructivo = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructivo ? AppColors.terracota : AppColors.cafeOscuro;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (destructivo
                          ? AppColors.terracota
                          : AppColors.cafeOscuro)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(titulo,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
