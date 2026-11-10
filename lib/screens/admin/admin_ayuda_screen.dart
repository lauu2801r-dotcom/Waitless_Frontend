import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';

/// Centro de ayuda: preguntas frecuentes para el personal del restaurante.
class AdminAyudaScreen extends StatelessWidget {
  const AdminAyudaScreen({super.key});

  static const _faqs = <(String, String, String)>[
    ('Pedidos', '¿Cómo cambio el estado de un pedido?',
        'En la pestaña Pedidos abre el pedido y avanza su estado: en preparación → listo → entregado. El cliente recibe un aviso en cada cambio.'),
    ('Pedidos', '¿Qué es el tiempo estimado que aparece en un pedido?',
        'Lo calcula el modelo de inteligencia artificial de WaitLess según los platos, la hora y la carga del restaurante. Mejora solo con cada pedido real que se entrega.'),
    ('Reservas', '¿Cómo confirmo o cancelo una reserva?',
        'En la pestaña Reservas, las nuevas aparecen en "Por confirmar". Pulsa Confirmar, o Cancelar escribiendo un motivo: el cliente recibe el aviso con ese motivo.'),
    ('Reservas', '¿Por qué un cliente no puede reservar a cierta hora?',
        'Si definiste tus Horarios de atención, el sistema no acepta reservas en días cerrados ni fuera del horario. Revisa Negocio → Horarios de atención y los días especiales.'),
    ('Negocio', '¿Cómo cierro el restaurante por un festivo o evento?',
        'En Negocio → Horarios de atención, sección "Días especiales", agrega la fecha y marca "Cerrado todo el día" (o define otro horario para ese día).'),
    ('Inventario', '¿Cómo sé qué insumos se están acabando?',
        'En Negocio → Inventario verás los insumos bajo el mínimo. Desde Compras puedes generar una orden al proveedor.'),
    ('Pagos', '¿Los pagos son reales?',
        'No. En esta versión la pasarela de pago es simulada con fines académicos: genera facturas y las envía por correo, pero no mueve dinero.'),
    ('Cuenta', '¿Cómo cambio mi contraseña?',
        'En Negocio → Seguridad y acceso. Te pedimos la contraseña actual y la nueva.'),
    ('Reportes', '¿Cómo descargo los reportes?',
        'En el Panel, pulsa el ícono de descarga junto a actualizar: puedes exportar ventas, inventario y calificaciones en CSV, o el resumen en PDF.'),
  ];

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<(String, String, String)>>{};
    for (final f in _faqs) {
      grupos.putIfAbsent(f.$1, () => []).add(f);
    }
    return PaginaNegocio(
      titulo: 'Centro de ayuda',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          for (final e in grupos.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(e.key.toUpperCase(), style: AppTheme.etiqueta()),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.superficieAdaptativa(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.bordeAdaptativo(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final f in e.value)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      expandedAlignment: Alignment.centerLeft,
                      iconColor: AppColors.terracota,
                      title: Text(f.$2,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
                      children: [
                        Text(f.$3,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.cafeMedio, height: 1.5)),
                      ],
                    ),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'WaitLess es un proyecto de grado de Ingeniería de Software (Universidad Manuela Beltrán). '
            'Si algo no funciona como esperas, cuéntanos al equipo del proyecto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio, height: 1.5),
          ),
        ],
      ),
    );
  }
}
