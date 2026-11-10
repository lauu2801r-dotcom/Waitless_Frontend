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

  // Reservas del restaurante (administrador / empleado)
  Future<List<ReservaModel>> reservasDelRestaurante() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reservas/todas'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ReservaModel.fromJson(e)).toList();
    }
    throw Exception(_detalle(response.body, 'Error al obtener las reservas'));
  }

  // El restaurante confirma o completa una reserva
  Future<ReservaModel> cambiarEstado(int reservaId, String estado) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId'),
      headers: await _headers(),
      body: jsonEncode({'estado': estado}),
    );
    if (response.statusCode == 200) {
      return ReservaModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_detalle(response.body, 'No se pudo cambiar el estado'));
  }

  // Modificar reserva (fecha/hora, personas, notas)
  Future<ReservaModel> modificarReserva(
    int reservaId, {
    DateTime? fechaHora,
    int? numeroPersonas,
    String? notas,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId'),
      headers: await _headers(),
      body: jsonEncode({
        if (fechaHora != null) 'fecha_hora': fechaHora.toIso8601String(),
        if (numeroPersonas != null) 'numero_personas': numeroPersonas,
        if (notas != null) 'notas': notas,
      }),
    );
    if (response.statusCode == 200) {
      return ReservaModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_detalle(response.body, 'Error al modificar la reserva'));
  }

  // Cancelar reserva (con motivo opcional)
  Future<void> cancelarReserva(int reservaId, {String? motivo}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId').replace(
      queryParameters: {
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
    final response = await http.delete(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception(_detalle(response.body, 'Error al cancelar reserva'));
    }
  }

  /// Saca el mensaje de error del backend (FastAPI manda {"detail": "..."} o una lista).
  String _detalle(String body, String porDefecto) {
    try {
      final d = jsonDecode(body)['detail'];
      if (d is String) return d;
      if (d is List && d.isNotEmpty && d.first is Map) {
        return (d.first['msg'] ?? porDefecto).toString();
      }
    } catch (_) {}
    return porDefecto;
  }
}
