class ReservaModel {
  final int id;
  final int usuarioId;
  final int mesaId;
  final DateTime fechaHora;
  final int numeroPersonas;
  final String estado;
  final String? notas;
  final int? tiempoEsperaEstimado;
  final DateTime creadoEn;

  ReservaModel({
    required this.id,
    required this.usuarioId,
    required this.mesaId,
    required this.fechaHora,
    required this.numeroPersonas,
    required this.estado,
    this.notas,
    this.tiempoEsperaEstimado,
    required this.creadoEn,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'],
      usuarioId: json['usuario_id'],
      mesaId: json['mesa_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      numeroPersonas: json['numero_personas'],
      estado: json['estado'],
      notas: json['notas'],
      tiempoEsperaEstimado: json['tiempo_espera_estimado'],
      creadoEn: DateTime.parse(json['creado_en']),
    );
  }

  Map<String, dynamic> toJson() => {
        'mesa_id': mesaId,
        'fecha_hora': fechaHora.toIso8601String(),
        'numero_personas': numeroPersonas,
        if (notas != null) 'notas': notas,
      };
}