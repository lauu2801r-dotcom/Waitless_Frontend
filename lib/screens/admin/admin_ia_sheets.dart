import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/prediccion_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';

// ═════════════════════════════════════════════════════════════
//  VERSIONES DEL MODELO + ENTRENAMIENTO
// ═════════════════════════════════════════════════════════════

/// [onCambio] se llama cuando se entrena o se activa otra versión,
/// para que la pantalla de análisis recargue sus métricas.
void mostrarVersionesIa(BuildContext context,
    {required VoidCallback onCambio}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _VersionesSheet(onCambio: onCambio),
  );
}

class _VersionesSheet extends StatefulWidget {
  final VoidCallback onCambio;
  const _VersionesSheet({required this.onCambio});

  @override
  State<_VersionesSheet> createState() => _VersionesSheetState();
}

class _VersionesSheetState extends State<_VersionesSheet> {
  List<VersionModelo> _versiones = [];
  bool _cargando = true;
  bool _trabajando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await PrediccionService.versiones();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      switch (r) {
        case IaExito(:final datos):
          _versiones = datos;
          _error = null;
        case IaError(:final mensaje):
          _error = mensaje;
      }
    });
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.terracota : AppColors.oliva,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _entrenar() async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrenar una versión nueva'),
        content: const Text(
          'Se entrena con todos los pedidos reales guardados. Puede tardar '
          'unos segundos. Ten en cuenta que el modelo es compartido por todos '
          'los restaurantes de la plataforma.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Entrenar')),
        ],
      ),
    );
    if (seguro != true || !mounted) return;

    setState(() => _trabajando = true);
    final r = await PrediccionService.entrenarModelo();
    if (!mounted) return;
    setState(() => _trabajando = false);

    switch (r) {
      case IaExito(:final datos):
        _aviso('Versión ${datos.version}: error '
            '${datos.mae?.toStringAsFixed(2) ?? '--'} min con '
            '${datos.muestrasReales} pedidos reales. ${datos.mensaje}');
        widget.onCambio();
        _cargar();
      case IaError(:final mensaje):
        _aviso(mensaje, error: true);
    }
  }

  Future<void> _activar(VersionModelo v) async {
    setState(() => _trabajando = true);
    final r = await PrediccionService.activarVersion(v.id);
    if (!mounted) return;
    setState(() => _trabajando = false);

    switch (r) {
      case IaExito(:final datos):
        _aviso('La versión $datos quedó activa');
        widget.onCambio();
        _cargar();
      case IaError(:final mensaje):
        _aviso(mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borde,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: Text('Versiones del modelo',
                        style: AppTheme.titulo(size: 22))),
                if (_trabajando)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.terracota),
                  )
                else
                  FilledButton.icon(
                    onPressed: _entrenar,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terracota),
                    icon: const Icon(Icons.model_training, size: 16),
                    label: const Text('Entrenar'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cada entrenamiento guarda una versión. El sistema también '
                'reentrena solo cada 25 pedidos nuevos y solo la activa si '
                'no empeora el error.',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.cafeMedio, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.terracota))
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _versiones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _tarjetaVersion(_versiones[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaVersion(VersionModelo v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: v.activo ? AppColors.oliva : AppColors.borde,
            width: v.activo ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Versión ${v.version}', style: AppTheme.titulo(size: 17)),
              const SizedBox(width: 8),
              _chip(v.motivoTexto, AppColors.cremaOscura, AppColors.cafeMedio),
              const Spacer(),
              if (v.activo)
                _chip('ACTIVA', AppColors.olivaFondo, AppColors.infoTexto)
              else
                TextButton(
                  onPressed: _trabajando ? null : () => _activar(v),
                  child: Text('Activar',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracota)),
                ),
            ],
          ),
          Text(fechaHora(v.entrenadoEn),
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio)),
          const SizedBox(height: 10),
          _dato('Entrenada con',
              '${v.muestrasReales} pedidos reales'
              '${v.muestrasSinteticas > 0 ? ' + ${v.muestrasSinteticas} de arranque' : ''}'
              ),
          _dato(
              'Error al entrenar',
              v.maeEntrenamiento == null
                  ? '--'
                  : '${v.maeEntrenamiento!.toStringAsFixed(2)} min'
                      '${v.maeBaseline == null ? '' : ' (promediar daría ${v.maeBaseline!.toStringAsFixed(2)})'}'),
          _dato('Ajuste (R²)', v.r2 == null ? '--' : v.r2!.toStringAsFixed(3)),
          _dato(
              'Error en producción',
              v.prediccionesEvaluadas == 0
                  ? 'aún sin pedidos evaluados'
                  : '${v.maeProduccion?.toStringAsFixed(2) ?? '--'} min '
                      '(${v.prediccionesEvaluadas} pedidos)'),
        ],
      ),
    );
  }

  Widget _chip(String t, Color fondo, Color texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(t,
          style: GoogleFonts.inter(
              fontSize: 9.5, fontWeight: FontWeight.w700, color: texto)),
    );
  }

  Widget _dato(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(k,
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.cafeMedio)),
          ),
          Expanded(
            child: Text(v,
                style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//  HISTORIAL DE PREDICCIONES
// ═════════════════════════════════════════════════════════════

void mostrarHistorialIa(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _HistorialSheet(),
  );
}

class _HistorialSheet extends StatefulWidget {
  const _HistorialSheet();

  @override
  State<_HistorialSheet> createState() => _HistorialSheetState();
}

class _HistorialSheetState extends State<_HistorialSheet> {
  List<PrediccionHistorial> _filas = [];
  bool _cargando = true;
  bool _exportando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await PrediccionService.historial(limite: 60);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      switch (r) {
        case IaExito(:final datos):
          _filas = datos;
        case IaError(:final mensaje):
          _error = mensaje;
      }
    });
  }

  Future<void> _copiarCsv() async {
    setState(() => _exportando = true);
    final r = await PrediccionService.exportarCsv();
    if (!mounted) return;
    setState(() => _exportando = false);

    switch (r) {
      case IaExito(:final datos):
        await Clipboard.setData(
            ClipboardData(text: datos.replaceFirst('﻿', '')));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CSV copiado. Pégalo en Excel o en un bloc de notas.'),
          backgroundColor: AppColors.oliva,
        ));
      case IaError(:final mensaje):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.terracota,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borde,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: Text('Historial de predicciones',
                        style: AppTheme.titulo(size: 22))),
                if (_exportando)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.terracota),
                  )
                else
                  TextButton.icon(
                    onPressed: _copiarCsv,
                    icon: const Icon(Icons.copy_all,
                        size: 16, color: AppColors.terracota),
                    label: Text('Copiar CSV',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.terracota)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Las últimas ${_filas.length} de tu restaurante.',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.cafeMedio)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.terracota))
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _filas.isEmpty
                          ? Center(
                              child: Text(
                                'Aún no hay predicciones.\nSe crean solas '
                                'cuando un cliente hace un pedido.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppColors.cafeMedio,
                                    height: 1.5),
                              ),
                            )
                          : ListView.separated(
                              controller: scroll,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: _filas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _fila(_filas[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(PrediccionHistorial p) {
    final err = p.error;
    final colorErr = err == null
        ? AppColors.cafeMedio
        : err <= 5
            ? AppColors.oliva
            : err <= 10
                ? const Color(0xFF8A6A1C)
                : AppColors.terracota;

    return Container(
      padding: const EdgeInsets.all(12),
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
                Text(
                  p.pedidoId == null ? 'Consulta' : 'Pedido #${p.pedidoId}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimó ${p.minutosEstimados} min (${p.rangoMin}–${p.rangoMax})'
                  '${p.confianza == null ? '' : ' · ${p.confianza}% confianza'}',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.cafeMedio),
                ),
                Text(
                  '${fechaHora(p.creadoEn)}'
                  '${p.versionModelo == null ? '' : ' · v${p.versionModelo}'}',
                  style: GoogleFonts.inter(
                      fontSize: 10.5, color: AppColors.cafeMedio),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.tiempoReal == null
                    ? 'en curso'
                    : 'real ${p.tiempoReal!.toStringAsFixed(1)} min',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro),
              ),
              const SizedBox(height: 3),
              if (err != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorErr.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('error ${err.toStringAsFixed(1)} min',
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: colorErr)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
