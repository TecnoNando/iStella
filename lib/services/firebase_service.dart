import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/socio.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';
import '../models/grupo_entrenamiento.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SOCIOS ====================

  // Obtener todos los socios activos
  Stream<List<Socio>> getSociosStream() {
    return _firestore
        .collection('socios')
        .where('activo', isEqualTo: true)
        // .orderBy('nombre') // Comentado temporalmente para evitar requerir índice
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Socio.fromFirestore(doc)).toList(),
        );
  }

  // Obtener socios por categoría
  Stream<List<Socio>> getSociosByCategoria(String categoria) {
    return _firestore
        .collection('socios')
        .where('activo', isEqualTo: true)
        .where('categoria', isEqualTo: categoria)
        // .orderBy('nombre') // Comentado temporalmente para evitar requerir índice
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Socio.fromFirestore(doc)).toList(),
        );
  }

  // Agregar nuevo socio
  Future<void> addSocio(Socio socio) async {
    await _firestore.collection('socios').add(socio.toFirestore());
  }

  // Actualizar socio existente
  Future<void> updateSocio(Socio socio) async {
    await _firestore
        .collection('socios')
        .doc(socio.id)
        .update(socio.toFirestore());
  }

  // Eliminar socio (soft delete - marcar como inactivo)
  Future<void> deleteSocio(String socioId) async {
    await _firestore.collection('socios').doc(socioId).update({
      'activo': false,
    });
  }

  // ==================== ASISTENCIAS ====================

  // Guardar registro de asistencia
  Future<String> saveAsistencia(Asistencia asistencia) async {
    DocumentReference docRef = await _firestore
        .collection('asistencias')
        .add(asistencia.toFirestore());
    return docRef.id;
  }

  // Obtener asistencias por rango de fechas
  Stream<List<Asistencia>> getAsistenciasByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('asistencias')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Asistencia.fromFirestore(doc))
              .toList(),
        );
  }

  // Obtener última asistencia
  Future<Asistencia?> getLastAsistencia() async {
    QuerySnapshot snapshot = await _firestore
        .collection('asistencias')
        .orderBy('fecha', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Asistencia.fromFirestore(snapshot.docs.first);
  }

  // ==================== CONFIGURACIÓN ====================

  // Obtener configuración de plantilla PDF
  Future<Map<String, dynamic>?> getPDFTemplate() async {
    DocumentSnapshot doc = await _firestore
        .collection('configuracion')
        .doc('pdf_template')
        .get();

    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  // Guardar configuración de plantilla PDF
  Future<void> savePDFTemplate(Map<String, dynamic> template) async {
    await _firestore.collection('configuracion').doc('pdf_template').set({
      'template': template,
    }, SetOptions(merge: true));
  }

  // ==================== USUARIOS (ENTRENADORES) ====================

  // Obtener todos los entrenadores
  Stream<List<Usuario>> getEntrenadoresStream() {
    return _firestore
        .collection('usuarios')
        .where('rol', isEqualTo: 'entrenador')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Usuario.fromFirestore(doc)).toList(),
        );
  }

  // Agregar nuevo entrenador
  Future<void> addEntrenador(Usuario entrenador) async {
    await _firestore.collection('usuarios').add(entrenador.toFirestore());
  }

  // Actualizar entrenador
  Future<void> updateEntrenador(Usuario entrenador) async {
    await _firestore
        .collection('usuarios')
        .doc(entrenador.id)
        .update(entrenador.toFirestore());
  }

  // Eliminar entrenador (soft delete)
  Future<void> deleteEntrenador(String entrenadorId) async {
    await _firestore.collection('usuarios').doc(entrenadorId).update({
      'activo': false,
    });
  }

  // ==================== GRUPOS DE ENTRENAMIENTO ====================

  // Obtener todos los grupos
  Stream<List<GrupoEntrenamiento>> getGruposStream() {
    return _firestore
        .collection('grupos')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GrupoEntrenamiento.fromFirestore(doc))
              .toList(),
        );
  }

  // Obtener grupos por día de la semana
  Stream<List<GrupoEntrenamiento>> getGruposByDia(String dia) {
    return _firestore
        .collection('grupos')
        .where('activo', isEqualTo: true)
        .where('diasSemana', arrayContains: dia.toLowerCase())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GrupoEntrenamiento.fromFirestore(doc))
              .toList(),
        );
  }

  // Agregar nuevo grupo
  Future<void> addGrupo(GrupoEntrenamiento grupo) async {
    await _firestore.collection('grupos').add(grupo.toFirestore());
  }

  // Actualizar grupo
  Future<void> updateGrupo(GrupoEntrenamiento grupo) async {
    await _firestore
        .collection('grupos')
        .doc(grupo.id)
        .update(grupo.toFirestore());
  }

  // Eliminar grupo (soft delete)
  Future<void> deleteGrupo(String grupoId) async {
    await _firestore.collection('grupos').doc(grupoId).update({
      'activo': false,
    });
  }

  // Asignar socio a grupo
  Future<void> assignSocioToGrupo(String socioId, String grupoId) async {
    await _firestore.collection('grupos').doc(grupoId).update({
      'sociosIds': FieldValue.arrayUnion([socioId]),
    });
  }

  // Remover socio de grupo
  Future<void> removeSocioFromGrupo(String socioId, String grupoId) async {
    await _firestore.collection('grupos').doc(grupoId).update({
      'sociosIds': FieldValue.arrayRemove([socioId]),
    });
  }

  // ==================== INICIALIZACIÓN ====================

  // Crear datos de ejemplo (solo para desarrollo)
  Future<void> createSampleData() async {
    // Verificar si ya existen socios
    QuerySnapshot existingSocios = await _firestore
        .collection('socios')
        .limit(1)
        .get();

    if (existingSocios.docs.isNotEmpty) {
      return; // Ya hay datos
    }

    // Crear socios de ejemplo
    List<Map<String, dynamic>> sampleSocios = [
      {
        'nombre': 'Juan Pérez',
        'categoria': 'senior',
        'activo': true,
        'fechaAlta': Timestamp.fromDate(DateTime(2025, 1, 15)),
      },
      {
        'nombre': 'María García',
        'categoria': 'senior',
        'activo': true,
        'fechaAlta': Timestamp.fromDate(DateTime(2025, 2, 10)),
      },
      {
        'nombre': 'Carlos López',
        'categoria': 'juvenil',
        'activo': true,
        'fechaAlta': Timestamp.fromDate(DateTime(2025, 3, 5)),
      },
      {
        'nombre': 'Ana Martínez',
        'categoria': 'juvenil',
        'activo': true,
        'fechaAlta': Timestamp.fromDate(DateTime(2025, 3, 20)),
      },
      {
        'nombre': 'Pedro Sánchez',
        'categoria': 'infantil',
        'activo': true,
        'fechaAlta': Timestamp.fromDate(DateTime(2025, 4, 1)),
      },
    ];

    for (var socio in sampleSocios) {
      await _firestore.collection('socios').add(socio);
    }

    // Crear configuración de plantilla PDF por defecto
    await _firestore.collection('configuracion').doc('pdf_template').set({
      'template': {
        'showLogo': true,
        'showDate': true,
        'showTime': true,
        'headerText': 'LISTA DE ASISTENCIA',
        'footerText': 'Club Deportivo Stella Maris',
        'customFields': [
          {'name': 'Entrenador', 'enabled': true},
          {'name': 'Categoría', 'enabled': true},
        ],
      },
    });

    print('✅ Datos de ejemplo creados correctamente');
  }
}
