import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/reportes_service.dart';
import '../../theme/app_theme.dart';

/// Hoja "Exportar reportes": elige el periodo y el reporte, se descarga y se
/// abre el menú de compartir del celular (WhatsApp, correo, Drive, etc.).
void mostrarExportarReportes(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ExportarSheet(),
  );
}

enum _Periodo { hoy, dias7, dias30, todo }

class _Reporte {
  final String archivo;
  final String titulo;
  final String detalle;
  final IconData icono;
  final bool usaPeriodo;
  const _Reporte(this.archivo, this.titulo, this.detalle, this.icono,
      {this.usaPeriodo = true});
}

const _reportes = [
  _Reporte('resumen.pdf', 'Resumen del restaurante (PDF)',
      'Ventas, platos más vendidos, calificaciones e inventario', Icons.picture_as_pdf_outlined),
  _Reporte('ventas.csv', 'Ventas (Excel / CSV)',
      'Una fila por factura: método de pago, propina, total', Icons.receipt_long_outlined),
  _Reporte('calificaciones.csv', 'Calificaciones (Excel / CSV)',
      'Estrellas y comentarios por plato', Icons.star_outline),
  _Reporte('inventario.csv', 'Inventario actual (Excel / CSV)',
      'Stock, mínimos, costos y proveedor', Icons.inventory_2_outlined,
      usaPeriodo: false),
];

class _ExportarSheet extends StatefulWidget {
  const _ExportarSheet();

  @override
  State<_ExportarSheet> createState() => _ExportarSheetState();
}

class _ExportarSheetState extends State<_ExportarSheet> {
  _Periodo _periodo = _Periodo.dias30;
  String? _trabajando; // archivo que se está generando
  String? _error;

  ({DateTime? desde, DateTime? hasta}) _rango() {
    final hoy = DateTime.now();
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    switch (_periodo) {
      case _Periodo.hoy:
        return (desde: dia, hasta: dia);
      case _Periodo.dias7:
        return (desde: dia.subtract(const Duration(days: 6)), hasta: dia);
      case _Periodo.dias30:
        return (desde: dia.subtract(const Duration(days: 29)), hasta: dia);
      case _Periodo.todo:
        return (desde: null, hasta: null);
    }
  }

  Future<void> _exportar(_Reporte rep) async {
    if (_trabajando != null) return;
    setState(() {
      _trabajando = rep.archivo;
      _error = null;
    });

    final r = rep.usaPeriodo
        ? await ReportesService.descargar(rep.archivo,
            desde: _rango().desde, hasta: _rango().hasta)
        : await ReportesService.descargar(rep.archivo);
    if (!mounted) return;

    if (r.ruta == null) {
      setState(() {
        _trabajando = null;
        _error = r.error;
      });
      return;
    }

    try {
      await Share.shareXFiles(
        [
          XFile(r.ruta!,
              mimeType: rep.archivo.endsWith('.pdf')
                  ? 'application/pdf'
                  : 'text/csv')
        ],
        subject: 'Reporte WaitLess',
      );
      if (mounted) setState(() => _trabajando = null);
    } catch (e) {
      if (mounted) {
        setState(() {
          _trabajando = null;
          _error = 'No se pudo abrir el menú de compartir: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('Exportar reportes', style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 4),
              Text(
                'Solo incluye los datos de tu restaurante.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: AppColors.cafeMedio),
              ),
              const SizedBox(height: 16),
              Text('PERIODO', style: AppTheme.etiqueta(size: 11)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (p, texto) in const [
                    (_Periodo.hoy, 'Hoy'),
                    (_Periodo.dias7, 'Últimos 7 días'),
                    (_Periodo.dias30, 'Últimos 30 días'),
                    (_Periodo.todo, 'Todo'),
                  ])
                    ChoiceChip(
                      label: Text(texto),
                      selected: _periodo == p,
                      selectedColor: AppColors.terracota.withValues(alpha: 0.18),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _periodo == p
                            ? AppColors.terracotaOscuro
                            : AppColors.cafeMedio,
                      ),
                      onSelected: (_) => setState(() => _periodo = p),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alertaFondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.terracotaOscuro, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.terracotaOscuro,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final rep in _reportes)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: AppColors.superficie,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borde),
                  ),
                  child: ListTile(
                    enabled: _trabajando == null,
                    onTap: () => _exportar(rep),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.terracota.withValues(alpha: 0.12),
                      child: Icon(rep.icono,
                          color: AppColors.terracota, size: 20),
                    ),
                    title: Text(rep.titulo,
                        style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cafeOscuro)),
                    subtitle: Text(
                      rep.usaPeriodo
                          ? rep.detalle
                          : '${rep.detalle} (no depende del periodo)',
                      style: GoogleFonts.inter(
                          fontSize: 11.5, color: AppColors.cafeMedio),
                    ),
                    trailing: _trabajando == rep.archivo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.terracota),
                          )
                        : const Icon(Icons.ios_share,
                            color: AppColors.cafeMedio, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
