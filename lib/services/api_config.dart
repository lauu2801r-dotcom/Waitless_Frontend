class ApiConfig {
  ApiConfig._(); // No instanciable

  /// URL base del backend. Cambia aquí y se aplica en todo el proyecto.
  /// - Emulador Android : http://10.0.2.2:8000
  /// - Dispositivo físico: http://<IP-de-tu-PC>:8000
  static const String baseUrl = 'http://10.0.0.2:8000';
}