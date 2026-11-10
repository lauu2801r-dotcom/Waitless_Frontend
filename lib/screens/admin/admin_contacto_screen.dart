import 'package:flutter/material.dart';

import '../../services/negocio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';

/// Ubicación y contacto del restaurante.
class AdminContactoScreen extends StatefulWidget {
  const AdminContactoScreen({super.key});

  @override
  State<AdminContactoScreen> createState() => _AdminContactoScreenState();
}

class _AdminContactoScreenState extends State<AdminContactoScreen> {
  final _direccion = TextEditingController();
  final _telefono = TextEditingController();
  final _instagram = TextEditingController();
  final _minutosMesa = TextEditingController(text: '90');
  final _costoEnvio = TextEditingController(text: '5000');
  final _pedidoMinimo = TextEditingController(text: '0');
  bool _domicilioActivo = true;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _direccion.dispose();
    _telefono.dispose();
    _instagram.dispose();
    _minutosMesa.dispose();
    _costoEnvio.dispose();
    _pedidoMinimo.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final p = await NegocioService.obtener();
      if (!mounted) return;
      _direccion.text = p.direccion ?? '';
      _telefono.text = p.telefono ?? '';
      _instagram.text = p.instagram ?? '';
      _minutosMesa.text = '${p.minutosAlertaMesa}';
      _costoEnvio.text = '${p.costoDomicilio}';
      _pedidoMinimo.text = '${p.pedidoMinimoDomicilio}';
      _domicilioActivo = p.domicilioActivo;
      setState(() => _cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = limpiarError(e);
      });
    }
  }

  Future<void> _guardar() async {
    final minutos = int.tryParse(_minutosMesa.text.trim());
    if (minutos == null || minutos < 15 || minutos > 480) {
      mostrarMensaje(context, 'El tiempo máximo de una mesa debe estar entre 15 y 480 minutos', error: true);
      return;
    }
    final envio = int.tryParse(_costoEnvio.text.trim());
    final minimo = int.tryParse(_pedidoMinimo.text.trim());
    if (envio == null || envio < 0 || envio > 50000) {
      mostrarMensaje(context, 'El costo de envío debe estar entre 0 y 50.000', error: true);
      return;
    }
    if (minimo == null || minimo < 0 || minimo > 500000) {
      mostrarMensaje(context, 'El pedido mínimo debe estar entre 0 y 500.000', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await NegocioService.guardar({
        'minutos_alerta_mesa': minutos,
        'domicilio_activo': _domicilioActivo,
        'costo_domicilio': envio,
        'pedido_minimo_domicilio': minimo,
        'direccion': _direccion.text.trim(),
        'telefono': _telefono.text.trim(),
        'instagram': _instagram.text.trim(),
      });
      if (!mounted) return;
      mostrarMensaje(context, 'Datos de contacto guardados');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, limpiarError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Ubicación y contacto',
      botonInferior: _cargando || _error != null
          ? null
          : ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: AppColors.crema, strokeWidth: 2))
                  : const Text('GUARDAR'),
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
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('DIRECCIÓN', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _direccion,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Cra 7 # 45-10, Bogotá',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.cafeMedio),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('TELÉFONO', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _telefono,
                      keyboardType: TextInputType.phone,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        hintText: 'Ej: +57 601 234 5678',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.cafeMedio),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('INSTAGRAM', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instagram,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        hintText: '@turestaurante',
                        prefixIcon: Icon(Icons.alternate_email, color: AppColors.cafeMedio),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('ALERTA DE MESA OCUPADA (MINUTOS)', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _minutosMesa,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      decoration: const InputDecoration(
                        helperText: 'Si una mesa pasa de este tiempo ocupada, avisamos al personal (15 a 480).',
                        helperMaxLines: 2,
                        prefixIcon: Icon(Icons.timer_outlined, color: AppColors.cafeMedio),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('SERVICIO A DOMICILIO', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.terracota,
                      title: const Text('Recibir pedidos a domicilio'),
                      subtitle: Text(
                        _domicilioActivo
                            ? 'Los clientes pueden pedir domicilio mientras estés abierto.'
                            : 'Desactivado: los clientes no verán la opción de domicilio.',
                      ),
                      value: _domicilioActivo,
                      onChanged: (v) => setState(() => _domicilioActivo = v),
                    ),
                    if (_domicilioActivo) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _costoEnvio,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: const InputDecoration(
                          labelText: 'Costo de envío (\$)',
                          helperText: 'Se suma al total del pedido. Pon 0 si el envío es gratis.',
                          helperMaxLines: 2,
                          prefixIcon: Icon(Icons.delivery_dining, color: AppColors.cafeMedio),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pedidoMinimo,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Pedido mínimo (\$)',
                          helperText: 'Valor mínimo de los platos para pedir a domicilio. 0 = sin mínimo.',
                          helperMaxLines: 2,
                          prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppColors.cafeMedio),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
