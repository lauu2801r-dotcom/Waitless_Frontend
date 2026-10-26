import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/inventario_service.dart' show InvExito, InvError;
import '../../services/personal_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';

/// Personal del restaurante: lista de empleados, alta y activar/desactivar acceso.
class AdminPersonalScreen extends StatefulWidget {
  const AdminPersonalScreen({super.key});

  @override
  State<AdminPersonalScreen> createState() => _AdminPersonalScreenState();
}

class _AdminPersonalScreenState extends State<AdminPersonalScreen> {
  List<EmpleadoApi> _empleados = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final r = await PersonalService.listar();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      switch (r) {
        case InvExito(:final datos):
          _empleados = datos;
        case InvError(:final mensaje):
          _error = mensaje;
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
      backgroundColor: error ? AppColors.terracota : AppColors.oliva,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _nuevo() async {
    final creado = await showModalBottomSheet<EmpleadoApi>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NuevoEmpleadoSheet(),
    );
    if (creado != null) {
      _snack('${creado.nombreCompleto} ya puede iniciar sesión');
      _cargar();
    }
  }

  Future<void> _detalle(EmpleadoApi e) async {
    final cambio = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetalleEmpleadoSheet(empleado: e),
    );
    if (cambio == true) {
      _snack(e.activo
          ? 'Acceso de ${e.nombre} desactivado'
          : 'Acceso de ${e.nombre} reactivado');
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activos = _empleados.where((e) => e.activo).length;
    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        backgroundColor: AppColors.crema,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.cafeOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Personal', style: AppTheme.titulo(size: 22)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        backgroundColor: AppColors.terracota,
        icon: const Icon(Icons.person_add_alt_1, color: AppColors.crema),
        label: Text('Agregar empleado',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.crema)),
      ),
      body: RefreshIndicator(
        color: AppColors.terracota,
        onRefresh: _cargar,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.terracota))
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.terracota, size: 40),
                          const SizedBox(height: 10),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.cafeMedio)),
                          TextButton(
                              onPressed: _cargar,
                              child: const Text('Reintentar')),
                        ]),
                      ),
                    ),
                  ])
                : _empleados.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        const Icon(Icons.groups_outlined,
                            color: AppColors.cafeMedio, size: 48),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('Aún no tienes empleados',
                              style: AppTheme.titulo(size: 18)),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Agrega a tus meseros, cocineros o cajeros para que puedan iniciar sesión.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.cafeMedio,
                                height: 1.4),
                          ),
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        children: [
                          Text(
                              '${_empleados.length} ${_empleados.length == 1 ? 'EMPLEADO' : 'EMPLEADOS'} · $activos ${activos == 1 ? 'ACTIVO' : 'ACTIVOS'}',
                              style: AppTheme.etiqueta()),
                          const SizedBox(height: 12),
                          ..._empleados.map((e) => _TarjetaEmpleado(
                                empleado: e,
                                onTap: () => _detalle(e),
                              )),
                        ],
                      ),
      ),
    );
  }
}

