import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class MesaModel {
  final int id;
  final int numero;
  final int capacidad;
  final String estado;
  final String? ubicacion;

  MesaModel({
    required this.id,
    required this.numero,
    required this.capacidad,
    required this.estado,
    this.ubicacion,
  });

  factory MesaModel.fromJson(Map<String, dynamic> json) => MesaModel(
        id: json['id'],
        numero: json['numero'],
        capacidad: json['capacidad'],
        estado: json['estado'],
        ubicacion: json['ubicacion'],
      );
}

class MesaService {
  static const String _kClaveToken = 'waitless.token';

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kClaveToken);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Todas las mesas (activas e inactivas) — usa GET /mesas/
  Future<List<MesaModel>> todasLasMesas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/mesas/'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MesaModel.fromJson(e)).toList();
    }
    throw Exception('Error al cargar mesas');
  }

  /// Cambia el estado de una mesa (libre, ocupada, reservada, en_limpieza).
  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> cambiarEstado(int mesaId, String estado) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/mesas/$mesaId/estado?estado=$estado'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return null;
      try {
        final d = jsonDecode(utf8.decode(response.bodyBytes))['detail'];
        if (d is String) return d;
      } catch (_) {}
      if (response.statusCode == 403) return 'No tienes permiso para cambiar esta mesa';
      return 'No se pudo cambiar el estado';
    } catch (_) {
      return 'No se pudo conectar con el servidor';
    }
  }

  /// Solo mesas disponibles — usa GET /mesas/disponibles
  Future<List<MesaModel>> mesasDisponibles() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/mesas/disponibles'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => MesaModel.fromJson(e)).toList();
    }
    throw Exception('Error al cargar mesas disponibles');
  }
}