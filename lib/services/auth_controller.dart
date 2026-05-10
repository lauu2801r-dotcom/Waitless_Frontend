import 'package:flutter/widgets.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repositorio;
  Usuario? _usuario;
  bool _cargando = true;

  AuthController(this.repositorio) {
    _inicializar();
  }

  Usuario? get usuario => _usuario;
  bool get estaAutenticado => _usuario != null;
  bool get cargando => _cargando;
  bool get esAdministrador => _usuario?.esAdministrador ?? false;
  bool get esCliente => _usuario?.esCliente ?? false;

  Future<void> _inicializar() async {
    _usuario = await repositorio.usuarioActual();
    _cargando = false;
    notifyListeners();
  }

  Future<AuthResultado<String>> registrarCliente({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) {
    return repositorio.registrarCliente(
      nombreCompleto: nombreCompleto,
      correo: correo,
      password: password,
    );
  }

  Future<AuthResultado<String>> registrarAdministrador({
    required String nombreCompleto,
    required String correo,
    required String password,
    required String nombreRestaurante,
    required String codigoNegocio,
  }) {
    return repositorio.registrarAdministrador(
      nombreCompleto: nombreCompleto,
      correo: correo,
      password: password,
      nombreRestaurante: nombreRestaurante,
      codigoNegocio: codigoNegocio,
    );
  }

  Future<AuthResultado<Usuario>> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    final r = await repositorio.verificarCodigo(correo: correo, codigo: codigo);
    if (r is AuthExito<Usuario>) {
      _usuario = r.datos;
      notifyListeners();
    }
    return r;
  }

  Future<AuthResultado<String>> reenviarCodigo(String correo) {
    return repositorio.reenviarCodigo(correo);
  }

  Future<AuthResultado<Usuario>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final r =
        await repositorio.iniciarSesion(correo: correo, password: password);
    if (r is AuthExito<Usuario>) {
      _usuario = r.datos;
      notifyListeners();
    }
    return r;
  }

  Future<void> cerrarSesion() async {
    await repositorio.cerrarSesion();
    _usuario = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controlador,
    required super.child,
  }) : super(notifier: controlador);

  /// Obtiene el [AuthController] del contexto. Lanza un error si no se encuentra.
  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }

  /// Variante segura que devuelve null si no se encuentra el [AuthScope].
  /// Útil para widgets que pueden renderizarse antes de tener acceso.
  static AuthController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    return scope?.notifier;
  }
}
