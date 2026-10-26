import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/mesa_service.dart';
import '../../services/tiempo_real_service.dart';
import '../../theme/app_theme.dart';

/// Mesas del restaurante del empleado, en tiempo real. Tocar una mesa cambia su estado.
class EmpleadoMesasScreen extends StatefulWidget {
  const EmpleadoMesasScreen({super.key});

  @override
  State<EmpleadoMesasScreen> createState() => _EmpleadoMesasScreenState();
}

class _EmpleadoMesasScreenState extends State<EmpleadoMesasScreen> {
  static const _estados = [
    ('libre', 'Libre', Icons.check_circle_outline),
    ('ocupada', 'Ocupada', Icons.people_outline),
    ('reservada', 'Reservada', Icons.event_available_outlined),
    ('en_limpieza', 'En limpieza', Icons.cleaning_services_outlined),
  ];

  final _servicio = MesaService();
  List<MesaModel> _mesas = [];
  bool _cargando = true;
  String? _error;

  late final TiempoRealConexion _tiempoReal;
  StreamSubscription<Map<String, dynamic>>? _suscripcion;

  @override
  void initState() {
    super.initState();
    _cargar();
    _tiempoReal = TiempoRealConexion('mesas')..conectar();
    _suscripcion = _tiempoReal.eventos.listen((evento) {
      final tipo = evento['tipo'] as String? ?? '';
      if (tipo == 'estado_mesa' || tipo == 'mesas_actualizadas') {
        _cargar(silencioso: true);
      }
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
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
      final mesas = await _servicio.todasLasMesas();
      mesas.sort((a, b) => a.numero.compareTo(b.numero));
      if (!mounted) return;
      setState(() {
        _mesas = mesas;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (!silencioso) _error = 'No se pudieron cargar las mesas';
      });
    }
  }

  Color _color(String estado) => switch (estado) {
        'libre' => AppColors.exitoTexto,
        'ocupada' => AppColors.terracota,
        'reservada' => AppColors.cafeMedio,
        _ => AppColors.alertaTexto,
      };

  String _etiqueta(String estado) =>
      _estados.where((e) => e.$1 == estado).map((e) => e.$2).firstOrNull ??
      estado;

  Future<void> _cambiar(MesaModel mesa) async {
    final elegido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.crema,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
              Text('Mesa ${mesa.numero}', style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 4),
              Text('Cambiar estado',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.cafeMedio)),
              const SizedBox(height: 12),
              ..._estados.map((e) {
                final actual = mesa.estado == e.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: actual ? null : () => Navigator.pop(ctx, e.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: actual
                            ? _color(e.$1).withValues(alpha: 0.12)
                            : AppColors.superficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: actual ? _color(e.$1) : AppColors.borde),
                      ),
                      child: Row(
                        children: [
                          Icon(e.$3, color: _color(e.$1), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(e.$2,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cafeOscuro)),
                          ),
                          if (actual)
                            Text('Actual',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: _color(e.$1),
                                    fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    final error = await _servicio.cambiarEstado(mesa.id, elegido);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          error ?? 'Mesa ${mesa.numero}: ${_etiqueta(elegido).toLowerCase()}',
          style: GoogleFonts.inter(color: AppColors.crema)),
      backgroundColor: error == null ? AppColors.oliva : AppColors.terracota,
      behavior: SnackBarBehavior.floating,
    ));
    _cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    final libres = _mesas.where((m) => m.estado == 'libre').length;
    return RefreshIndicator(
      color: AppColors.terracota,
      onRefresh: _cargar,
      child: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracota))
          : _error != null
              ? ListView(children: [
                  const SizedBox(height: 80),
                  Center(child: Text(_error!)),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ])
              : _mesas.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Text('Tu restaurante aún no tiene mesas',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio)),
                      ),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        Text('${_mesas.length} MESAS · $libres LIBRES',
                            style: AppTheme.etiqueta()),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.35,
                          children: _mesas.map((m) {
                            final c = _color(m.estado);
                            return InkWell(
                              onTap: () => _cambiar(m),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: c.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Mesa ${m.numero}',
                                            style: GoogleFonts.playfairDisplay(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.cafeOscuro)),
                                        Icon(Icons.edit_outlined,
                                            size: 15, color: c),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${m.capacidad} pers.${(m.ubicacion ?? '').isEmpty ? '' : ' · ${m.ubicacion}'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.cafeMedio)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: c.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(_etiqueta(m.estado),
                                              style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: c)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
    );
  }
}
