import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reserva_model.dart';
import 'api_config.dart';

class ReservaService {
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

  // Crear reserva
  Future<ReservaModel> crearReserva({
    required int mesaId,
    required DateTime fechaHora,
    required int numeroPersonas,
    String? notas,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reservas/'),
      headers: await _headers(),
      body: jsonEncode({
        'mesa_id': mesaId,
        'fecha_hora': fechaHora.toIso8601String(),
        'numero_personas': numeroPersonas,
        if (notas != null) 'notas': notas,
      }),
    );

    if (response.statusCode == 200) {
      return ReservaModel.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al crear reserva');
    }
  }

  // Mis reservas
  Future<List<ReservaModel>> misReservas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reservas/mis-reservas'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ReservaModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener reservas');
    }
  }

  // Cancelar reserva
  Future<void> cancelarReserva(int reservaId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al cancelar reserva');
    }
  }
}