import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';

class _Promo {
  String nombre;
  String detalle;
  String descuento;
  bool activa;
  _Promo(this.nombre, this.detalle, this.descuento, {this.activa = false});
}

/// Promociones (versión de demostración).
/// Muestra ejemplos y permite crear y activar promos, pero por ahora NO se
/// guardan en el servidor ni se aplican a los precios: queda como trabajo futuro.
class AdminPromocionesScreen extends StatefulWidget {
  const AdminPromocionesScreen({super.key});

  @override
  State<AdminPromocionesScreen> createState() => _AdminPromocionesScreenState();
}

class _AdminPromocionesScreenState extends State<AdminPromocionesScreen> {
  final List<_Promo> _promos = [
    _Promo('Almuerzo ejecutivo', 'Lunes a viernes de 12:00 a 15:00', '15 %', activa: true),
    _Promo('Martes de pasta', 'Todas las pastas, solo los martes', '2x1'),
    _Promo('Cliente frecuente', 'A partir de la quinta visita del mes', '10 %'),
    _Promo('Promo express', 'Mesas libres en horas valle (15:00 a 18:00)', '20 %'),
  ];

  Future<void> _nueva() async {
    final nombre = TextEditingController();
    final detalle = TextEditingController();
    final descuento = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nueva promoción',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nombre,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: detalle,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Condiciones')),
            TextField(
                controller: descuento,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Descuento', hintText: 'Ej: 10 % o 2x1')),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Crear',
                style: GoogleFonts.inter(color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    final n = nombre.text.trim(), d = detalle.text.trim(), x = descuento.text.trim();
    nombre.dispose();
    detalle.dispose();
    descuento.dispose();
    if (ok == true && n.isNotEmpty) {
      setState(() => _promos.insert(0, _Promo(n, d.isEmpty ? 'Sin condiciones' : d, x.isEmpty ? '—' : x)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Promociones',
      botonInferior: ElevatedButton.icon(
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('NUEVA PROMOCIÓN'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.alertaFondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.terracota.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.alertaTexto),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Versión de demostración: estas promociones son ejemplos y todavía no se guardan '
                  'ni se aplican a los precios de los pedidos.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.alertaTexto, height: 1.4),
                ),
              ),
            ]),
          ),
          for (final p in _promos)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                color: AppColors.superficieAdaptativa(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.bordeAdaptativo(context)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.terracota.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(p.descuento,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: AppColors.terracota, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nombre,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.cafeOscuro)),
                    const SizedBox(height: 2),
                    Text(p.detalle,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
                  ]),
                ),
                Switch(
                  value: p.activa,
                  activeThumbColor: AppColors.terracota,
                  onChanged: (v) => setState(() => p.activa = v),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.cafeMedio, size: 20),
                  onPressed: () => setState(() => _promos.remove(p)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
