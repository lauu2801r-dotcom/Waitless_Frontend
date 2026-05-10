import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../login_screen.dart';

class AdminPerfilScreen extends StatelessWidget {
  const AdminPerfilScreen({super.key});

  void _abrirHoja(BuildContext context,
      {required String titulo,
      required String descripcion,
      required IconData icono}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.terracota.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    Icon(icono, color: AppColors.terracota, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 8),
            Text(descripcion,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                  height: 1.5,
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Cerrar sesión?', style: AppTheme.titulo(size: 20)),
        content: Text(
          'Volverás a la pantalla de inicio de sesión.',
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
            child: Text(AppStrings.t(context, 'cerrar_sesion'),
                style: GoogleFonts.inter(
                    color: AppColors.terracota,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await AuthScope.of(context).cerrarSesion();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    final usuario = auth?.usuario;
    final restaurante = usuario?.nombreRestaurante ?? 'El Buen Sabor';
    final nombreAdmin = usuario?.nombreCompleto ?? 'Administrador';
    final correo = usuario?.correo ?? 'admin@elbuensabor.com';
    final conDatos = usuario?.conDatos ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppStrings.t(context, 'mi_negocio'),
                  style: AppTheme.titulo(size: 30)),
              const SizedBox(height: 4),
              Text(AppStrings.t(context, 'gestion_restaurante'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 24),

              // Tarjeta del restaurante
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cafeOscuro,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.terracota,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.restaurant,
                              color: AppColors.crema, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.t(context, 'tu_restaurante'),
                                  style: AppTheme.etiqueta(
                                      size: 10,
                                      color: AppColors.cremaOscura)),
                              const SizedBox(height: 4),
                              Text(restaurante,
                                  style: AppTheme.titulo(
                                      size: 22, color: AppColors.crema),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('Centro · Bogotá',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.cremaOscura)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricaResumen(
                            valor: conDatos ? '4.8' : '—',
                            label: 'CALIF.',
                            icon: Icons.star,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.cremaOscura.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _MetricaResumen(
                            valor: conDatos ? '342' : '0',
                            label: 'CLIENTES',
                            icon: Icons.people_outline,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.cremaOscura.withValues(alpha: 0.3),
                        ),
                        Expanded(
                          child: _MetricaResumen(
                            valor: conDatos ? '14' : '0',
                            label: 'MESAS',
                            icon: Icons.table_restaurant_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Perfil del administrador
              Text(AppStrings.t(context, 'tus_datos'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.terracota,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          usuario?.inicial ?? 'A',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontStyle: FontStyle.italic,
                            color: AppColors.crema,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombreAdmin,
                              style: AppTheme.titulo(size: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(correo,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.cafeMedio),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.olivaFondo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppStrings.t(context, 'administrador'),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.oliva,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gestión del negocio
              Text(AppStrings.t(context, 'gestion_negocio'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              _GrupoOpciones(opciones: [
                _OpcionMenu(Icons.menu_book_outlined, 'Menú y precios',
                    valor: '12 platos',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Menú y precios',
                        descripcion:
                            'Edita platos, precios y categorías. Sincroniza tu carta con la app de clientes.',
                        icono: Icons.menu_book_outlined)),
                _OpcionMenu(Icons.table_restaurant_outlined, 'Mesas',
                    valor: '14 mesas',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Gestión de mesas',
                        descripcion:
                            'Configura el plano del salón, capacidades y zonas (terraza, salón, privado).',
                        icono: Icons.table_restaurant_outlined)),
                _OpcionMenu(Icons.access_time, 'Horarios de atención',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Horarios',
                        descripcion:
                            'Define los días y horas de apertura, así como pausas y días festivos.',
                        icono: Icons.access_time)),
                _OpcionMenu(Icons.location_on_outlined, 'Ubicación y contacto',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Ubicación y contacto',
                        descripcion:
                            'Actualiza la dirección, teléfono y redes sociales de tu restaurante.',
                        icono: Icons.location_on_outlined)),
                _OpcionMenu(Icons.image_outlined, 'Galería del restaurante',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Galería',
                        descripcion:
                            'Sube fotos de tus platos, ambiente y eventos para atraer más clientes.',
                        icono: Icons.image_outlined)),
              ]),

              const SizedBox(height: 20),

              Text(AppStrings.t(context, 'operaciones'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              _GrupoOpciones(opciones: [
                _OpcionMenu(Icons.people_outline, 'Personal del restaurante',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Personal',
                        descripcion:
                            'Administra meseros, cocineros y cajeros. Asigna roles y permisos.',
                        icono: Icons.people_outline)),
                _OpcionMenu(Icons.inventory_2_outlined, 'Inventario',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Inventario',
                        descripcion:
                            'Controla stock de ingredientes y bebidas. Recibe alertas de bajo inventario.',
                        icono: Icons.inventory_2_outlined)),
                _OpcionMenu(Icons.receipt_long_outlined, 'Facturación',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Facturación',
                        descripcion:
                            'Configura impuestos, propinas y método de facturación electrónica.',
                        icono: Icons.receipt_long_outlined)),
                _OpcionMenu(Icons.local_offer_outlined, 'Promociones',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Promociones',
                        descripcion:
                            'Crea descuentos por hora, día o cliente frecuente. Activa promos express.',
                        icono: Icons.local_offer_outlined)),
              ]),

              const SizedBox(height: 20),

              Text(AppStrings.t(context, 'configuracion'),
                  style: AppTheme.etiqueta()),
              const SizedBox(height: 12),
              _GrupoOpciones(opciones: [
                _OpcionMenu(Icons.notifications_outlined, 'Notificaciones',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Notificaciones',
                        descripcion:
                            'Recibe alertas de pedidos nuevos, mesas disponibles y reseñas.',
                        icono: Icons.notifications_outlined)),
                _OpcionMenu(Icons.security, 'Seguridad y acceso',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Seguridad',
                        descripcion:
                            'Cambia contraseña, activa autenticación de dos factores y gestiona sesiones.',
                        icono: Icons.security)),
                _OpcionMenu(Icons.help_outline, 'Centro de ayuda',
                    onTap: () => _abrirHoja(context,
                        titulo: 'Centro de ayuda',
                        descripcion:
                            'Consulta tutoriales, FAQs y contacta a soporte técnico de Sabor & Datos.',
                        icono: Icons.help_outline)),
                _OpcionMenu(Icons.info_outline, 'Acerca de',
                    onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'Sabor & Datos · Negocios',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              '© 2026 Sabor & Datos.\nLa plataforma para restaurantes que aman los datos.',
                        )),
              ]),

              const SizedBox(height: 28),

              InkWell(
                onTap: () => _cerrarSesion(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.alertaFondo,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            AppColors.terracota.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout,
                          color: AppColors.terracota, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.t(context, 'cerrar_sesion'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.terracota,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Sabor & Datos · v 1.0.0',
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

class _MetricaResumen extends StatelessWidget {
  final String valor;
  final String label;
  final IconData icon;

  const _MetricaResumen({
    required this.valor,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.cremaOscura, size: 16),
        const SizedBox(height: 4),
        Text(
          valor,
          style: AppTheme.titulo(size: 18, color: AppColors.crema),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.cremaOscura,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cremaOscura,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(op.icono,
                        color: AppColors.cafeOscuro, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(op.titulo,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.cafeOscuro,
                            fontWeight: FontWeight.w500)),
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
