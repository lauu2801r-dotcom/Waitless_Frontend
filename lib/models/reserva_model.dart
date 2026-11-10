class ReservaModel {
  final int id;
  final int usuarioId;
  final int mesaId;
  final int? mesaNumero;
  final String? clienteNombre;
  final DateTime fechaHora;
  final int numeroPersonas;
  final String estado;
  final String? notas;
  final int? tiempoEsperaEstimado;
  final String? motivoCancelacion;
  final DateTime creadoEn;

  ReservaModel({
    required this.id,
    required this.usuarioId,
    required this.mesaId,
    this.mesaNumero,
    this.clienteNombre,
    required this.fechaHora,
    required this.numeroPersonas,
    required this.estado,
    this.notas,
    this.tiempoEsperaEstimado,
    this.motivoCancelacion,
    required this.creadoEn,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'],
      usuarioId: json['usuario_id'],
      mesaId: json['mesa_id'],
      mesaNumero: json['mesa_numero'],
      clienteNombre: json['cliente_nombre'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      numeroPersonas: json['numero_personas'],
      estado: json['estado'],
      notas: json['notas'],
      tiempoEsperaEstimado: json['tiempo_espera_estimado'],
      motivoCancelacion: json['motivo_cancelacion'],
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