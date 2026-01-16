import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/socio.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminPanel)),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        children: [
          _buildAdminCard(
            context,
            icon: Icons.people,
            title: AppStrings.manageSocios,
            subtitle: 'Añadir, editar o eliminar socios',
            color: AppColors.primary,
            onTap: () => _showManageSociosDialog(context),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildAdminCard(
            context,
            icon: Icons.picture_as_pdf,
            title: AppStrings.pdfTemplateEditor,
            subtitle: 'Personalizar plantilla de PDF',
            color: AppColors.secondary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Editor de plantillas próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildAdminCard(
            context,
            icon: Icons.settings,
            title: AppStrings.settings,
            subtitle: 'Configuración de la aplicación',
            color: AppColors.textSecondary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageSociosDialog(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.borderRadius),
                    topRight: Radius.circular(AppDimensions.borderRadius),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    const Expanded(
                      child: Text(
                        'Gestionar Socios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Lista de socios
              Expanded(
                child: StreamBuilder<List<Socio>>(
                  stream: firebaseService.getSociosStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final socios = snapshot.data!;

                    if (socios.isEmpty) {
                      return const Center(
                        child: Text('No hay socios registrados'),
                      );
                    }

                    return ListView.builder(
                      itemCount: socios.length,
                      itemBuilder: (context, index) {
                        final socio = socios[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              socio.nombre[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(socio.nombre),
                          subtitle: Text(socio.categoria.toUpperCase()),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            onPressed: () => _confirmDelete(context, socio),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Botón agregar
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddSocioDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Socio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSocioDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCategory = 'senior';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Socio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'infantil', child: Text('Infantil')),
                DropdownMenuItem(value: 'juvenil', child: Text('Juvenil')),
                DropdownMenuItem(value: 'senior', child: Text('Senior')),
              ],
              onChanged: (value) {
                if (value != null) selectedCategory = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un nombre')),
                );
                return;
              }

              final firebaseService = context.read<FirebaseService>();
              final newSocio = Socio(
                id: '',
                nombre: nameController.text.trim(),
                categoria: selectedCategory,
                fechaAlta: DateTime.now(),
              );

              await firebaseService.addSocio(newSocio);

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Socio agregado correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Socio socio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Socio'),
        content: Text('¿Estás seguro de eliminar a ${socio.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.deleteSocio(socio.id);

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Socio eliminado'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
