import 'package:flutter/material.dart';

/// Estado global de configuración del usuario: tema y idioma.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('es');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  String get aparienciaLabel {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
    }
  }

  String get idiomaLabel {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      default:
        return 'Español';
    }
  }

  void setApariencia(String label) {
    final modo = switch (label) {
      'Oscuro' => ThemeMode.dark,
      'Sistema' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    if (modo == _themeMode) return;
    _themeMode = modo;
    notifyListeners();
  }

  void setIdioma(String label) {
    final loc = switch (label) {
      'English' => const Locale('en'),
      'Português' => const Locale('pt'),
      _ => const Locale('es'),
    };
    if (loc.languageCode == _locale.languageCode) return;
    _locale = loc;
    notifyListeners();
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope no encontrado');
    return scope!.notifier!;
  }
}
