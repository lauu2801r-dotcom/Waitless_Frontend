import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/reserva_model.dart';
import '../../services/reserva_service.dart';
import '../../services/tiempo_real_service.dart';
import '../../theme/app_theme.dart';

/// Reservas del restaurante (administrador y empleados): ver, confirmar,
/// completar y cancelar con motivo. Se actualiza en vivo.
class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  final _service = ReservaService();
  List<ReservaModel> _reservas = [];
  bool _cargando = true;
  String? _error;
  String _filtro = 'por_confirmar'; // por_confirmar | confirmadas | historial
  int? _procesando;

  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Timer? _antirrebote;

  @override
  void initState() {
    super.initState();
    _cargar();
    _tiempoReal = TiempoRealConexion('dashboard')..conectar();
    _sub = _tiempoReal.eventos.listen((e) {
      if ('${e['tipo']}'.startsWith('reserva')) {
        _antirrebote?.cancel();
        _antirrebote = Timer(const Duration(seconds: 1), () => _cargar(silencioso: true));
      }
    });
  }

  @override
  void dispose() {
    _antirrebote?.cancel();
    _sub?.cancel();
    _tiempoReal.cerrar();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final lista = await _service.reservasDelRestaurante();
      if (!mounted) return;
      setState(() {
        _reservas = lista;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silencioso) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _avisar(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: AppColors.crema)),
        backgroundColor: error ? AppColors.terracotaOscuro : AppColors.cafeOscuro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  Future<void> _cambiarEstado(ReservaModel r, String estado) async {
    setState(() => _procesando = r.id);
    try {
      await _service.cambiarEstado(r.id, estado);
      _avisar(estado == 'confirmada' ? 'Reserva confirmada' : 'Reserva completada');
      await _cargar(silencioso: true);
    } catch (e) {
      _avisar(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  Future<void> _cancelar(ReservaModel r) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancelar reserva',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se le avisará al cliente con el motivo que escribas.',
                style: GoogleFonts.inter(color: AppColors.cafeMedio, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLength: 255,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ej: la mesa no estará disponible',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Volver', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancelar reserva',
                style: GoogleFonts.inter(
                    color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    final motivo = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return;
    setState(() => _procesando = r.id);
    try {
      await _service.cancelarReserva(r.id, motivo: motivo);
      _avisar('Reserva cancelada');
      await _cargar(silencioso: true);
    } catch (e) {
      _avisar(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  List<ReservaModel> get _visibles {
    final l = _reservas.where((r) {
      switch (_filtro) {
        case 'por_confirmar':
          return r.estado == 'pendiente';
        case 'confirmadas':
          return r.estado == 'confirmada';
        default:
          return r.estado == 'cancelada' || r.estado == 'completada';
      }
    }).toList();
    // próximas primero; el historial, lo más reciente primero
    l.sort((a, b) => _filtro == 'historial'
        ? b.fechaHora.compareTo(a.fechaHora)
        : a.fechaHora.compareTo(b.fechaHora));
    return l;
  }

  int _cuenta(String estado) => _reservas.where((r) => r.estado == estado).length;

  @override
  Widget build(BuildContext context) {
    final porConfirmar = _cuenta('pendiente');
    final confirmadas = _cuenta('confirmada');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            children: [
              _chip('Por confirmar ($porConfirmar)', 'por_confirmar'),
              _chip('Confirmadas ($confirmadas)', 'confirmadas'),
              _chip('Historial', 'historial'),
            ],
          ),
        ),
        Expanded(child: _cuerpo()),
      ],
    );
  }

  Widget _chip(String texto, String valor) {
    final sel = _filtro == valor;
    return ChoiceChip(
      label: Text(texto,
          style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: sel ? AppColors.crema : AppColors.cafeOscuro)),
      selected: sel,
      selectedColor: AppColors.terracota,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = valor),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracota));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.cafeMedio, size: 44),
          const SizedBox(height: 10),
          Text(_error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.cafeMedio, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }
    final lista = _visibles;
    return RefreshIndicator(
      color: AppColors.terracota,
      onRefresh: () => _cargar(silencioso: true),
      child: lista.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              const Icon(Icons.event_available_outlined, size: 46, color: AppColors.cafeMedio),
              const SizedBox(height: 10),
              Text(
                _filtro == 'por_confirmar'
                    ? 'No hay reservas por confirmar'
                    : _filtro == 'confirmadas'
                        ? 'No hay reservas confirmadas'
                        : 'Aún no hay historial',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.cafeMedio, fontSize: 14),
              ),
            ])
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _tarjeta(lista[i]),
            ),
    );
  }

  Color _color(String e) => switch (e) {
        'confirmada' => AppColors.oliva,
        'pendiente' => AppColors.terracota,
        _ => AppColors.cafeMedio,
      };

  String _etiqueta(String e) => switch (e) {
        'pendiente' => 'Por confirmar',
        'confirmada' => 'Confirmada',
        'completada' => 'Completada',
        'cancelada' => 'Cancelada',
        _ => e,
      };

  Widget _dato(IconData icono, String texto) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 13, color: AppColors.cafeMedio),
        const SizedBox(width: 4),
        Text(texto, style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
      ]);

  Widget _tarjeta(ReservaModel r) {
    final f = r.fechaHora;
    final fecha = '${f.day}/${f.month}/${f.year}  '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
    final ocupado = _procesando == r.id;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficieAdaptativa(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordeAdaptativo(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mesa ${r.mesaNumero ?? r.mesaId}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.cafeOscuro)),
              if (r.clienteNombre != null && r.clienteNombre!.isNotEmpty)
                Text(r.clienteNombre!,
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.cafeMedio)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color(r.estado).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_etiqueta(r.estado),
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _color(r.estado))),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          _dato(Icons.calendar_today_outlined, fecha),
          _dato(Icons.people_outline, '${r.numeroPersonas} personas'),
        ]),
        if (r.notas != null && r.notas!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.notas!,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.cafeMedio, fontStyle: FontStyle.italic)),
        ],
        if (r.estado == 'cancelada' &&
            r.motivoCancelacion != null &&
            r.motivoCancelacion!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Motivo: ${r.motivoCancelacion}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
        ],
        if (r.estado == 'pendiente' || r.estado == 'confirmada') ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: ocupado ? null : () => _cancelar(r),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(
                      color: AppColors.terracota, fontWeight: FontWeight.w500, fontSize: 13)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: ocupado
                  ? null
                  : () => _cambiarEstado(r, r.estado == 'pendiente' ? 'confirmada' : 'completada'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: ocupado
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: AppColors.crema, strokeWidth: 2))
                  : Text(r.estado == 'pendiente' ? 'Confirmar' : 'Completar'),
            ),
          ]),
        ],
      ]),
    );
  }
}
