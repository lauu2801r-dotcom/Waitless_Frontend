import '../models/pedido.dart';

/// Modelo simple para platos del menú.
class Plato {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String categoria;
  final int tiempoPreparacion;
  final bool destacado;
  final String emoji;

  const Plato({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.tiempoPreparacion,
    this.destacado = false,
    required this.emoji,
  });
}

/// Modelo para reservas/mesas.
class Mesa {
  final int numero;
  final int capacidad;
  final String zona;
  final EstadoMesa estado;
  final String? clienteActual;
  final int? minutosOcupada;

  const Mesa({
    required this.numero,
    required this.capacidad,
    required this.zona,
    required this.estado,
    this.clienteActual,
    this.minutosOcupada,
  });
}

enum EstadoMesa { disponible, ocupada, reservada, limpieza }

/// Reseñas de clientes
class Resena {
  final String cliente;
  final String inicial;
  final int estrellas;
  final String comentario;
  final String fecha;

  const Resena({
    required this.cliente,
    required this.inicial,
    required this.estrellas,
    required this.comentario,
    required this.fecha,
  });
}

class PedidosMock {
  /// Pedidos del restaurante "rest_001" (El Buen Sabor).
  static List<Pedido> get pedidosRestaurante001 => const [
        Pedido(
          numero: '1204',
          plato: 'Pasta al pesto',
          detalle: 'Doble porción de queso',
          precio: 28500,
          estado: EstadoPedido.emplatado,
          horaPedido: '14:32',
          minutosRestantes: 4,
          restauranteId: 'rest_001',
          mesa: 'Mesa 12',
          clienteNombre: 'Laura G.',
        ),
        Pedido(
          numero: '1205',
          plato: 'Limonada de coco',
          detalle: 'Sin azúcar añadida',
          precio: 9500,
          estado: EstadoPedido.enCamino,
          horaPedido: '14:36',
          minutosRestantes: 1,
          restauranteId: 'rest_001',
          mesa: 'Mesa 12',
          clienteNombre: 'Laura G.',
        ),
        Pedido(
          numero: '1206',
          plato: 'Risotto de mariscos',
          detalle: 'Punto medio',
          precio: 42000,
          estado: EstadoPedido.enCocina,
          horaPedido: '14:38',
          minutosRestantes: 12,
          restauranteId: 'rest_001',
          mesa: 'Mesa 5',
          clienteNombre: 'Carlos M.',
        ),
        Pedido(
          numero: '1207',
          plato: 'Ensalada César',
          detalle: 'Sin crutones',
          precio: 22000,
          estado: EstadoPedido.recibido,
          horaPedido: '14:40',
          minutosRestantes: 18,
          restauranteId: 'rest_001',
          mesa: 'Mesa 8',
          clienteNombre: 'Ana P.',
        ),
        Pedido(
          numero: '1208',
          plato: 'Pollo a la plancha',
          detalle: 'Con vegetales asados',
          precio: 35000,
          estado: EstadoPedido.enCocina,
          horaPedido: '14:42',
          minutosRestantes: 8,
          restauranteId: 'rest_001',
          mesa: 'Mesa 3',
          clienteNombre: 'Pedro S.',
        ),
        Pedido(
          numero: '1198',
          plato: 'Bruschettas de tomate',
          detalle: 'Albahaca fresca',
          precio: 18000,
          estado: EstadoPedido.entregado,
          horaPedido: '14:05',
          minutosRestantes: 0,
          restauranteId: 'rest_001',
          mesa: 'Mesa 12',
          clienteNombre: 'Laura G.',
        ),
        Pedido(
          numero: '1192',
          plato: 'Risotto de hongos',
          detalle: 'Con trufa',
          precio: 32000,
          estado: EstadoPedido.entregado,
          horaPedido: '13:40',
          minutosRestantes: 0,
          restauranteId: 'rest_001',
          mesa: 'Mesa 3',
          clienteNombre: 'Pedro S.',
        ),
        Pedido(
          numero: '1185',
          plato: 'Salmón a las finas hierbas',
          detalle: 'Con quinoa',
          precio: 38500,
          estado: EstadoPedido.entregado,
          horaPedido: '13:15',
          minutosRestantes: 0,
          restauranteId: 'rest_001',
          mesa: 'Mesa 7',
          clienteNombre: 'María L.',
        ),
        Pedido(
          numero: '1180',
          plato: 'Tiramisú casero',
          detalle: '',
          precio: 14000,
          estado: EstadoPedido.entregado,
          horaPedido: '12:55',
          minutosRestantes: 0,
          restauranteId: 'rest_001',
          mesa: 'Mesa 7',
          clienteNombre: 'María L.',
        ),
      ];

