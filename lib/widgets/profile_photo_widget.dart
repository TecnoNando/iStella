import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/usuario.dart';
import '../services/image_picker_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ProfilePhotoWidget extends StatefulWidget {
  final Usuario? usuario;
  final Function(String photoUrl)? onPhotoUploaded;
  final bool editable;
  final double size;

  const ProfilePhotoWidget({
    super.key,
    this.usuario,
    this.onPhotoUploaded,
    this.editable = false,
    this.size = 100,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  File? _selectedImage;

  Future<void> _selectAndUploadPhoto() async {
    if (!widget.editable) return;

    // Mostrar opciones de selección
    final imageFile = await ImagePickerService.showImageSourceDialog(context);

    if (imageFile == null) return;

    setState(() {
      _selectedImage = imageFile;
      _isUploading = true;
    });

    try {
      // Subir foto a Firebase Storage
      final photoUrl = await _storageService.uploadProfilePhoto(
        imageFile,
        widget.usuario!.id,
      );

      // Notificar al padre
      widget.onPhotoUploaded?.call(photoUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _selectedImage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.editable ? _selectAndUploadPhoto : null,
      child: Stack(
        children: [
          // Foto de perfil
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: ClipOval(child: _buildPhotoContent()),
          ),

          // Indicador de carga
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),

          // Botón de editar
          if (widget.editable && !_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent() {
    // Mostrar imagen seleccionada localmente
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }

    // Mostrar foto de perfil de Firebase
    if (widget.usuario?.tieneFoto == true) {
      return CachedNetworkImage(
        imageUrl: widget.usuario!.fotoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => _buildInitialsAvatar(),
      );
    }

    // Mostrar avatar con iniciales
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          widget.usuario?.iniciales ?? '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
