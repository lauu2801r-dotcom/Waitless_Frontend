import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/negocio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pagina_negocio.dart';

const _dias = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
const _nombres = {
  'lun': 'Lunes',
  'mar': 'Martes',
  'mie': 'Miércoles',
  'jue': 'Jueves',
  'vie': 'Viernes',
  'sab': 'Sábado',
  'dom': 'Domingo',
};

class _Dia {
  bool abierto;
  TimeOfDay abre;
  TimeOfDay cierra;
  _Dia({this.abierto = true, required this.abre, required this.cierra});
}

class _Especial {
  DateTime fecha;
  bool cerrado;
  TimeOfDay abre;
  TimeOfDay cierra;
  String nota;
  _Especial({
    required this.fecha,
    this.cerrado = true,
    required this.abre,
    required this.cierra,
    this.nota = '',
  });
}

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String? s, TimeOfDay porDefecto) {
  if (s == null || !s.contains(':')) return porDefecto;
  final p = s.split(':');
  return TimeOfDay(hour: int.tryParse(p[0]) ?? porDefecto.hour, minute: int.tryParse(p[1]) ?? 0);
}

int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

String _fechaStr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Horarios de atención: semana + días especiales (festivos, eventos, cierres).
/// El backend no deja reservar en días cerrados ni fuera del horario.
class AdminHorariosScreen extends StatefulWidget {
  const AdminHorariosScreen({super.key});

  @override
  State<AdminHorariosScreen> createState() => _AdminHorariosScreenState();
}

class _AdminHorariosScreenState extends State<AdminHorariosScreen> {
  static const _abreDef = TimeOfDay(hour: 12, minute: 0);
  static const _cierraDef = TimeOfDay(hour: 22, minute: 0);

  final Map<String, _Dia> _semana = {
    for (final d in _dias) d: _Dia(abre: _abreDef, cierra: _cierraDef),
  };
  final List<_Especial> _especiales = [];
  bool _cargando = true;
  bool _guardando = false;
  bool _sinHorarios = true;
  String? _error;

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
      final h = p.horarios;
      if (!mounted) return;
      if (h != null) {
        _sinHorarios = false;
        final sem = (h['semana'] as Map?) ?? {};
        for (final d in _dias) {
          final f = sem[d];
          if (f is Map) {
            _semana[d] = _Dia(
              abierto: true,
              abre: _parse(f['abre'] as String?, _abreDef),
              cierra: _parse(f['cierra'] as String?, _cierraDef),
            );
          } else {
            _semana[d] = _Dia(abierto: false, abre: _abreDef, cierra: _cierraDef);
          }
        }
        _especiales
          ..clear()
          ..addAll(((h['especiales'] as List?) ?? []).whereType<Map>().map((e) => _Especial(
                fecha: DateTime.tryParse('${e['fecha']}') ?? DateTime.now(),
                cerrado: e['cerrado'] == true,
                abre: _parse(e['abre'] as String?, _abreDef),
                cierra: _parse(e['cierra'] as String?, _cierraDef),
                nota: (e['nota'] ?? '') as String,
              )));
      }
      setState(() => _cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = limpiarError(e);
      });
    }
  }

  Future<TimeOfDay?> _elegirHora(TimeOfDay inicial) => showTimePicker(
        context: context,
        initialTime: inicial,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.terracota,
              onPrimary: AppColors.crema,
              surface: AppColors.crema,
            ),
          ),
          child: child!,
        ),
      );

  void _aplicarATodos(String origen) {
    final o = _semana[origen]!;
    setState(() {
      for (final d in _dias) {
        _semana[d] = _Dia(abierto: o.abierto, abre: o.abre, cierra: o.cierra);
      }
    });
    mostrarMensaje(context, 'Horario de ${_nombres[origen]!.toLowerCase()} aplicado a toda la semana');
  }

  Future<void> _agregarEspecial() async {
    final nuevo = await showDialog<_Especial>(
      context: context,
      builder: (_) => const _DialogoEspecial(),
    );
    if (nuevo != null) {
      setState(() {
        _especiales.removeWhere((e) => _iso(e.fecha) == _iso(nuevo.fecha));
        _especiales.add(nuevo);
        _especiales.sort((a, b) => a.fecha.compareTo(b.fecha));
      });
    }
  }

  Future<void> _guardar() async {
    for (final d in _dias) {
      final x = _semana[d]!;
      if (x.abierto && _minutos(x.abre) >= _minutos(x.cierra)) {
        mostrarMensaje(context, '${_nombres[d]}: la hora de cierre debe ser después de la apertura',
            error: true);
        return;
      }
    }
    setState(() => _guardando = true);
    try {
      await NegocioService.guardar({
        'horarios': {
          'semana': {
            for (final d in _dias)
              d: _semana[d]!.abierto
                  ? {'abre': _hhmm(_semana[d]!.abre), 'cierra': _hhmm(_semana[d]!.cierra)}
                  : null,
          },
          'especiales': [
            for (final e in _especiales)
              {
                'fecha': _iso(e.fecha),
                'cerrado': e.cerrado,
                if (!e.cerrado) 'abre': _hhmm(e.abre),
                if (!e.cerrado) 'cierra': _hhmm(e.cierra),
                if (e.nota.trim().isNotEmpty) 'nota': e.nota.trim(),
              },
          ],
        },
      });
      if (!mounted) return;
      mostrarMensaje(context, 'Horarios guardados');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, limpiarError(e), error: true);
    }
  }

  Widget _botonHora(TimeOfDay t, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Text(t.format(context), style: GoogleFonts.inter(fontSize: 12.5)),
      );

  Widget _filaDia(String d) {
    final x = _semana[d]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.superficieAdaptativa(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordeAdaptativo(context)),
      ),
      child: Row(children: [
        SizedBox(
          width: 88,
          child: Text(_nombres[d]!,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
        ),
        Switch(
          value: x.abierto,
          activeThumbColor: AppColors.terracota,
          onChanged: (v) => setState(() => x.abierto = v),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: x.abierto
              ? Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  _botonHora(x.abre, () async {
                    final t = await _elegirHora(x.abre);
                    if (t != null) setState(() => x.abre = t);
                  }),
                  const Text('–'),
                  _botonHora(x.cierra, () async {
                    final t = await _elegirHora(x.cierra);
                    if (t != null) setState(() => x.cierra = t);
                  }),
                ])
              : Text('Cerrado',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.cafeMedio)),
        ),
        PopupMenuButton<String>(
          tooltip: 'Más',
          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.cafeMedio),
          onSelected: (_) => _aplicarATodos(d),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'todos', child: Text('Copiar a toda la semana')),
          ],
        ),
      ]),
    );
  }

  Widget _filaEspecial(_Especial e) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.superficieAdaptativa(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bordeAdaptativo(context)),
        ),
        child: Row(children: [
          Icon(e.cerrado ? Icons.event_busy_outlined : Icons.event_available_outlined,
              color: e.cerrado ? AppColors.terracota : AppColors.oliva, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_fechaStr(e.fecha),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
              Text(
                [
                  e.cerrado ? 'Cerrado' : '${e.abre.format(context)} – ${e.cierra.format(context)}',
                  if (e.nota.trim().isNotEmpty) e.nota.trim(),
                ].join(' · '),
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.cafeMedio),
              ),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.cafeMedio),
            onPressed: () => setState(() => _especiales.remove(e)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return PaginaNegocio(
      titulo: 'Horarios de atención',
      botonInferior: _cargando || _error != null
          ? null
          : ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: AppColors.crema, strokeWidth: 2))
                  : const Text('GUARDAR HORARIOS'),
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    Text(
                      _sinHorarios
                          ? 'Aún no has definido horarios: los clientes pueden reservar a cualquier hora. '
                              'Al guardar, no se podrán hacer reservas en días cerrados ni fuera de horario.'
                          : 'Las reservas solo se aceptan dentro de estos horarios.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.cafeMedio, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Text('SEMANA', style: AppTheme.etiqueta()),
                    const SizedBox(height: 8),
                    for (final d in _dias) _filaDia(d),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Text('DÍAS ESPECIALES', style: AppTheme.etiqueta())),
                      TextButton.icon(
                        onPressed: _agregarEspecial,
                        icon: const Icon(Icons.add, size: 18, color: AppColors.terracota),
                        label: Text('Agregar',
                            style: GoogleFonts.inter(
                                color: AppColors.terracota, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    Text('Festivos, eventos privados o cierres: reemplazan el horario normal de esa fecha.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.cafeMedio)),
                    const SizedBox(height: 8),
                    if (_especiales.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text('No hay días especiales',
                            style: GoogleFonts.inter(color: AppColors.cafeMedio, fontSize: 13)),
                      )
                    else
                      for (final e in _especiales) _filaEspecial(e),
                  ],
                ),
    );
  }
}

