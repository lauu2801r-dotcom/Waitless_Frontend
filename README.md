# WaitLess

App Flutter para gestión de restaurantes con dos roles: **cliente** (reservar mesa, hacer pedidos, ver predicciones de afluencia) y **administrador** (ver dashboard, gestionar pedidos, métricas del negocio).

---

## Cómo correr la app paso a paso

### 1. Instalar Flutter

Si todavía no tienes Flutter en tu computador, descárgalo aquí:

> https://docs.flutter.dev/get-started/install

Sigue la guía oficial según tu sistema operativo (Windows / macOS / Linux). Necesitas **Flutter 3.4.0 o superior**.

Para verificar que quedó bien instalado, en la terminal:

```bash
flutter --version
flutter doctor
```

`flutter doctor` te dirá si te falta algo. Lo importante para correr en web es que tenga **Chrome** habilitado.

### 2. Descomprimir el proyecto

Descomprime el zip en cualquier carpeta. Te quedará una carpeta llamada `WaitLess 2 backup` (puedes renombrarla como quieras).

### 3. Abrir la terminal en esa carpeta

```bash
cd "ruta/donde/descomprimiste/WaitLess 2 backup"
```

### 4. Instalar dependencias

```bash
flutter pub get
```

Esto descarga las librerías que usa el proyecto (`google_fonts`, `fl_chart`, `shared_preferences`, `flutter_localizations`).

### 5. Correr en el navegador

```bash
flutter run -d chrome
```

Se abrirá Chrome automáticamente con la app en `http://localhost:port`. La primera compilación tarda 1-2 minutos; después es más rápida.

> Si no tienes Chrome, también puedes correrla en un emulador Android/iOS con `flutter run`.

---

## Cómo probar la app

### Flujo cliente (usuario nuevo)

1. En la pantalla de Login, toca **"Regístrate"**
2. Llena el formulario (cualquier correo y contraseña con mayúscula y número, ej. `Test1234`)
3. En la pantalla de verificación, **el código aparece en la cajita verde** (modo demo). Cópialo.
4. Entras a la app **sin datos** (porque acabas de registrarte): pedidos vacíos, perfil sin estadísticas, predicción sin gráficas
5. Ve a **Perfil** → **Cerrar sesión**
6. Ahora **inicia sesión** con el mismo correo → ahora sí ves todos los datos: pedidos, estadísticas, gráficas, MIEMBRO Oro, etc.

### Flujo administrador

1. Logout y toca "Regístrate"
2. Abajo, toca **"Registra tu restaurante"**
3. Llena el formulario. **El código de negocio es: `RESTO2026`**
4. Verifica con el código verde
5. Igual que el cliente: **al registrarte** ves dashboard vacío; **al iniciar sesión** ves los datos completos

### Personalización (Perfil → Preferencias)

- **Idioma**: Español / English / Português → cambia toda la app
- **Apariencia**: Claro / Oscuro / Sistema → tema oscuro real con fondos invertidos
- **Notificaciones**: 3 switches funcionales

### Botones funcionales clave

- **Inicio**: campana 🔔, búsqueda 🔍, banner 20% OFF, "Reservar mesa", "Pedido a domicilio", "Promos del día", platos destacados, "Ver todos"
- **Pedidos**: tarjeta de cada pedido (abre detalle), "Llamar al mesero" con motivos
- **Perfil**: editar foto, agregar tarjeta, agregar dirección, FAQ del centro de ayuda
- **Admin Pedidos**: botón "Avanzar" cambia el estado del pedido en tiempo real (Recibido → En cocina → Emplatando → En camino → Entregado), menú 3 puntos: reasignar mesa / imprimir / cancelar

---

## Stack técnico

- **Flutter 3.4+** (web, móvil y escritorio)
- **shared_preferences** para persistencia local de usuarios y sesión
- **fl_chart** para gráficas de barras y línea
- **google_fonts** (Playfair Display + Inter)
- **flutter_localizations** para soporte i18n

## Estructura

```
lib/
├── main.dart
├── theme/app_theme.dart            # tema claro + tema oscuro
├── models/
│   ├── pedido.dart
│   └── usuario.dart
├── data/mock_data.dart              # datos de ejemplo
├── services/
│   ├── auth_controller.dart         # estado de auth
│   ├── auth_repository.dart
│   ├── local_auth_repository.dart   # persistencia con shared_preferences
│   └── app_settings.dart            # tema + idioma global
├── utils/
│   ├── validadores.dart
│   └── app_strings.dart             # traducciones es/en/pt
├── widgets/common_widgets.dart
└── screens/
    ├── login_screen.dart
    ├── registro_screen.dart
    ├── registro_admin_screen.dart
    ├── verificacion_screen.dart
    ├── main_shell.dart              # cliente
    ├── home_screen.dart
    ├── pedidos_screen.dart
    ├── detalle_pedido_screen.dart
    ├── prediccion_screen.dart
    ├── perfil_screen.dart
    └── admin/
        ├── admin_shell.dart
        ├── admin_dashboard_screen.dart
        ├── admin_pedidos_screen.dart
        ├── admin_prediccion_screen.dart
        └── admin_perfil_screen.dart
```

## Solución de problemas

- **"flutter: command not found"** → Flutter no está en el PATH. Sigue la guía oficial.
- **"No connected devices"** al correr `flutter run` → especifica `flutter run -d chrome`.
- **Compilación muy lenta la primera vez** → es normal. La segunda vez es mucho más rápido.
- **"Could not find a set of Noto fonts"** → solo es un warning, ignóralo.
- **Pantalla en blanco al cargar** → espera 5-10 segundos. Si sigue blanca, abre la consola del navegador (F12) para ver errores.
