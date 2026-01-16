import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/usuario.dart';
import '../widgets/profile_photo_widget.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  final Usuario usuario;

  const ProfileScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implementar edición de perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edición de perfil próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Foto de perfil
            ProfilePhotoWidget(usuario: usuario, editable: false, size: 120),
            const SizedBox(height: 16),

            // Nombre completo
            Text(
              usuario.nombreCompleto,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Cargo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                usuario.cargo ??
                    (usuario.isAdmin ? 'Administrador' : 'Entrenador'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Información personal
            _buildSection(
              title: 'Información Personal',
              children: [
                if (usuario.email != null)
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: usuario.email!,
                  ),
                if (usuario.telefono != null)
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: usuario.telefono!,
                  ),
                if (usuario.dni != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'DNI/NIE',
                    value: usuario.dni!,
                  ),
                if (usuario.fechaNacimiento != null)
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Fecha de Nacimiento',
                    value: DateFormat(
                      'dd/MM/yyyy',
                    ).format(usuario.fechaNacimiento!),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Información profesional
            _buildSection(
              title: 'Información Profesional',
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Institución',
                  value: usuario.institucion ?? 'C.D. Stella Maris',
                ),
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Usuario',
                  value: usuario.usuario,
                ),
                _buildInfoRow(
                  icon: Icons.admin_panel_settings,
                  label: 'Rol',
                  value: usuario.isAdmin ? 'Administrador' : 'Entrenador',
                ),
                if (usuario.gruposAsignados.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.group,
                    label: 'Grupos Asignados',
                    value: '${usuario.gruposAsignados.length} grupos',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Información del sistema
            _buildSection(
              title: 'Información del Sistema',
              children: [
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Miembro desde',
                  value: DateFormat('dd/MM/yyyy').format(usuario.fechaCreacion),
                ),
                _buildInfoRow(
                  icon: Icons.check_circle,
                  label: 'Estado',
                  value: usuario.activo ? 'Activo' : 'Inactivo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }
}