class _TarjetaEmpleado extends StatelessWidget {
  final EmpleadoApi empleado;
  final VoidCallback onTap;
  const _TarjetaEmpleado({required this.empleado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = empleado;
    final color = e.activo ? AppColors.exitoTexto : AppColors.cafeMedio;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: e.activo ? 1 : 0.65,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(e.inicial,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracota)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.nombreCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cafeOscuro)),
                      const SizedBox(height: 2),
                      Text('${e.cargoEtiqueta} · ${e.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.cafeMedio)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e.activo ? 'Activo' : 'Inactivo',
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────── Hoja: detalle / activar-desactivar ─────────────────────
class _DetalleEmpleadoSheet extends StatefulWidget {
  final EmpleadoApi empleado;
  const _DetalleEmpleadoSheet({required this.empleado});

  @override
  State<_DetalleEmpleadoSheet> createState() => _DetalleEmpleadoSheetState();
}

class _DetalleEmpleadoSheetState extends State<_DetalleEmpleadoSheet> {
  bool _guardando = false;
  String? _error;

  Future<void> _cambiar() async {
    final e = widget.empleado;
    if (e.activo) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Desactivar acceso?'),
          content: Text(
              '${e.nombreCompleto} ya no podrá iniciar sesión. Puedes reactivarlo cuando quieras.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Desactivar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await PersonalService.cambiarActivo(e.id, !e.activo);
    if (!mounted) return;
    switch (r) {
      case InvExito():
        Navigator.pop(context, true);
      case InvError(:final mensaje):
        setState(() {
          _guardando = false;
          _error = mensaje;
        });
    }
  }

  Widget _dato(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etiqueta,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.cafeMedio)),
            Flexible(
              child: Text(valor,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeOscuro)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.empleado;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 16),
            Text(e.nombreCompleto, style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 14),
            _dato('Correo', e.email),
            _dato('Teléfono', (e.telefono ?? '').isEmpty ? '—' : e.telefono!),
            _dato('Cargo', e.cargoEtiqueta),
            _dato('Estado', e.activo ? 'Activo' : 'Inactivo'),
            _dato('Registrado', fechaCorta(e.creadoEn)),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.terracota)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _guardando ? null : _cambiar,
              icon: Icon(e.activo ? Icons.block : Icons.check_circle_outline,
                  color: AppColors.terracota, size: 18),
              label: Text(
                  e.activo ? 'Desactivar acceso' : 'Reactivar acceso',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracota)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.terracota),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Hoja: nuevo empleado ─────────────────────
class _NuevoEmpleadoSheet extends StatefulWidget {
  const _NuevoEmpleadoSheet();

  @override
  State<_NuevoEmpleadoSheet> createState() => _NuevoEmpleadoSheetState();
}

class _NuevoEmpleadoSheetState extends State<_NuevoEmpleadoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  bool _ver = false;
  String _cargo = 'mesero';
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _email.dispose();
    _telefono.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final r = await PersonalService.crear(
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      email: _email.text.trim(),
      telefono: _telefono.text.trim(),
      cargo: _cargo,
      password: _password.text,
    );
    if (!mounted) return;
    switch (r) {
      case InvExito(:final datos):
        Navigator.pop(context, datos);
      case InvError(:final mensaje):
        setState(() {
          _guardando = false;
          _error = mensaje;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
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
                const SizedBox(height: 16),
                Text('Nuevo empleado', style: AppTheme.titulo(size: 22)),
                const SizedBox(height: 4),
                Text(
                    'Su cuenta queda activa de una vez. Compárteles el correo y la contraseña.',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.cafeMedio,
                        height: 1.4)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? 'Mínimo 2 letras'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _apellido,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Text('CARGO', style: AppTheme.etiqueta()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in const ['mesero', 'cocinero', 'cajero'])
                      ChoiceChip(
                        label: Text(c[0].toUpperCase() + c.substring(1)),
                        selected: _cargo == c,
                        selectedColor: AppColors.terracota.withValues(alpha: 0.18),
                        onSelected: (_) => setState(() => _cargo = c),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch((v ?? '').trim())
                      ? null
                      : 'Correo no válido',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Teléfono (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: !_ver,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    helperText: 'Mínimo 8 caracteres, una mayúscula y un número',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _ver ? Icons.visibility_off : Icons.visibility,
                          size: 20),
                      onPressed: () => setState(() => _ver = !_ver),
                    ),
                  ),
                  validator: (v) {
                    final p = v ?? '';
                    if (p.length < 8) return 'Mínimo 8 caracteres';
                    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Falta una mayúscula';
                    if (!RegExp(r'[0-9]').hasMatch(p)) return 'Falta un número';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 12.5, color: AppColors.terracota)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.crema))
                      : const Text('CREAR EMPLEADO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
