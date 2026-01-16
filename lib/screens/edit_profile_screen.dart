import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../services/firebase_service.dart';
import '../widgets/profile_photo_widget.dart';
import '../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final Usuario usuario;

  const EditProfileScreen({super.key, required this.usuario});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  String? _fotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.usuario.email ?? '');
    _telefonoController = TextEditingController(
      text: widget.usuario.telefono ?? '',
    );
    _fotoUrl = widget.usuario.fotoUrl;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseService = context.read<FirebaseService>();

      // Crear usuario actualizado
      final updatedUsuario = widget.usuario.copyWith(
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        fotoUrl: _fotoUrl,
      );

      // Guardar en Firestore
      await firebaseService.updateEntrenador(updatedUsuario);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Center(
                child: ProfilePhotoWidget(
                  usuario: widget.usuario.copyWith(fotoUrl: _fotoUrl),
                  editable: true,
                  size: 120,
                  onPhotoUploaded: (url) {
                    setState(() {
                      _fotoUrl = url;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Toca la foto para cambiarla',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Información no editable
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        'Nombre',
                        widget.usuario.nombreCompleto,
                      ),
                      _buildReadOnlyField('Usuario', widget.usuario.usuario),
                      _buildReadOnlyField(
                        'Rol',
                        widget.usuario.cargo ?? 'Entrenador',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campos editables
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
