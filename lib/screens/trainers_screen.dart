import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../models/grupo_entrenamiento.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/password_hasher.dart';
import 'dart:math';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Entrenadores')),
      body: StreamBuilder<List<Usuario>>(
        stream: firebaseService.getEntrenadoresStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entrenadores = snapshot.data!;

          if (entrenadores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay entrenadores creados',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea el primer entrenador',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entrenadores.length,
            itemBuilder: (context, index) {
              final entrenador = entrenadores[index];
              return _buildEntrenadorCard(context, entrenador, firebaseService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntrenadorDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Entrenador'),
      ),
    );
  }

  Widget _buildEntrenadorCard(
    BuildContext context,
    Usuario entrenador,
    FirebaseService firebaseService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            entrenador.nombre[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entrenador.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Usuario: ${entrenador.usuario}'),
            Text('Grupos asignados: ${entrenador.gruposAsignados.length}'),
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
              _showEntrenadorDialog(context, entrenador: entrenador);
            } else if (value == 'delete') {
              _confirmDelete(context, entrenador, firebaseService);
            }
          },
        ),
      ),
    );
  }

  void _showEntrenadorDialog(BuildContext context, {Usuario? entrenador}) {
    showDialog(
      context: context,
      builder: (context) => EntrenadorDialog(entrenador: entrenador),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Usuario entrenador,
    FirebaseService firebaseService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Entrenador'),
        content: Text('¿Estás seguro de eliminar a "${entrenador.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await firebaseService.deleteEntrenador(entrenador.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Entrenador eliminado')),
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

class EntrenadorDialog extends StatefulWidget {
  final Usuario? entrenador;

  const EntrenadorDialog({super.key, this.entrenador});

  @override
  State<EntrenadorDialog> createState() => _EntrenadorDialogState();
}

class _EntrenadorDialogState extends State<EntrenadorDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _apellidosController;
  late TextEditingController _usuarioController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _dniController;
  late TextEditingController _cargoController;

  DateTime? _fechaNacimiento;
  String? _fotoUrl;
  List<String> _gruposAsignados = [];
  List<GrupoEntrenamiento> _gruposDisponibles = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.entrenador?.nombre ?? '',
    );
    _apellidosController = TextEditingController(
      text: widget.entrenador?.apellidos ?? '',
    );
    _usuarioController = TextEditingController(
      text: widget.entrenador?.usuario ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.entrenador?.password ?? '',
    );
    _emailController = TextEditingController(
      text: widget.entrenador?.email ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.entrenador?.telefono ?? '',
    );
    _dniController = TextEditingController(text: widget.entrenador?.dni ?? '');
    _cargoController = TextEditingController(
      text: widget.entrenador?.cargo ?? 'Entrenador',
    );
    _fechaNacimiento = widget.entrenador?.fechaNacimiento;
    _fotoUrl = widget.entrenador?.fotoUrl;
    _gruposAsignados = List.from(widget.entrenador?.gruposAsignados ?? []);
    _loadGrupos();
  }

  Future<void> _loadGrupos() async {
    final firebaseService = context.read<FirebaseService>();
    final grupos = await firebaseService.getGruposStream().first;
    setState(() {
      _gruposDisponibles = grupos;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.entrenador == null ? 'Nuevo Entrenador' : 'Editar Entrenador',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Center(
                child: ProfilePhotoWidget(
                  usuario: widget.entrenador,
                  editable: true,
                  size: 120,
                  onPhotoUploaded: (url) {
                    setState(() {
                      _fotoUrl = url;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Apellidos
              TextFormField(
                controller: _apellidosController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa los apellidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+34 600 000 000',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // DNI
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI/NIE',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                  hintText: '12345678A',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaNacimiento ?? DateTime(1990),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaNacimiento = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fechaNacimiento != null
                        ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _fechaNacimiento != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cargo
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                  hintText: 'Entrenador, Coordinador...',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Usuario
              TextFormField(
                controller: _usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario *',
                  hintText: 'nombre.apellido',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                enabled: widget.entrenador == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Generar contraseña',
                    onPressed: _generatePassword,
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (widget.entrenador == null &&
                      (value == null || value.isEmpty)) {
                    return 'Ingresa una contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Grupos asignados:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_gruposDisponibles.isEmpty)
                const Text(
                  'No hay grupos disponibles. Crea grupos primero.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: _gruposDisponibles.map((grupo) {
                    final isSelected = _gruposAsignados.contains(grupo.id);
                    return FilterChip(
                      label: Text(grupo.nombre),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _gruposAsignados.add(grupo.id);
                          } else {
                            _gruposAsignados.remove(grupo.id);
                          }
                        });
                      },
                    );
                  }).toList(),
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
          onPressed: _saveEntrenador,
          child: Text(widget.entrenador == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final password = List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    setState(() {
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Contraseña generada: $password')));
  }

  Future<void> _saveEntrenador() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final firebaseService = context.read<FirebaseService>();

      // Hash de la contraseña si se proporcionó una nueva
      String passwordToSave;
      if (_passwordController.text.isNotEmpty) {
        passwordToSave = PasswordHasher.hashPassword(_passwordController.text);
      } else {
        passwordToSave = widget.entrenador!.password;
      }

      final entrenador = Usuario(
        id: widget.entrenador?.id ?? '',
        usuario: _usuarioController.text.trim(),
        password: passwordToSave,
        rol: 'entrenador',
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        dni: _dniController.text.trim().isEmpty
            ? null
            : _dniController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        cargo: _cargoController.text.trim().isEmpty
            ? null
            : _cargoController.text.trim(),
        institucion: 'C.D. Stella Maris',
        fotoUrl: _fotoUrl ?? widget.entrenador?.fotoUrl,
        gruposAsignados: _gruposAsignados,
        fechaCreacion: widget.entrenador?.fechaCreacion ?? DateTime.now(),
      );

      if (widget.entrenador == null) {
        await firebaseService.addEntrenador(entrenador);
      } else {
        await firebaseService.updateEntrenador(entrenador);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entrenador == null
                  ? 'Entrenador creado correctamente'
                  : 'Entrenador actualizado correctamente',
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
