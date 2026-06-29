import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_controller.dart';
import 'services/app_settings.dart';
import 'services/api_auth_repository.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/admin/admin_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.crema,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final repo = ApiAuthRepository();
  final auth = AuthController(repo);
  final settings = AppSettings();

  runApp(WaitLessApp(auth: auth, settings: settings));
}

class WaitLessApp extends StatelessWidget {
  final AuthController auth;
  final AppSettings settings;
  const WaitLessApp({
    super.key,
    required this.auth,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: AuthScope(
        controlador: auth,
        child: AnimatedBuilder(
          animation: settings,
          builder: (_, __) => MaterialApp(
            title: 'WaitLess',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
              Locale('pt'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _ArranqueInicial(),
          ),
        ),
      ),
    );
  }
}

class _ArranqueInicial extends StatelessWidget {
  const _ArranqueInicial();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    // 🔍 DEBUG: Imprime info de la sesión
    debugPrint('═══════════════════════════════════');
    debugPrint('🔍 DEBUG SESIÓN:');
    debugPrint('🔍 Cargando: ${auth.cargando}');
    debugPrint('🔍 Autenticado: ${auth.estaAutenticado}');
    debugPrint('🔍 Usuario: ${auth.usuario?.correo}');
    debugPrint('🔍 Rol: ${auth.usuario?.rol}');
    debugPrint('🔍 esAdministrador: ${auth.esAdministrador}');
    debugPrint('🔍 restauranteId: ${auth.usuario?.restauranteId}');
    debugPrint('🔍 nombreRestaurante: ${auth.usuario?.nombreRestaurante}');
    debugPrint('═══════════════════════════════════');

    if (auth.cargando) {
      return Scaffold(
        backgroundColor: AppColors.crema,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.terracota,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'W',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontStyle: FontStyle.italic,
                      color: AppColors.crema,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.terracota,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.estaAutenticado) {
      debugPrint('❌ NO AUTENTICADO → Mostrando LoginScreen');
      return const LoginScreen();
    }

    // Detectar rol y dirigir a la shell correspondiente.
    if (auth.esAdministrador) {
      debugPrint('✅ ES ADMIN → Mostrando AdminShell');
      return const AdminShell();
    }

    debugPrint('👤 ES CLIENTE → Mostrando MainShell');
    return const MainShell();
  }
}