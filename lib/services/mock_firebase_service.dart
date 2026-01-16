import '../models/socio.dart';

class MockFirebaseService {
  // Datos de ejemplo sin Firebase
  final List<Socio> _socios = [
    Socio(
      id: '1',
      nombre: 'Juan Pérez',
      categoria: 'senior',
      fechaAlta: DateTime(2025, 1, 15),
    ),
    Socio(
      id: '2',
      nombre: 'María García',
      categoria: 'senior',
      fechaAlta: DateTime(2025, 2, 10),
    ),
    Socio(
      id: '3',
      nombre: 'Carlos López',
      categoria: 'juvenil',
      fechaAlta: DateTime(2025, 3, 5),
    ),
    Socio(
      id: '4',
      nombre: 'Ana Martínez',
      categoria: 'juvenil',
      fechaAlta: DateTime(2025, 3, 20),
    ),
    Socio(
      id: '5',
      nombre: 'Pedro Sánchez',
      categoria: 'infantil',
      fechaAlta: DateTime(2025, 4, 1),
    ),
  ];

  Stream<List<Socio>> getSociosStream() {
    return Stream.value(_socios);
  }

  Stream<List<Socio>> getSociosByCategoria(String categoria) {
    return Stream.value(
      _socios.where((s) => s.categoria == categoria).toList(),
    );
  }

  Future<void> addSocio(Socio socio) async {
    _socios.add(socio);
  }

  Future<void> updateSocio(Socio socio) async {
    final index = _socios.indexWhere((s) => s.id == socio.id);
    if (index != -1) {
      _socios[index] = socio;
    }
  }

  Future<void> deleteSocio(String socioId) async {
    _socios.removeWhere((s) => s.id == socioId);
  }

  Future<String> saveAsistencia(dynamic asistencia) async {
    return 'demo-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<bool> verifyAdminPin(String pin) async {
    return pin == '1234';
  }
}
