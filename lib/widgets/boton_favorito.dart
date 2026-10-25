import 'package:flutter/material.dart';

import '../services/clientes_service.dart';
import '../services/inventario_service.dart' show InvExito, InvError;
import '../theme/app_theme.dart';

/// Corazón para marcar o quitar un plato de favoritos (guardado en el servidor).
class BotonFavorito extends StatefulWidget {
  final int productoId;
  const BotonFavorito({super.key, required this.productoId});

  @override
  State<BotonFavorito> createState() => _BotonFavoritoState();
}

class _BotonFavoritoState extends State<BotonFavorito> {
  bool _esFavorito = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    final r = await ClientesService.favoritos();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (r is InvExito<List<FavoritoApi>>) {
        _esFavorito = r.datos.any((f) => f.productoId == widget.productoId);
      }
    });
  }

  Future<void> _alternar() async {
    final nuevo = !_esFavorito;
    setState(() => _esFavorito = nuevo); // respuesta inmediata
    final r = nuevo
        ? await ClientesService.marcarFavorito(widget.productoId)
        : await ClientesService.quitarFavorito(widget.productoId);
    if (!mounted) return;
    if (r is InvError<bool>) {
      setState(() => _esFavorito = !nuevo); // se deshace si falló
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.mensaje),
        backgroundColor: AppColors.terracotaOscuro,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
      onPressed: _cargando ? null : _alternar,
      icon: Icon(
        _esFavorito ? Icons.favorite : Icons.favorite_border,
        color: AppColors.terracota,
      ),
    );
  }
}
