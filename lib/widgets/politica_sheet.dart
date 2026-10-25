import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_controller.dart';
import '../services/auth_repository.dart';
import '../theme/app_theme.dart';

/// Muestra la política de tratamiento de datos cargándola desde el backend.
Future<void> mostrarPoliticaPrivacidad(BuildContext context) {
  final futuro = AuthScope.of(context).obtenerPolitica();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FutureBuilder<AuthResultado<PoliticaPrivacidad>>(
          future: futuro,
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.terracota),
              );
            }

            final r = snap.data;
            final String titulo;
            final String version;
            final String texto;
            if (r is AuthExito<PoliticaPrivacidad>) {
              titulo = r.datos.titulo;
              version = 'Versión ${r.datos.version}';
              texto = r.datos.texto;
            } else {
              titulo = 'Política de tratamiento de datos';
              version = '';
              texto = r is AuthError<PoliticaPrivacidad>
                  ? r.mensaje
                  : 'No se pudo cargar la política. Intenta de nuevo.';
            }

            return Column(
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
                Text(titulo, style: AppTheme.titulo(size: 20)),
                if (version.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(version.toUpperCase(),
                      style: AppTheme.etiqueta(size: 10)),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: Text(
                      texto,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.cafeOscuro,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ENTENDIDO'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}