import 'package:cloud_firestore/cloud_firestore.dart';

class GrupoEntrenamiento {
  final String id;
  final String nombre; // ej: "Infantil - Lunes y Miércoles"
  final String categoria; // infantil, juvenil, senior
  final List<String>
  diasSemana; // ['lunes', 'martes', 'miercoles', 'jueves', 'viernes']
  final String horario; // ej: "17:00 - 18:30"
  final List<String> sociosIds; // IDs de socios asignados a este grupo
  final bool activo;
  final DateTime fechaCreacion;

  GrupoEntrenamiento({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.diasSemana,
    required this.horario,
    this.sociosIds = const [],
    this.activo = true,
    required this.fechaCreacion,
  });

  // Convertir desde Firestore
  factory GrupoEntrenamiento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GrupoEntrenamiento(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      diasSemana: List<String>.from(data['diasSemana'] ?? []),
      horario: data['horario'] ?? '',
      sociosIds: List<String>.from(data['sociosIds'] ?? []),
      activo: data['activo'] ?? true,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'diasSemana': diasSemana,
      'horario': horario,
      'sociosIds': sociosIds,
      'activo': activo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  // Helper para mostrar días en español
  String get diasTexto {
    return diasSemana
        .map((dia) {
          switch (dia.toLowerCase()) {
            case 'lunes':
              return 'L';
            case 'martes':
              return 'M';
            case 'miercoles':
              return 'X';
            case 'jueves':
              return 'J';
            case 'viernes':
              return 'V';
            default:
              return '';
          }
        })
        .join(', ');
  }
}
