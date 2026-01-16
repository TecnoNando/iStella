import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;

  // Datos de autenticación
  final String usuario;
  final String password;
  final String rol; // 'admin' o 'entrenador'

  // Datos personales
  final String nombre;
  final String apellidos;
  final String? email;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? dni;

  // Datos profesionales
  final String? institucion;
  final String? cargo;
  final String? fotoUrl;

  // Datos de sistema
  final List<String> gruposAsignados;
  final bool activo;
  final DateTime fechaCreacion;

  Usuario({
    required this.id,
    required this.usuario,
    required this.password,
    required this.rol,
    required this.nombre,
    this.apellidos = '',
    this.email,
    this.telefono,
    this.fechaNacimiento,
    this.dni,
    this.institucion,
    this.cargo,
    this.fotoUrl,
    this.gruposAsignados = const [],
    this.activo = true,
    required this.fechaCreacion,
  });

  // Getters útiles
  String get nombreCompleto =>
      apellidos.isEmpty ? nombre : '$nombre $apellidos';

  String get iniciales {
    if (apellidos.isEmpty) {
      return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    }
    return '${nombre[0]}${apellidos[0]}'.toUpperCase();
  }

  bool get isAdmin => rol == 'admin';
  bool get isEntrenador => rol == 'entrenador';

  bool get tieneEmail => email != null && email!.isNotEmpty;
  bool get tieneFoto => fotoUrl != null && fotoUrl!.isNotEmpty;

  // Convertir desde Firestore
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      usuario: data['usuario'] ?? '',
      password: data['password'] ?? '',
      rol: data['rol'] ?? 'entrenador',
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      email: data['email'],
      telefono: data['telefono'],
      fechaNacimiento: data['fechaNacimiento'] != null
          ? (data['fechaNacimiento'] as Timestamp).toDate()
          : null,
      dni: data['dni'],
      institucion: data['institucion'],
      cargo: data['cargo'],
      fotoUrl: data['fotoUrl'],
      gruposAsignados: List<String>.from(data['gruposAsignados'] ?? []),
      activo: data['activo'] ?? true,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'usuario': usuario,
      'password': password,
      'rol': rol,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'fechaNacimiento': fechaNacimiento != null
          ? Timestamp.fromDate(fechaNacimiento!)
          : null,
      'dni': dni,
      'institucion': institucion,
      'cargo': cargo,
      'fotoUrl': fotoUrl,
      'gruposAsignados': gruposAsignados,
      'activo': activo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  // Método para copiar con cambios
  Usuario copyWith({
    String? id,
    String? usuario,
    String? password,
    String? rol,
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
    DateTime? fechaNacimiento,
    String? dni,
    String? institucion,
    String? cargo,
    String? fotoUrl,
    List<String>? gruposAsignados,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Usuario(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      password: password ?? this.password,
      rol: rol ?? this.rol,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      dni: dni ?? this.dni,
      institucion: institucion ?? this.institucion,
      cargo: cargo ?? this.cargo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      gruposAsignados: gruposAsignados ?? this.gruposAsignados,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
