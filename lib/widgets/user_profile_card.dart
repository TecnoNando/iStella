import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/usuario.dart';
import '../utils/constants.dart';

class UserProfileCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback? onTap;

  const UserProfileCard({super.key, required this.usuario, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Foto de perfil
              _buildProfilePhoto(),
              const SizedBox(width: 16),

              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buenos días',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          usuario.isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.sports,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            usuario.rolMostrable,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Icono de perfil
              IconButton(
                icon: const Icon(Icons.person, color: AppColors.primary),
                onPressed: onTap,
                tooltip: 'Ver perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: usuario.tieneFoto
            ? CachedNetworkImage(
                imageUrl: usuario.fotoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => _buildInitialsAvatar(),
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          usuario.iniciales,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
