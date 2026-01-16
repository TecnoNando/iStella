import 'package:cloud_firestore/cloud_firestore.dart';

class Socio {
  final String id;
  final String nombre;
  final String categoria; // infantil, juvenil, senior
  final bool activo;
  final DateTime fechaAlta;

  Socio({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.activo = true,
    required this.fechaAlta,
  });

  // Convertir de Firestore a objeto Socio
  factory Socio.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Socio(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? 'senior',
      activo: data['activo'] ?? true,
      fechaAlta: (data['fechaAlta'] as Timestamp).toDate(),
    );
  }

  // Convertir de objeto Socio a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'activo': activo,
      'fechaAlta': Timestamp.fromDate(fechaAlta),
    };
  }

  // Crear copia con modificaciones
  Socio copyWith({
    String? id,
    String? nombre,
    String? categoria,
    bool? activo,
    DateTime? fechaAlta,
  }) {
    return Socio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      activo: activo ?? this.activo,
      fechaAlta: fechaAlta ?? this.fechaAlta,
    );
  }
}
