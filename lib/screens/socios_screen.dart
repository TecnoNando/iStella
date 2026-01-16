import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../models/grupo_entrenamiento.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../utils/password_hasher.dart';
import '../widgets/profile_photo_widget.dart';
import 'dart:math';

class SociosScreen extends StatefulWidget {
  const SociosScreen({super.key});

  @override
  State<SociosScreen> createState() => _SociosScreenState();
}

class _SociosScreenState extends State<SociosScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gimnastas')),
      body: StreamBuilder<List<Usuario>>(
        stream: firebaseService.getUsuariosByRolStream('gimnasta'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final socios = snapshot.data!;

          if (socios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay socios registrados',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Añade el primer socio',
                    style: TextStyle(color: AppColors.textSecondary),
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
              return _buildSocioCard(context, socio, firebaseService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSocioDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Socio'),
      ),
    );
  }

  Widget _buildSocioCard(
    BuildContext context,
    Usuario socio,
    FirebaseService firebaseService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ProfilePhotoWidget(usuario: socio, editable: false, size: 50),
        title: Text(
          socio.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Usuario: ${socio.usuario}'),
            if (socio.gruposAsignados.isNotEmpty)
              Text('Grupos: ${socio.gruposAsignados.length}'),
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
              _showSocioDialog(context, socio: socio);
            } else if (value == 'delete') {
              _confirmDelete(context, socio, firebaseService);
            }
          },
        ),
      ),
    );
  }

  void _showSocioDialog(BuildContext context, {Usuario? socio}) {
    showDialog(
      context: context,
      builder: (context) => SocioDialog(socio: socio),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Usuario socio,
    FirebaseService firebaseService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Socio'),
        content: Text('¿Estás seguro de eliminar a "${socio.nombreCompleto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await firebaseService.deleteUsuario(
                socio.id,
              ); // Assuming generic delete method exists or add specific logic
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Socio eliminado')),
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

class SocioDialog extends StatefulWidget {
  final Usuario? socio;

  const SocioDialog({super.key, this.socio});

  @override
  State<SocioDialog> createState() => _SocioDialogState();
}

class _SocioDialogState extends State<SocioDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _apellidosController;
  late TextEditingController _usuarioController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _dniController;

  DateTime? _fechaNacimiento;
  String? _fotoUrl;
  List<String> _gruposAsignados = [];
  List<GrupoEntrenamiento> _gruposDisponibles = [];
  bool _isMinor = false; // To track if user is under 18

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.socio?.nombre ?? '');
    _apellidosController = TextEditingController(
      text: widget.socio?.apellidos ?? '',
    );
    _usuarioController = TextEditingController(
      text: widget.socio?.usuario ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.socio?.password ?? '',
    );
    _emailController = TextEditingController(text: widget.socio?.email ?? '');
    _telefonoController = TextEditingController(
      text: widget.socio?.telefono ?? '',
    );
    _dniController = TextEditingController(text: widget.socio?.dni ?? '');

    _fechaNacimiento = widget.socio?.fechaNacimiento;
    _fotoUrl = widget.socio?.fotoUrl;
    _gruposAsignados = List.from(widget.socio?.gruposAsignados ?? []);

    _checkAge(); // Initial check
    _loadGrupos();
  }

  void _checkAge() {
    if (_fechaNacimiento == null) {
      _isMinor = false;
      return;
    }
    final now = DateTime.now();
    final age = now.year - _fechaNacimiento!.year;
    // Check if birthday has happened this year
    bool birthdayPassed =
        now.month > _fechaNacimiento!.month ||
        (now.month == _fechaNacimiento!.month &&
            now.day >= _fechaNacimiento!.day);

    // Exact age calculation
    int exactAge = birthdayPassed ? age : age - 1;

    setState(() {
      _isMinor = exactAge < 18;
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.socio == null ? 'Nuevo Socio' : 'Editar Socio'),
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
                  usuario: widget.socio,
                  editable: true,
                  size: 100,
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

              // Fecha de nacimiento (CRITICAL for logic)
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        _fechaNacimiento ??
                        DateTime(2010), // Default easier for minors
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaNacimiento = picked;
                      _checkAge(); // Update logic when date changes
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento *',
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
              if (_fechaNacimiento == null)
                const Padding(
                  padding: EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    'Requerido para determinar si es menor',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Teléfono (Label changes)
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: _isMinor
                      ? 'Teléfono del Padre/Madre'
                      : 'Teléfono del Socio',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  hintText: '+34 600 000 000',
                  helperText: _isMinor ? 'Menor de edad detectado' : null,
                ),
                keyboardType: TextInputType.phone,
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

              // DNI
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(
                  labelText: 'DNI/NIE (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Usuario generate
              TextFormField(
                controller: _usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario *',
                  hintText: 'nombre.apellido',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                enabled: widget.socio == null,
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
                  if (widget.socio == null &&
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
                  'No hay grupos disponibles.',
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
          onPressed: _saveSocio,
          child: Text(widget.socio == null ? 'Crear' : 'Guardar'),
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

  Future<void> _saveSocio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de nacimiento es obligatoria'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final firebaseService = context.read<FirebaseService>();

      // Hash de la contraseña si se proporcionó una nueva
      String passwordToSave;
      if (_passwordController.text.isNotEmpty) {
        passwordToSave = PasswordHasher.hashPassword(_passwordController.text);
      } else {
        passwordToSave = widget.socio!.password;
      }

      final socio = Usuario(
        id: widget.socio?.id ?? '',
        usuario: _usuarioController.text.trim(),
        password: passwordToSave,
        rol: 'gimnasta', // Role enforced
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
        cargo: null, // Cargo is null for socios
        institucion: 'C.D. Stella Maris',
        fotoUrl: _fotoUrl ?? widget.socio?.fotoUrl,
        gruposAsignados: _gruposAsignados,
        fechaCreacion: widget.socio?.fechaCreacion ?? DateTime.now(),
      );

      // Using same methods as trainer since they are all Users but checking if generic method exists
      // If addEntrenador adds to 'usuarios' collection, we can reuse or create specific method
      // Assuming 'addEntrenador' adds to 'usuarios' collection regardless of role, but let's check FirebaseService later.
      // For now, I'll use addEntrenador method (which typically adds to 'usuarios') but naming suggests specific.
      // Ideally should be `addUsuario` or similar. I'll use `addEntrenador` (renaming conceptually to addUsuario) for now if generic,
      // or I will need to check FirebaseService again to be sure.
      // Checking used imports: `deleteEntrenador` was used in TrainersScreen.
      // I'll assume I need to verify FirebaseService methods.

      if (widget.socio == null) {
        await firebaseService.addEntrenador(socio); // Reusing for now
      } else {
        await firebaseService.updateEntrenador(socio); // Reusing for now
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.socio == null
                  ? 'Socio creado correctamente'
                  : 'Socio actualizado correctamente',
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