  /// Devuelve los pedidos asociados a un restaurante específico.
  static List<Pedido> porRestaurante(String? restauranteId) {
    if (restauranteId == null) return [];
    return pedidosRestaurante001
        .where((p) => p.restauranteId == restauranteId)
        .toList();
  }

  /// Pedidos del cliente actual (los que están a su nombre / mesa).
  static List<Pedido> pedidosCliente() {
    return pedidosRestaurante001.where((p) => p.mesa == 'Mesa 12').toList();
  }

  /// Pedidos del cliente personalizados con su nombre, para que la UI
  /// se sienta poblada para cualquier usuario recién registrado.
  static List<Pedido> pedidosClientePersonalizados(String? primerNombre) {
    final base = pedidosCliente();
    if (primerNombre == null || primerNombre.trim().isEmpty) return base;
    final inicial = primerNombre.trim()[0].toUpperCase();
    final resto = primerNombre.trim().length > 1
        ? primerNombre.trim().substring(1).toLowerCase()
        : '';
    final nombre = '$inicial$resto';
    return base
        .map((p) => Pedido(
              numero: p.numero,
              plato: p.plato,
              detalle: p.detalle,
              precio: p.precio,
              estado: p.estado,
              horaPedido: p.horaPedido,
              minutosRestantes: p.minutosRestantes,
              restauranteId: p.restauranteId,
              mesa: p.mesa,
              clienteNombre: nombre,
            ))
        .toList();
  }
}

class MenuMock {
  static const List<Plato> platos = [
    // Entradas
    Plato(
      id: 'p001',
      nombre: 'Bruschettas de tomate',
      descripcion: 'Pan tostado con tomate fresco, albahaca y aceite de oliva',
      precio: 18000,
      categoria: 'Entradas',
      tiempoPreparacion: 8,
      emoji: '🍞',
    ),
    Plato(
      id: 'p002',
      nombre: 'Carpaccio de res',
      descripcion: 'Láminas finas de res con rúcula y parmesano',
      precio: 26000,
      categoria: 'Entradas',
      tiempoPreparacion: 10,
      emoji: '🥩',
    ),
    Plato(
      id: 'p003',
      nombre: 'Ensalada César',
      descripcion: 'Lechuga romana, crutones, parmesano y aderezo casero',
      precio: 22000,
      categoria: 'Entradas',
      tiempoPreparacion: 7,
      emoji: '🥗',
    ),

    // Principales
    Plato(
      id: 'p004',
      nombre: 'Risotto de hongos',
      descripcion: 'Cremoso risotto con hongos portobello y trufa',
      precio: 32000,
      categoria: 'Principales',
      tiempoPreparacion: 18,
      destacado: true,
      emoji: '🍚',
    ),
    Plato(
      id: 'p005',
      nombre: 'Pasta al pesto',
      descripcion: 'Pasta fresca con pesto genovés casero y queso parmesano',
      precio: 28500,
      categoria: 'Principales',
      tiempoPreparacion: 15,
      emoji: '🍝',
    ),
    Plato(
      id: 'p006',
      nombre: 'Salmón a las finas hierbas',
      descripcion: 'Filete de salmón con quinoa y vegetales asados',
      precio: 38500,
      categoria: 'Principales',
      tiempoPreparacion: 18,
      destacado: true,
      emoji: '🐟',
    ),
    Plato(
      id: 'p007',
      nombre: 'Risotto de mariscos',
      descripcion: 'Risotto con camarones, calamar y mejillones',
      precio: 42000,
      categoria: 'Principales',
      tiempoPreparacion: 20,
      emoji: '🦐',
    ),
    Plato(
      id: 'p008',
      nombre: 'Pollo a la plancha',
      descripcion: 'Pechuga de pollo marinada con vegetales de temporada',
      precio: 35000,
      categoria: 'Principales',
      tiempoPreparacion: 15,
      emoji: '🍗',
    ),

    // Postres
    Plato(
      id: 'p009',
      nombre: 'Tiramisú casero',
      descripcion: 'Receta tradicional italiana con café espresso',
      precio: 14000,
      categoria: 'Postres',
      tiempoPreparacion: 5,
      destacado: true,
      emoji: '🍰',
    ),
    Plato(
      id: 'p010',
      nombre: 'Cheesecake de frutos rojos',
      descripcion: 'Cremoso cheesecake con coulis de frutos rojos',
      precio: 13500,
      categoria: 'Postres',
      tiempoPreparacion: 5,
      emoji: '🍰',
    ),

    // Bebidas
    Plato(
      id: 'p011',
      nombre: 'Limonada de coco',
      descripcion: 'Refrescante limonada con leche de coco',
      precio: 9500,
      categoria: 'Bebidas',
      tiempoPreparacion: 3,
      emoji: '🥥',
    ),
    Plato(
      id: 'p012',
      nombre: 'Vino tinto reserva',
      descripcion: 'Copa de vino tinto reserva de la casa',
      precio: 18000,
      categoria: 'Bebidas',
      tiempoPreparacion: 2,
      emoji: '🍷',
    ),
  ];

