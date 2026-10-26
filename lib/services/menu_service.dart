import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'package:flutter/foundation.dart';

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? categoria;
  final String? imagenUrl;
  final bool disponible;
  final int? restauranteId;
  final String? restauranteNombre;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.categoria,
    this.imagenUrl,
    required this.disponible,
    this.restauranteId,
    this.restauranteNombre,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        categoria: json['categoria'] as String?,
        imagenUrl: json['imagen_url'] as String?,
        disponible: json['disponible'] as bool? ?? true,
        restauranteId: json['restaurante_id'] as int?,
        restauranteNombre: json['restaurante_nombre'] as String?,
      );

  String get precioFormateado {
    final p = precio.toInt();
    return '\$${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Emoji según el tipo de comida (sirve para cualquier restaurante).
  static String emojiCategoria(String? categoria) {
    switch (categoria?.trim().toLowerCase()) {
      case 'entradas':
        return '🥗';
      case 'principales':
        return '🍽️';
      case 'postres':
        return '🍰';
      case 'bebidas':
        return '🥤';
      case 'hamburguesas':
        return '🍔';
      case 'perros calientes':
        return '🌭';
      case 'combos':
        return '🥡';
      case 'acompañantes':
        return '🍟';
      default:
        return '🍴';
    }
  }

  String get emoji => emojiCategoria(categoria);
}

class MenuService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('waitless.token');
  }

  /// Menú disponible. Si se pasa [restauranteId] solo trae los platos de ese restaurante.
  static Future<List<Producto>> obtenerMenu({int? restauranteId}) async {
    try {
      final token = await _obtenerToken();
      final url = restauranteId == null
          ? '$_baseUrl/menu/'
          : '$_baseUrl/menu/?restaurante_id=$restauranteId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final productos = <Producto>[];
        for (final j in data) {
          try {
            productos.add(Producto.fromJson(j as Map<String, dynamic>));
          } catch (e) {
            debugPrint('MenuService: error parseando $j → $e');
          }
        }
        return productos.where((p) => p.disponible).toList();
      }
      return [];
    } catch (e) {
      debugPrint('MenuService ERROR: $e');
      return [];
    }
  }

  static Future<List<Producto>> obtenerPorCategoria(String categoria) async {
    try {
      final token = await _obtenerToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/menu/categoria/$categoria'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((j) => Producto.fromJson(j as Map<String, dynamic>))
            .where((p) => p.disponible)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('MenuService.obtenerPorCategoria ERROR: $e');
      return [];
    }
  }
}
