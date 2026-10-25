/// Funciones pequeñas para mostrar números y fechas en pantalla.

String fmtNum(double n) {
  if (n == n.roundToDouble()) return n.toStringAsFixed(0);
  return n.toStringAsFixed(1);
}

String moneda(double n) {
  final t = n.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '\$$t';
}

String fechaCorta(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String fechaHora(DateTime? d) {
  if (d == null) return '';
  final h =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${fechaCorta(d)} $h';
}
