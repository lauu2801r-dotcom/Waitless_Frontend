import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/reserva_model.dart';
import '../services/reserva_service.dart';
import '../services/mesa_service.dart';
import '../services/tiempo_real_service.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReservaService();
  late TabController _tabController;

  List<ReservaModel> _reservas = [];
  bool _cargando = true;
  String? _error;

  // Estado de la reserva en tiempo real (HU-021)
  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarReservas();
    _tiempoReal = TiempoRealConexion('mis-eventos')..conectar();
    _suscripcion = _tiempoReal.eventos.listen((evento) {
      if (evento['tipo'] == 'reserva_estado') {
        _cargarReservas(silencioso: true);
        final msg = evento['mensaje'] as String?;
        if (msg != null && mounted) _avisar('🔔 $msg');
      }
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _tiempoReal.cerrar();
    _tabController.dispose();
    super.dispose();
  }

  void _avisar(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: error ? AppColors.terracotaOscuro : AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cargarReservas({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final reservas = await _service.misReservas();
      if (!mounted) return;
      setState(() {
        _reservas = reservas;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silencioso) return; // si falla en segundo plano, se deja lo que ya había
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _cancelar(int id) async {
    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancelar reserva',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres cancelar esta reserva?',
                style: GoogleFonts.inter(color: AppColors.cafeMedio)),
            const SizedBox(height: 14),
            TextField(
              controller: motivoCtrl,
              maxLength: 255,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: me surgió un imprevisto',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No',
                style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, cancelar',
                style: GoogleFonts.inter(
                    color: AppColors.terracota,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    final motivo = motivoCtrl.text.trim();
    motivoCtrl.dispose();
    if (confirmar != true) return;
    try {
      await _service.cancelarReserva(id, motivo: motivo);
      _cargarReservas(silencioso: true);
      _avisar('Reserva cancelada');
    } catch (e) {
      _avisar(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _modificar(ReservaModel reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormularioModificar(
        reserva: reserva,
        onGuardada: () {
          Navigator.pop(context);
          _cargarReservas(silencioso: true);
          _avisar('Reserva actualizada');
        },
      ),
    );
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FormularioReserva(
        onCreada: () {
          Navigator.pop(context);
          _cargarReservas();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activas = _reservas
        .where((r) => r.estado == 'pendiente' || r.estado == 'confirmada')
        .toList();
    final historial = _reservas
        .where((r) => r.estado == 'cancelada' || r.estado == 'completada')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.fondo(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondo(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.cafeOscuro, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mis Reservas', style: AppTheme.titulo(size: 22)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.terracota,
          unselectedLabelColor: AppColors.textoSecundario(context),
          indicatorColor: AppColors.terracota,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: AppColors.terracota,
        elevation: 2,
        icon: const Icon(Icons.add, color: AppColors.crema),
        label: Text('Nueva reserva',
            style: GoogleFonts.inter(
                color: AppColors.crema, fontWeight: FontWeight.w600)),
      ),
      body: _cargando
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.terracota))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_outlined,
                          color: AppColors.cafeMedio, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: GoogleFonts.inter(
                              color: AppColors.cafeMedio, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarReservas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ListaReservas(
                      reservas: activas,
                      onCancelar: _cancelar,
                      onModificar: _modificar,
                      onRefrescar: _cargarReservas,
                      vacio: 'No tienes reservas activas',
                      vacioBadge: '🗓️',
                    ),
                    _ListaReservas(
                      reservas: historial,
                      onCancelar: null,
                      onModificar: null,
                      onRefrescar: _cargarReservas,
                      vacio: 'Sin historial de reservas',
                      vacioBadge: '📋',
                    ),
                  ],
                ),
    );
  }
}

// ── Lista ──────────────────────────────────────────────────────────────────

class _ListaReservas extends StatelessWidget {
  final List<ReservaModel> reservas;
  final void Function(int id)? onCancelar;
  final void Function(ReservaModel reserva)? onModificar;
  final Future<void> Function({bool silencioso}) onRefrescar;
  final String vacio;
  final String vacioBadge;

  const _ListaReservas({
    required this.reservas,
    required this.onCancelar,
    required this.onModificar,
    required this.onRefrescar,
    required this.vacio,
    required this.vacioBadge,
  });

  @override
  Widget build(BuildContext context) {
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vacioBadge, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(vacio,
                style: GoogleFonts.inter(
                    color: AppColors.textoSecundario(context),
                    fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.terracota,
      onRefresh: () => onRefrescar(silencioso: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: reservas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TarjetaReserva(
          reserva: reservas[i],
          onCancelar: onCancelar,
          onModificar: onModificar,
        ),
      ),
    );
  }
}

// ── Tarjeta ────────────────────────────────────────────────────────────────

class _TarjetaReserva extends StatelessWidget {
  final ReservaModel reserva;
  final void Function(int id)? onCancelar;
  final void Function(ReservaModel reserva)? onModificar;

  const _TarjetaReserva(
      {required this.reserva,
      required this.onCancelar,
      required this.onModificar});

  Color _colorEstado(String estado) => switch (estado) {
        'confirmada' => AppColors.oliva,
        'pendiente' => AppColors.terracota,
        'cancelada' => AppColors.cafeMedio,
        _ => AppColors.cafeMedio,
      };

  String _labelEstado(String estado) => switch (estado) {
        'confirmada' => 'Confirmada',
        'pendiente' => 'Pendiente',
        'cancelada' => 'Cancelada',
        'completada' => 'Completada',
        _ => estado,
      };

  @override
  Widget build(BuildContext context) {
    final fecha = reserva.fechaHora;
    final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}  '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficieAdaptativa(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordeAdaptativo(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.terracota.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_restaurant_outlined,
                  color: AppColors.terracota, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Mesa ${reserva.mesaNumero ?? reserva.mesaId}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.cafeOscuro)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _colorEstado(reserva.estado).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_labelEstado(reserva.estado),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _colorEstado(reserva.estado))),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cremaOscura.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.cafeMedio),
                  const SizedBox(width: 4),
                  Text(fechaStr,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.cafeMedio)),
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_outline,
                      size: 13, color: AppColors.cafeMedio),
                  const SizedBox(width: 4),
                  Text('${reserva.numeroPersonas} personas',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.cafeMedio)),
                ]),
                if (reserva.tiempoEsperaEstimado != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: AppColors.cafeMedio),
                    const SizedBox(width: 4),
                    Text('~${reserva.tiempoEsperaEstimado} min',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.cafeMedio)),
                  ]),
              ],
            ),
          ),
          if (reserva.notas != null && reserva.notas!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reserva.notas!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.cafeMedio,
                    fontStyle: FontStyle.italic)),
          ],
          if (reserva.estado == 'cancelada' &&
              reserva.motivoCancelacion != null &&
              reserva.motivoCancelacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Motivo: ${reserva.motivoCancelacion}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.cafeMedio)),
          ],
          if (onCancelar != null || onModificar != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onModificar != null)
                  TextButton.icon(
                    onPressed: () => onModificar!(reserva),
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.cafeOscuro),
                    label: Text('Modificar',
                        style: GoogleFonts.inter(
                            color: AppColors.cafeOscuro,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                  ),
                if (onCancelar != null)
                  TextButton(
                    onPressed: () => onCancelar!(reserva.id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.terracota,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text('Cancelar reserva',
                        style: GoogleFonts.inter(
                            color: AppColors.terracota,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Formulario nueva reserva ───────────────────────────────────────────────

class _FormularioReserva extends StatefulWidget {
  final VoidCallback onCreada;
  const _FormularioReserva({required this.onCreada});

  @override
  State<_FormularioReserva> createState() => _FormularioReservaState();
}

class _FormularioReservaState extends State<_FormularioReserva> {
  final _service = ReservaService();
  final _mesaService = MesaService();
  final _formKey = GlobalKey<FormState>();
  final _notasController = TextEditingController();

  int _personas = 2;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _enviando = false;

  List<MesaModel> _mesas = [];
  MesaModel? _mesaSeleccionada;
  bool _cargandoMesas = true;

  @override
  void initState() {
    super.initState();
    _cargarMesas();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarMesas() async {
    try {
      final mesas = await _mesaService.mesasDisponibles();
      setState(() {
        _mesas = mesas;
        _cargandoMesas = false;
      });
    } catch (e) {
      setState(() => _cargandoMesas = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.terracota,
            onPrimary: AppColors.crema,
            surface: AppColors.crema,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.terracota,
            onPrimary: AppColors.crema,
            surface: AppColors.crema,
          ),
        ),
        child: child!,
      ),
    );
    if (hora != null) setState(() => _horaSeleccionada = hora);
  }

  void _mostrarSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor:
            error ? AppColors.terracotaOscuro : AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _enviar() async {
    if (_mesaSeleccionada == null) {
      _mostrarSnack('Selecciona una mesa', error: true);
      return;
    }
    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      _mostrarSnack('Selecciona fecha y hora', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      final fechaHora = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );
      await _service.crearReserva(
        mesaId: _mesaSeleccionada!.id,
        fechaHora: fechaHora,
        numeroPersonas: _personas,
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );
      widget.onCreada();
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) _mostrarSnack(e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = _fechaSeleccionada == null
        ? 'Seleccionar fecha'
        : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}';
    final horaStr = _horaSeleccionada == null
        ? 'Seleccionar hora'
        : _horaSeleccionada!.format(context);

    // Mesas filtradas por capacidad >= personas seleccionadas
    final mesasFiltradas =
        _mesas.where((m) => m.capacidad >= _personas).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
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
              Text('Reservar mesa', style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 20),

              // ── Personas ──
              Text('PERSONAS', style: AppTheme.etiqueta()),
              const SizedBox(height: 10),
              Row(
                children: List.generate(6, (index) {
                  final n = index + 1;
                  final sel = _personas == n;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _personas = n;
                        // Si la mesa seleccionada ya no aplica, deseleccionar
                        if (_mesaSeleccionada != null &&
                            _mesaSeleccionada!.capacidad < n) {
                          _mesaSeleccionada = null;
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            EdgeInsets.only(right: index < 5 ? 6 : 0),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.terracota
                              : AppColors.superficie,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.terracota
                                : AppColors.borde,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$n${n == 6 ? '+' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? AppColors.crema
                                  : AppColors.cafeOscuro,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // ── Mesas disponibles ──
              Text('MESA DISPONIBLE', style: AppTheme.etiqueta()),
              const SizedBox(height: 8),
              if (_cargandoMesas)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                        color: AppColors.terracota),
                  ),
                )
              else if (mesasFiltradas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.alertaFondo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.terracota.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.alertaTexto, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay mesas disponibles para $_personas personas',
                        style: GoogleFonts.inter(
                            color: AppColors.alertaTexto, fontSize: 13),
                      ),
                    ),
                  ]),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mesasFiltradas.map((mesa) {
                    final sel = _mesaSeleccionada?.id == mesa.id;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _mesaSeleccionada = mesa),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.terracota
                              : AppColors.superficie,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.terracota
                                : AppColors.borde,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Mesa ${mesa.numero}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? AppColors.crema
                                    : AppColors.cafeOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mesa.capacidad} pers.',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: sel
                                    ? AppColors.crema.withValues(alpha: 0.8)
                                    : AppColors.cafeMedio,
                              ),
                            ),
                            if (mesa.ubicacion != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                mesa.ubicacion!,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: sel
                                      ? AppColors.crema
                                          .withValues(alpha: 0.7)
                                      : AppColors.cafeMedio,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 18),

              // ── Fecha y hora ──
              Text('FECHA Y HORA', style: AppTheme.etiqueta()),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarFecha,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _fechaSeleccionada != null
                              ? AppColors.terracota
                              : AppColors.borde,
                          width: _fechaSeleccionada != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            color: _fechaSeleccionada != null
                                ? AppColors.terracota
                                : AppColors.cafeMedio,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(fechaStr,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _fechaSeleccionada != null
                                      ? AppColors.cafeOscuro
                                      : AppColors.cafeMedio)),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _seleccionarHora,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.superficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _horaSeleccionada != null
                              ? AppColors.terracota
                              : AppColors.borde,
                          width: _horaSeleccionada != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.access_time,
                            color: _horaSeleccionada != null
                                ? AppColors.terracota
                                : AppColors.cafeMedio,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(horaStr,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _horaSeleccionada != null
                                      ? AppColors.cafeOscuro
                                      : AppColors.cafeMedio)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),

              // ── Notas ──
              Text('NOTAS', style: AppTheme.etiqueta()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notasController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Alergias, ocasión especial... (opcional)',
                  prefixIcon: Icon(Icons.note_outlined,
                      color: AppColors.cafeMedio, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.crema, strokeWidth: 2))
                      : const Text('CONFIRMAR RESERVA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Formulario modificar reserva ───────────────────────────────────────────

class _FormularioModificar extends StatefulWidget {
  final ReservaModel reserva;
  final VoidCallback onGuardada;
  const _FormularioModificar({required this.reserva, required this.onGuardada});

  @override
  State<_FormularioModificar> createState() => _FormularioModificarState();
}

class _FormularioModificarState extends State<_FormularioModificar> {
  final _service = ReservaService();
  late final TextEditingController _notasController;
  late int _personas;
  late DateTime _fecha;
  late TimeOfDay _hora;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.reserva;
    _personas = r.numeroPersonas.clamp(1, 6);
    _fecha = DateTime(r.fechaHora.year, r.fechaHora.month, r.fechaHora.day);
    _hora = TimeOfDay(hour: r.fechaHora.hour, minute: r.fechaHora.minute);
    _notasController = TextEditingController(text: r.notas ?? '');
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  ThemeData _tema(BuildContext context) => Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.terracota,
          onPrimary: AppColors.crema,
          surface: AppColors.crema,
        ),
      );

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 60)),
      builder: (context, child) => Theme(data: _tema(context), child: child!),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora() async {
    final h = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (context, child) => Theme(data: _tema(context), child: child!),
    );
    if (h != null) setState(() => _hora = h);
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _service.modificarReserva(
        widget.reserva.id,
        fechaHora: DateTime(_fecha.year, _fecha.month, _fecha.day, _hora.hour, _hora.minute),
        numeroPersonas: _personas,
        notas: _notasController.text.trim(),
      );
      widget.onGuardada();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr = '${_fecha.day}/${_fecha.month}/${_fecha.year}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Text('Modificar reserva', style: AppTheme.titulo(size: 22)),
            const SizedBox(height: 4),
            Text('Mesa ${widget.reserva.mesaNumero ?? widget.reserva.mesaId}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
            const SizedBox(height: 18),
            Text('PERSONAS', style: AppTheme.etiqueta()),
            const SizedBox(height: 10),
            Row(
              children: List.generate(6, (index) {
                final n = index + 1;
                final sel = _personas == n;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _personas = n),
                    child: Container(
                      margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.terracota : AppColors.superficie,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? AppColors.terracota : AppColors.borde),
                      ),
                      child: Center(
                        child: Text('$n',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: sel ? AppColors.crema : AppColors.cafeOscuro)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Text('FECHA Y HORA', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(fechaStr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _elegirHora,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_hora.format(context)),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text('NOTAS', style: AppTheme.etiqueta()),
            const SizedBox(height: 8),
            TextField(
              controller: _notasController,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Alergias, ocasión especial... (opcional)',
                prefixIcon: Icon(Icons.note_outlined, color: AppColors.cafeMedio, size: 20),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.terracotaOscuro)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.crema, strokeWidth: 2))
                    : const Text('GUARDAR CAMBIOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
