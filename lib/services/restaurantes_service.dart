import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class RestauranteApi {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? tipoCocina;
  final String emoji;
  final String? imagenUrl;
  final bool activo;
  final int totalPlatos;
  final int mesasLibres;
  final List<String> categorias;
  final double? calificacionPromedio;
  final int totalCalificaciones;
  final bool? abiertoAhora; // null = sin horarios configurados
  final bool domicilioActivo;
  final int costoDomicilio;
  final int pedidoMinimoDomicilio;
  final String? telefono;

  const RestauranteApi({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.tipoCocina,
    this.emoji = '🍽️',
    this.imagenUrl,
    this.activo = true,
    this.totalPlatos = 0,
    this.mesasLibres = 0,
    this.categorias = const [],
    this.calificacionPromedio,
    this.totalCalificaciones = 0,
    this.abiertoAhora,
    this.domicilioActivo = true,
    this.costoDomicilio = 5000,
    this.pedidoMinimoDomicilio = 0,
    this.telefono,
  });

  factory RestauranteApi.fromJson(Map<String, dynamic> j) => RestauranteApi(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        tipoCocina: j['tipo_cocina'] as String?,
        emoji: (j['emoji'] as String?)?.trim().isNotEmpty == true
            ? j['emoji'] as String
            : '🍽️',
        imagenUrl: j['imagen_url'] as String?,
        activo: j['activo'] as bool? ?? true,
        totalPlatos: (j['total_platos'] as num?)?.toInt() ?? 0,
        mesasLibres: (j['mesas_libres'] as num?)?.toInt() ?? 0,
        categorias: ((j['categorias'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        calificacionPromedio: (j['calificacion_promedio'] as num?)?.toDouble(),
        totalCalificaciones: (j['total_calificaciones'] as num?)?.toInt() ?? 0,
        abiertoAhora: j['abierto_ahora'] as bool?,
        domicilioActivo: j['domicilio_activo'] as bool? ?? true,
        costoDomicilio: (j['costo_domicilio'] as num?)?.toInt() ?? 5000,
        pedidoMinimoDomicilio: (j['pedido_minimo_domicilio'] as num?)?.toInt() ?? 0,
        telefono: j['telefono'] as String?,
      );
}

class RestaurantesService {
  /// Datos actualizados de UN restaurante (envío, mínimo, si está abierto...). Null si falla.
  static Future<RestauranteApi?> obtener(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/restaurantes/$id'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return RestauranteApi.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('RestaurantesService.obtener ERROR: $e');
    }
    return null;
  }

  static Future<List<RestauranteApi>> listar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('waitless.token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/restaurantes/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((j) => RestauranteApi.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('RestaurantesService ERROR: $e');
      return [];
    }
  }
}