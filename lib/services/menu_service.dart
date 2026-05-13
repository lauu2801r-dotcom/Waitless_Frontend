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

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.categoria,
    this.imagenUrl,
    required this.disponible,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        categoria: json['categoria'] as String?,
        imagenUrl: json['imagen_url'] as String?,
        disponible: json['disponible'] as bool? ?? true,
      );

  String get precioFormateado {
    final p = precio.toInt();
    return '\$${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String get emoji {
    switch (categoria?.toLowerCase()) {
      case 'entradas':
        return '🥗';
      case 'principales':
        return '🍽️';
      case 'postres':
        return '🍰';
      case 'bebidas':
        return '🍹';
      default:
        return '🍴';
    }
  }
}

class MenuService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('waitless.token');
  }

  static Future<List<Producto>> obtenerMenu() async {
    try {
      final token = await _obtenerToken();
      debugPrint('🍽️ Token: $token');

      final response = await http.get(
        Uri.parse('$_baseUrl/menu/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🍽️ Status: ${response.statusCode}');
      debugPrint('🍽️ Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('🍽️ Total en JSON: ${data.length}');

        final productos = <Producto>[];
        for (final j in data) {
          try {
            final p = Producto.fromJson(j as Map<String, dynamic>);
            productos.add(p);
            debugPrint('✅ Parseado: ${p.nombre} disponible=${p.disponible}');
          } catch (e) {
            debugPrint('❌ Error parseando: $j → $e');
          }
        }

        debugPrint('🍽️ Disponibles: ${productos.where((p) => p.disponible).length}');
        return productos.where((p) => p.disponible).toList();
      }
      return [];
    } catch (e) {
      debugPrint('🔴 MenuService ERROR: $e');
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
      debugPrint('🔴 MenuService.obtenerPorCategoria ERROR: $e');
      return [];
    }
  }
}