import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  ESTADO DEL PEDIDO
// ─────────────────────────────────────────────────────────────

enum EstadoPedido {
  recibido,
  enCocina,
  emplatado,
  enCamino,
  entregado,
}

extension EstadoPedidoX on EstadoPedido {
  String get etiqueta {
    switch (this) {
      case EstadoPedido.recibido:   return 'Recibido';
      case EstadoPedido.enCocina:   return 'En cocina';
      case EstadoPedido.emplatado:  return 'Emplatado';
      case EstadoPedido.enCamino:   return 'En camino';
      case EstadoPedido.entregado:  return 'Entregado';
    }
  }

  /// Progreso para la barra lineal (0.0 – 1.0)
  double get progreso {
    switch (this) {
      case EstadoPedido.recibido:   return 0.1;
      case EstadoPedido.enCocina:   return 0.35;
      case EstadoPedido.emplatado:  return 0.65;
      case EstadoPedido.enCamino:   return 0.85;
      case EstadoPedido.entregado:  return 1.0;
    }
  }

  Color get colorAcento {
    switch (this) {
      case EstadoPedido.recibido:   return AppColors.cafeMedio;
      case EstadoPedido.enCocina:   return AppColors.terracota;
      case EstadoPedido.emplatado:  return AppColors.oliva;
      case EstadoPedido.enCamino:   return const Color(0xFF5B8DB8);
      case EstadoPedido.entregado:  return AppColors.exitoTexto;
    }
  }

  Color get colorFondo {
    return colorAcento.withValues(alpha: 0.12);
  }

  Color get colorTexto {
    return colorAcento;
  }
}

// ─────────────────────────────────────────────────────────────
//  MODELO PEDIDO
// ─────────────────────────────────────────────────────────────

class Pedido {
  final String numero;
  final String plato;
  final String? detalle;
  final double precio;
  final EstadoPedido estado;
  final String horaPedido;
  final int minutosRestantes;
  final String? restauranteId;
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
    this.restauranteId,
    this.mesa,
    this.clienteNombre,
  });

  Pedido copyWith({
    String? numero,
    String? plato,
    String? detalle,
    double? precio,
    EstadoPedido? estado,
    String? horaPedido,
    int? minutosRestantes,
    String? restauranteId,
    String? mesa,
    String? clienteNombre,
  }) {
    return Pedido(
      numero:           numero           ?? this.numero,
      plato:            plato            ?? this.plato,
      detalle:          detalle          ?? this.detalle,
      precio:           precio           ?? this.precio,
      estado:           estado           ?? this.estado,
      horaPedido:       horaPedido       ?? this.horaPedido,
      minutosRestantes: minutosRestantes ?? this.minutosRestantes,
      restauranteId:    restauranteId    ?? this.restauranteId,
      mesa:             mesa             ?? this.mesa,
      clienteNombre:    clienteNombre    ?? this.clienteNombre,
    );
  }
}