  static List<Plato> get destacados =>
      platos.where((p) => p.destacado).toList();

  static List<String> get categorias =>
      platos.map((p) => p.categoria).toSet().toList();

  static List<Plato> porCategoria(String categoria) =>
      platos.where((p) => p.categoria == categoria).toList();
}

class MesasMock {
  static const List<Mesa> mesas = [
    Mesa(
      numero: 1,
      capacidad: 2,
      zona: 'Terraza',
      estado: EstadoMesa.ocupada,
      clienteActual: 'Familia López',
      minutosOcupada: 45,
    ),
    Mesa(
      numero: 2,
      capacidad: 4,
      zona: 'Salón principal',
      estado: EstadoMesa.disponible,
    ),
    Mesa(
      numero: 3,
      capacidad: 4,
      zona: 'Salón principal',
      estado: EstadoMesa.ocupada,
      clienteActual: 'Pedro S.',
      minutosOcupada: 25,
    ),
    Mesa(
      numero: 5,
      capacidad: 6,
      zona: 'Salón principal',
      estado: EstadoMesa.ocupada,
      clienteActual: 'Carlos M.',
      minutosOcupada: 15,
    ),
    Mesa(
      numero: 7,
      capacidad: 2,
      zona: 'Terraza',
      estado: EstadoMesa.limpieza,
    ),
    Mesa(
      numero: 8,
      capacidad: 4,
      zona: 'Salón privado',
      estado: EstadoMesa.ocupada,
      clienteActual: 'Ana P.',
      minutosOcupada: 8,
    ),
    Mesa(
      numero: 10,
      capacidad: 8,
      zona: 'Salón privado',
      estado: EstadoMesa.reservada,
      clienteActual: 'Cumpleaños 8pm',
    ),
    Mesa(
      numero: 12,
      capacidad: 2,
      zona: 'Terraza',
      estado: EstadoMesa.ocupada,
      clienteActual: 'Laura G.',
      minutosOcupada: 72,
    ),
    Mesa(
      numero: 14,
      capacidad: 4,
      zona: 'Salón principal',
      estado: EstadoMesa.disponible,
    ),
  ];
}

class ResenasMock {
  static const List<Resena> resenas = [
    Resena(
      cliente: 'Laura González',
      inicial: 'L',
      estrellas: 5,
      comentario:
          'Excelente atención y la comida estuvo deliciosa. El risotto es espectacular!',
      fecha: 'Hace 2 días',
    ),
    Resena(
      cliente: 'Carlos Martínez',
      inicial: 'C',
      estrellas: 5,
      comentario: 'Mi lugar favorito en Bogotá. Siempre vuelvo por el ambiente.',
      fecha: 'Hace 4 días',
    ),
    Resena(
      cliente: 'Ana Patricia',
      inicial: 'A',
      estrellas: 4,
      comentario: 'Muy buena experiencia. La predicción de afluencia me ayudó mucho.',
      fecha: 'Hace 1 semana',
    ),
  ];
}
