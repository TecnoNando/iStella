import 'package:cloud_firestore/cloud_firestore.dart';

class SocioAsistencia {
  final String socioId;
  final String nombre;
  final bool presente;

  SocioAsistencia({
    required this.socioId,
    required this.nombre,
    required this.presente,
  });

  Map<String, dynamic> toMap() {
    return {'socioId': socioId, 'nombre': nombre, 'presente': presente};
  }

  factory SocioAsistencia.fromMap(Map<String, dynamic> map) {
    return SocioAsistencia(
      socioId: map['socioId'] ?? '',
      nombre: map['nombre'] ?? '',
      presente: map['presente'] ?? false,
    );
  }
}

class Asistencia {
  final String id;
  final DateTime fecha;
  final String entrenador;
  final String? grupoId; // ID del grupo al que pertenece esta asistencia
  final List<SocioAsistencia> socios;

  Asistencia({
    required this.id,
    required this.fecha,
    required this.entrenador,
    this.grupoId,
    required this.socios,
  });

  // Convertir de Firestore a objeto Asistencia
  factory Asistencia.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<SocioAsistencia> sociosList = [];

    if (data['socios'] != null) {
      sociosList = (data['socios'] as List)
          .map(
            (socio) => SocioAsistencia.fromMap(socio as Map<String, dynamic>),
          )
          .toList();
    }

    return Asistencia(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      entrenador: data['entrenador'] ?? '',
      grupoId: data['grupoId'],
      socios: sociosList,
    );
  }

  // Convertir de objeto Asistencia a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'entrenador': entrenador,
      'grupoId': grupoId,
      'socios': socios.map((s) => s.toMap()).toList(),
    };
  }

  // Obtener número de presentes
  int get totalPresentes => socios.where((s) => s.presente).length;

  // Obtener número de ausentes
  int get totalAusentes => socios.where((s) => !s.presente).length;
}
