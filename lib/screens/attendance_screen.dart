import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/socio.dart';
import '../models/asistencia.dart';
import '../models/grupo_entrenamiento.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';
import '../widgets/socio_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, bool> _attendance = {};
  bool _isGeneratingPDF = false;
  GrupoEntrenamiento? _selectedGrupo;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentDayOfWeek = '';

  @override
  void initState() {
    super.initState();
    _currentDayOfWeek = _getDayOfWeek(DateTime.now());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    return days[date.weekday - 1];
  }

  String _getDayName(String day) {
    const names = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
    };
    return names[day] ?? day;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasar Lista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Día actual: ${_getDayName(_currentDayOfWeek)}',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hoy es ${_getDayName(_currentDayOfWeek)}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de grupo
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: StreamBuilder<List<GrupoEntrenamiento>>(
              stream: currentUser.isAdmin
                  ? firebaseService.getGruposByDia(_currentDayOfWeek)
                  : firebaseService.getGruposStream().map(
                      (grupos) => grupos
                          .where(
                            (g) =>
                                currentUser.gruposAsignados.contains(g.id) &&
                                g.diasSemana.contains(_currentDayOfWeek),
                          )
                          .toList(),
                    ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final gruposHoy = snapshot.data!;

                if (gruposHoy.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: AppColors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No hay grupos programados para ${_getDayName(_currentDayOfWeek)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona un grupo:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GrupoEntrenamiento>(
                      initialValue: _selectedGrupo,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      hint: const Text('Selecciona un grupo'),
                      items: gruposHoy.map((grupo) {
                        return DropdownMenuItem(
                          value: grupo,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                grupo.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${grupo.horario} • ${grupo.sociosIds.length} socios',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (grupo) {
                        setState(() {
                          _selectedGrupo = grupo;
                          _attendance.clear();
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Búsqueda y contador
          if (_selectedGrupo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background,
              child: Column(
                children: [
                  // Barra de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar socio...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                  const SizedBox(height: 12),

                  // Contador y acciones rápidas
                  if (_attendance.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Presentes: ${_attendance.values.where((v) => v).length} / ${_attendance.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _markAll,
                                icon: const Icon(Icons.check_box, size: 18),
                                label: const Text('Todos'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _unmarkAll,
                                icon: const Icon(
                                  Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                label: const Text('Ninguno'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Lista de socios del grupo
            Expanded(
              child: StreamBuilder<List<Socio>>(
                stream: firebaseService.getSociosStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar los socios',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filtrar socios del grupo seleccionado
                  var socios = snapshot.data!
                      .where((s) => _selectedGrupo!.sociosIds.contains(s.id))
                      .toList();

                  // Filtrar por búsqueda
                  if (_searchQuery.isNotEmpty) {
                    socios = socios
                        .where(
                          (s) => s.nombre.toLowerCase().contains(_searchQuery),
                        )
                        .toList();
                  }

                  if (socios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.people_outline,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron socios'
                                : 'No hay socios en este grupo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: socios.length,
                    itemBuilder: (context, index) {
                      final socio = socios[index];
                      final isPresent = _attendance[socio.id] ?? false;

                      return SocioCard(
                        socio: socio,
                        isPresent: isPresent,
                        onChanged: (value) {
                          setState(() {
                            _attendance[socio.id] = value ?? false;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Selecciona un grupo para comenzar',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _attendance.isNotEmpty && _selectedGrupo != null
          ? FloatingActionButton.extended(
              onPressed: _isGeneratingPDF
                  ? null
                  : () => _generatePDF(currentUser.nombre),
              icon: _isGeneratingPDF
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isGeneratingPDF ? 'Guardando...' : 'Guardar'),
            )
          : null,
    );
  }

  void _markAll() {
    setState(() {
      for (var key in _attendance.keys) {
        _attendance[key] = true;
      }
    });
  }

  void _unmarkAll() {
    setState(() {
      for (var key in _attendance.keys) {
        _attendance[key] = false;
      }
    });
  }

  Future<void> _generatePDF(String trainerName) async {
    setState(() => _isGeneratingPDF = true);

    try {
      final firebaseService = context.read<FirebaseService>();

      // Obtener todos los socios del grupo
      final sociosSnapshot = await firebaseService.getSociosStream().first;
      final sociosDelGrupo = sociosSnapshot
          .where((s) => _selectedGrupo!.sociosIds.contains(s.id))
          .toList();

      // Crear lista de asistencia
      List<SocioAsistencia> sociosAsistencia = sociosDelGrupo.map((socio) {
        return SocioAsistencia(
          socioId: socio.id,
          nombre: socio.nombre,
          presente: _attendance[socio.id] ?? false,
        );
      }).toList();

      // Crear objeto Asistencia
      final asistencia = Asistencia(
        id: '',
        fecha: DateTime.now(),
        entrenador: trainerName,
        grupoId: _selectedGrupo!.id,
        socios: sociosAsistencia,
      );

      // Guardar en Firebase
      final asistenciaId = await firebaseService.saveAsistencia(asistencia);

      // Generar PDF
      final pdfService = PDFService();
      await pdfService.generateAndSharePDF(
        asistencia.copyWith(id: asistenciaId),
        context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asistencia guardada para ${_selectedGrupo!.nombre}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Limpiar selección
        setState(() {
          _attendance.clear();
          _selectedGrupo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }
}

extension on Asistencia {
  Asistencia copyWith({String? id}) {
    return Asistencia(
      id: id ?? this.id,
      fecha: fecha,
      entrenador: entrenador,
      grupoId: grupoId,
      socios: socios,
    );
  }
}
