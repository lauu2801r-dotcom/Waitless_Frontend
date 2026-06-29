import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores cálida/gastronómica para la app.
/// Inspirada en tonos tierra: terracota, crema, oliva y café oscuro.
class AppColors {
  // ── Modo claro (default) ──
  static const Color terracota = Color(0xFFC65D3A);
  static const Color terracotaOscuro = Color(0xFF8A3B1C);
  static const Color crema = Color(0xFFFBF7F0);
  static const Color cremaOscura = Color(0xFFF0E4D2);
  static const Color cafeOscuro = Color(0xFF3D2817);
  static const Color cafeMedio = Color(0xFF8B6F4E);

  static const Color oliva = Color(0xFF7B8B3C);
  static const Color olivaSuave = Color(0xFFA8B89A);
  static const Color olivaFondo = Color(0xFFE8EDD2);

  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFE8DDD0);
  static const Color bordeSuave = Color(0xFFF0E4D2);

  static const Color exitoFondo = Color(0xFFE0E8DA);
  static const Color exitoTexto = Color(0xFF4A5A3C);
  static const Color infoFondo = Color(0xFFE8EDD2);
  static const Color infoTexto = Color(0xFF5A6B1F);
  static const Color alertaFondo = Color(0xFFFBE4D8);
  static const Color alertaTexto = Color(0xFF8A3B1C);

  // ── Modo oscuro (equivalentes invertidos para dark mode) ──
  static const Color cremaDark = Color(0xFF1A1310);
  static const Color cremaOscuraDark = Color(0xFF2A1F18);
  static const Color superficieDark = Color(0xFF231914);
  static const Color cafeOscuroDark = Color(0xFFF0E4D2);
  static const Color cafeMedioDark = Color(0xFFB8A38B);
  static const Color bordeDark = Color(0xFF3A2E25);
  static const Color bordeSuaveDark = Color(0xFF302419);

  /// Devuelve el color de fondo principal según el brillo actual.
  static Color fondo(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? cremaDark : crema;

  static Color superficieAdaptativa(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? superficieDark : superficie;

  static Color textoPrincipal(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? cafeOscuroDark : cafeOscuro;

  static Color textoSecundario(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? cafeMedioDark : cafeMedio;

  static Color bordeAdaptativo(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? bordeDark : borde;
}

/// Tema global de la aplicación.
class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final esOscuro = brightness == Brightness.dark;
    final base = esOscuro ? ThemeData.dark() : ThemeData.light();

    final fondo = esOscuro ? AppColors.cremaDark : AppColors.crema;
    final superficie =
        esOscuro ? AppColors.superficieDark : AppColors.superficie;
    final textoPrincipal =
        esOscuro ? AppColors.cafeOscuroDark : AppColors.cafeOscuro;
    final textoSecundario =
        esOscuro ? AppColors.cafeMedioDark : AppColors.cafeMedio;
    final borde = esOscuro ? AppColors.bordeDark : AppColors.borde;

    final textoBase = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: textoPrincipal,
      displayColor: textoPrincipal,
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: fondo,
      canvasColor: fondo,
      primaryColor: AppColors.terracota,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.terracota,
        onPrimary: AppColors.crema,
        secondary: AppColors.oliva,
        onSecondary: AppColors.crema,
        surface: superficie,
        onSurface: textoPrincipal,
        error: AppColors.terracotaOscuro,
        onError: AppColors.crema,
      ),
      textTheme: textoBase,
      iconTheme: IconThemeData(color: textoPrincipal),
      dividerColor: borde,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: textoPrincipal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontStyle: FontStyle.italic,
          color: textoPrincipal,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracota,
          foregroundColor: AppColors.crema,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: superficie,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.terracota, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: textoSecundario,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
        hintStyle: GoogleFonts.inter(
          color: textoSecundario,
          fontSize: 13,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: fondo),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: fondo),
    );
  }

  /// Estilo para títulos serif itálica (gastronómico).
  static TextStyle titulo({
    double size = 22,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontStyle: FontStyle.italic,
      color: color ?? AppColors.cafeOscuro,
      fontWeight: weight,
    );
  }

  /// Estilo para etiquetas pequeñas con tracking.
  static TextStyle etiqueta({
    double size = 10,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      letterSpacing: 1.2,
      color: color ?? AppColors.cafeMedio,
      fontWeight: FontWeight.w500,
    );
  }
}
