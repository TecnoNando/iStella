import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grupo_entrenamiento.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Grupos')),
      body: StreamBuilder<List<GrupoEntrenamiento>>(
        stream: firebaseService.getGruposStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final grupos = snapshot.data!;

          if (grupos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay grupos creados',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu primer grupo',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              return _buildGrupoCard(context, grupo, firebaseService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGrupoDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Grupo'),
      ),
    );
  }

  Widget _buildGrupoCard(
    BuildContext context,
    GrupoEntrenamiento grupo,
    FirebaseService firebaseService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(grupo.categoria),
          child: Text(
            grupo.diasTexto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          grupo.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Horario: ${grupo.horario}'),
            Text('Categoría: ${_getCategoryName(grupo.categoria)}'),
            Text('Socios: ${grupo.sociosIds.length}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showGrupoDialog(context, grupo: grupo);
            } else if (value == 'delete') {
              _confirmDelete(context, grupo, firebaseService);
            }
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'infantil':
        return Colors.green;
      case 'juvenil':
        return Colors.orange;
      case 'senior':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getCategoryName(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'infantil':
        return 'Infantil';
      case 'juvenil':
        return 'Juvenil';
      case 'senior':
        return 'Senior';
      default:
        return categoria;
    }
  }

  void _showGrupoDialog(BuildContext context, {GrupoEntrenamiento? grupo}) {
    showDialog(
      context: context,
      builder: (context) => GrupoDialog(grupo: grupo),
    );
  }

  void _confirmDelete(
    BuildContext context,
    GrupoEntrenamiento grupo,
    FirebaseService firebaseService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: Text('¿Estás seguro de eliminar el grupo "${grupo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await firebaseService.deleteGrupo(grupo.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grupo eliminado')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class GrupoDialog extends StatefulWidget {
  final GrupoEntrenamiento? grupo;

  const GrupoDialog({super.key, this.grupo});

  @override
  State<GrupoDialog> createState() => _GrupoDialogState();
}

class _GrupoDialogState extends State<GrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _horarioController;
  String _categoria = 'infantil';
  final Map<String, bool> _diasSeleccionados = {
    'lunes': false,
    'martes': false,
    'miercoles': false,
    'jueves': false,
    'viernes': false,
  };

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.grupo?.nombre ?? '');
    _horarioController = TextEditingController(
      text: widget.grupo?.horario ?? '',
    );
    _categoria = widget.grupo?.categoria ?? 'infantil';

    if (widget.grupo != null) {
      for (var dia in widget.grupo!.diasSemana) {
        _diasSeleccionados[dia.toLowerCase()] = true;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _horarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.grupo == null ? 'Nuevo Grupo' : 'Editar Grupo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  hintText: 'Ej: Infantil - Lunes y Miércoles',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'infantil', child: Text('Infantil')),
                  DropdownMenuItem(value: 'juvenil', child: Text('Juvenil')),
                  DropdownMenuItem(value: 'senior', child: Text('Senior')),
                ],
                onChanged: (value) {
                  setState(() => _categoria = value!);
                },
              ),
              const SizedBox(height: 16),

              // Días de la semana
              const Text(
                'Días de entrenamiento:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _diasSeleccionados.keys.map((dia) {
                  return FilterChip(
                    label: Text(_getDiaLabel(dia)),
                    selected: _diasSeleccionados[dia]!,
                    onSelected: (selected) {
                      setState(() {
                        _diasSeleccionados[dia] = selected;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Horario
              TextFormField(
                controller: _horarioController,
                decoration: const InputDecoration(
                  labelText: 'Horario',
                  hintText: 'Ej: 17:00 - 18:30',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el horario';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveGrupo,
          child: Text(widget.grupo == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  String _getDiaLabel(String dia) {
    switch (dia) {
      case 'lunes':
        return 'Lunes';
      case 'martes':
        return 'Martes';
      case 'miercoles':
        return 'Miércoles';
      case 'jueves':
        return 'Jueves';
      case 'viernes':
        return 'Viernes';
      default:
        return dia;
    }
  }

  Future<void> _saveGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    final diasSeleccionados = _diasSeleccionados.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día')),
      );
      return;
    }

    try {
      final firebaseService = context.read<FirebaseService>();

      final grupo = GrupoEntrenamiento(
        id: widget.grupo?.id ?? '',
        nombre: _nombreController.text.trim(),
        categoria: _categoria,
        diasSemana: diasSeleccionados,
        horario: _horarioController.text.trim(),
        sociosIds: widget.grupo?.sociosIds ?? [],
        fechaCreacion: widget.grupo?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.grupo == null) {
        await firebaseService.addGrupo(grupo);
      } else {
        await firebaseService.updateGrupo(grupo);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.grupo == null
                  ? 'Grupo creado correctamente'
                  : 'Grupo actualizado correctamente',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}