class _DialogoEspecial extends StatefulWidget {
  const _DialogoEspecial();

  @override
  State<_DialogoEspecial> createState() => _DialogoEspecialState();
}

class _DialogoEspecialState extends State<_DialogoEspecial> {
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  bool _cerrado = true;
  TimeOfDay _abre = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _cierra = const TimeOfDay(hour: 16, minute: 0);
  final _nota = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora(bool apertura) async {
    final t = await showTimePicker(context: context, initialTime: apertura ? _abre : _cierra);
    if (t != null) setState(() => apertura ? _abre = t : _cierra = t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Día especial',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.cafeOscuro)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          OutlinedButton.icon(
            onPressed: _elegirFecha,
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(_fechaStr(_fecha)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Cerrado todo el día', style: GoogleFonts.inter(fontSize: 14)),
            value: _cerrado,
            activeThumbColor: AppColors.terracota,
            onChanged: (v) => setState(() => _cerrado = v),
          ),
          if (!_cerrado)
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _elegirHora(true), child: Text(_abre.format(context)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–')),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _elegirHora(false), child: Text(_cierra.format(context)))),
            ]),
          const SizedBox(height: 8),
          TextField(
            controller: _nota,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nota (opcional)', hintText: 'Ej: Navidad'),
          ),
          if (_error != null)
            Text(_error!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.terracotaOscuro)),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.cafeMedio)),
        ),
        TextButton(
          onPressed: () {
            if (!_cerrado && _minutos(_abre) >= _minutos(_cierra)) {
              setState(() => _error = 'El cierre debe ser después de la apertura');
              return;
            }
            Navigator.pop(
              context,
              _Especial(
                fecha: _fecha,
                cerrado: _cerrado,
                abre: _abre,
                cierra: _cierra,
                nota: _nota.text,
              ),
            );
          },
          child: Text('Agregar',
              style: GoogleFonts.inter(color: AppColors.terracota, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
