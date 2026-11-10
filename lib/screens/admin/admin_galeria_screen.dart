import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/negocio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';

/// Galería del restaurante: fotos por enlace (https). Se guarda en cada cambio.
class AdminGaleriaScreen extends StatefulWidget {
  const AdminGaleriaScreen({super.key});

  @override
  State<AdminGaleriaScreen> createState() => _AdminGaleriaScreenState();
}

class _AdminGaleriaScreenState extends State<AdminGaleriaScreen> {
  List<String> _fotos = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  static const _max = 12;

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
    try {
      final p = await NegocioService.obtener();
      if (!mounted) return;
      setState(() {
        _fotos = p.galeria;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = limpiarError(e);
      });
    }
  }

  Future<void> _guardar(List<String> nuevas) async {
    setState(() => _guardando = true);
    try {
      final p = await NegocioService.guardar({'galeria': nuevas});
      if (!mounted) return;
      setState(() {
        _fotos = p.galeria;
        _guardando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, limpiarError(e), error: true);
    }
  }

  Future<void> _agregar() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Agregar foto',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enlace de la imagen',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('Agregar',
                style: GoogleFonts.inter(color: AppColors.terracota, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null || url.isEmpty) return;
    if (!url.toLowerCase().startsWith('http')) {
      if (mounted) mostrarMensaje(context, 'El enlace debe empezar por https://', error: true);
      return;
    }
    await _guardar([..._fotos, url]);
  }

  Future<void> _quitar(int i) async {
    final copia = [..._fotos]..removeAt(i);
    await _guardar(copia);
  }

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Galería',
      acciones: [
        if (_guardando)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracota),
              ),
            ),
          ),
      ],
      botonInferior: _cargando || _error != null
          ? null
          : ElevatedButton.icon(
              onPressed: _guardando || _fotos.length >= _max ? null : _agregar,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_fotos.length >= _max ? 'LÍMITE DE $_max FOTOS' : 'AGREGAR FOTO'),
            ),
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracota))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                  ]),
                )
              : _fotos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.image_outlined, size: 48, color: AppColors.cafeMedio),
                          const SizedBox(height: 10),
                          Text(
                            'Aún no hay fotos. Agrega enlaces de imágenes de tus platos, tu local o tus eventos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio),
                          ),
                        ]),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _fotos.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.network(
                            _fotos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.cremaOscura,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              child: Text('No se pudo cargar la imagen',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.cafeMedio)),
                            ),
                            loadingBuilder: (_, child, progreso) => progreso == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(color: AppColors.terracota)),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _guardando ? null : () => _quitar(i),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
    );
  }
}
