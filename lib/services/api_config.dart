class ApiConfig {
  ApiConfig._(); 
  /// URL base del backend. Cambia aquí y se aplica en todo el proyecto.
  /// - Emulador Android : http://10.0.2.2:8000
  /// - Dispositivo físico: http://<IP-de-tu-PC>:8000
    static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  /// Enlace del informe de Power BI (Archivo → Insertar informe → Publicar en la web,
  /// o el enlace "Compartir" del informe publicado en Power BI Service).
  /// Mientras esté vacío, el botón del panel de Análisis avisa que aún no está configurado.
  static const String powerBiUrl = 'https://app.powerbi.com/view?r=eyJrIjoiNjAxYjE3OTMtN2EzYS00MmM2LWI3NDUtOGJiZjgxZTI1MTMzIiwidCI6ImI0OWRiNjI0LTI1NDYtNDI1OS1iZjM2LTE5OWM2ZTk4ODAzMyIsImMiOjR9';
   /// Convierte la ruta de una imagen guardada en el backend (/static/...)
  /// en una URL completa. Si ya es un enlace http(s) lo deja igual.
  static String? imagen(String? ruta) {
    if (ruta == null || ruta.trim().isEmpty) return null;
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) return ruta;
    final separador = ruta.startsWith('/') ? '' : '/';
    return baseUrl + separador + ruta;
  }
}