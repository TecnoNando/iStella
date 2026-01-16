import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/password_hasher.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/login_screen.dart';
import '../utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final Usuario usuario;

  const SettingsScreen({super.key, required this.usuario});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          // Sección: Mis Datos
          _buildSectionHeader('Mis Datos'),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('Editar Perfil'),
            subtitle: const Text('Email, teléfono, foto...'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(usuario: widget.usuario),
                ),
              );
            },
          ),

          const Divider(),

          // Sección: Seguridad
          _buildSectionHeader('Seguridad'),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: const Text('Cambiar Contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar cambio de contraseña
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximamente: Cambiar contraseña'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: AppColors.primary),
            title: const Text('Notificaciones'),
            trailing: Switch(
              value: true, // TODO: Implementar persistencia
              onChanged: (val) {
                // TODO: Implementar lógica
              },
              activeColor: AppColors.primary,
            ),
          ),

          const Divider(),

          // Sección: Otros
          _buildSectionHeader('Personalizar'),
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.grey),
            title: const Text('Personalizar Tema'),
            subtitle: const Text('Próximamente'),
            enabled: false,
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.grey),
            title: const Text('Idioma'),
            subtitle: const Text('Español (Único idioma)'),
            enabled: false,
          ),

          const Divider(),

          // Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),

          const SizedBox(height: 32),

          // Info App
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png', // Asegúrate deque este asset exista
                  height: 60,
                  errorBuilder: (c, o, s) => const Icon(
                    Icons.star,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'C.D. Stella Maris',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Versión $_appVersion',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña Anterior',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requerido';
                        // Verify old password logic could be here but safer on submit
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setState(() => isSaving = true);

                          try {
                            // 1. Verify old password
                            final isValid = PasswordHasher.verifyPassword(
                              oldPasswordController.text,
                              widget.usuario.password,
                            );

                            if (!isValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La contraseña anterior es incorrecta',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              setState(() => isSaving = false);
                              return;
                            }

                            // 2. Hash new password
                            final newHash = PasswordHasher.hashPassword(
                              newPasswordController.text,
                            );

                            // 3. Update user
                            final firebaseService = context
                                .read<FirebaseService>();
                            final updatedUser = widget.usuario.copyWith(
                              password: newHash,
                            );

                            await firebaseService.updateEntrenador(updatedUser);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contraseña actualizada con éxito',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  child: Text(isSaving ? 'Guardando...' : 'Cambiar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
