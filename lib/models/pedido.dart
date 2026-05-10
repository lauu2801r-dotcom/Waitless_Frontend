import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum EstadoPedido { recibido, enCocina, emplatado, enCamino, entregado }

extension EstadoPedidoX on EstadoPedido {
  String get etiqueta {
    switch (this) {
      case EstadoPedido.recibido:
        return 'Recibido';
      case EstadoPedido.enCocina:
        return 'En cocina';
      case EstadoPedido.emplatado:
        return 'Emplatando';
      case EstadoPedido.enCamino:
        return 'En camino';
      case EstadoPedido.entregado:
        return 'Entregado';
    }
  }

  Color get colorFondo {
    switch (this) {
      case EstadoPedido.recibido:
        return AppColors.cremaOscura;
      case EstadoPedido.enCocina:
        return AppColors.infoFondo;
      case EstadoPedido.emplatado:
      case EstadoPedido.enCamino:
        return AppColors.alertaFondo;
      case EstadoPedido.entregado:
        return AppColors.exitoFondo;
    }
  }

  Color get colorTexto {
    switch (this) {
      case EstadoPedido.recibido:
        return AppColors.cafeMedio;
      case EstadoPedido.enCocina:
        return AppColors.infoTexto;
      case EstadoPedido.emplatado:
      case EstadoPedido.enCamino:
        return AppColors.alertaTexto;
      case EstadoPedido.entregado:
        return AppColors.exitoTexto;
    }
  }

  Color get colorAcento {
    switch (this) {
      case EstadoPedido.recibido:
        return AppColors.cafeMedio;
      case EstadoPedido.enCocina:
        return AppColors.oliva;
      case EstadoPedido.emplatado:
      case EstadoPedido.enCamino:
        return AppColors.terracota;
      case EstadoPedido.entregado:
        return AppColors.olivaSuave;
    }
  }

  double get progreso {
    switch (this) {
      case EstadoPedido.recibido:
        return 0.2;
      case EstadoPedido.enCocina:
        return 0.5;
      case EstadoPedido.emplatado:
        return 0.75;
      case EstadoPedido.enCamino:
        return 0.9;
      case EstadoPedido.entregado:
        return 1.0;
    }
  }
}

class Pedido {
  final String numero;
  final String plato;
  final String? detalle;
  final double precio;
  final EstadoPedido estado;
  final String horaPedido;
  final int minutosRestantes;
  final String restauranteId;
  final String? mesa;
  final String? clienteNombre;

  const Pedido({
    required this.numero,
    required this.plato,
    this.detalle,
    required this.precio,
    required this.estado,
    required this.horaPedido,
    required this.minutosRestantes,
    required this.restauranteId,
    this.mesa,
    this.clienteNombre,
  });

  Pedido copyWith({
    EstadoPedido? estado,
    int? minutosRestantes,
    String? mesa,
    String? clienteNombre,
  }) =>
      Pedido(
        numero: numero,
        plato: plato,
        detalle: detalle,
        precio: precio,
        estado: estado ?? this.estado,
        horaPedido: horaPedido,
        minutosRestantes: minutosRestantes ?? this.minutosRestantes,
        restauranteId: restauranteId,
        mesa: mesa ?? this.mesa,
        clienteNombre: clienteNombre ?? this.clienteNombre,
      );
}
