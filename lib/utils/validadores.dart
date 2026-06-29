class Validadores {
  static String? correo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v)) return 'Formato de correo inválido';
    return null;
  }

  static String? password(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  static String? confirmarPassword(String? valor, String passwordOriginal) {
    if (valor == null || valor.isEmpty) return 'Confirma tu contraseña';
    if (valor != passwordOriginal) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? nombreCompleto(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length < 3) return 'Nombre demasiado corto';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  static int fortalezaPassword(String v) {
    int puntos = 0;
    if (v.length >= 8) puntos++;
    if (RegExp(r'[A-Z]').hasMatch(v)) puntos++;
    if (RegExp(r'[0-9]').hasMatch(v)) puntos++;
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:"\\|,.<>\/\?]').hasMatch(v)) {
      puntos++;
    }
    return puntos;
  }
}