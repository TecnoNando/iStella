import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../utils/constants.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Seleccionar imagen desde galería o cámara
  Future<File?> pickImage({
    required ImageSource source,
    bool cropImage = true,
  }) async {
    try {
      // Seleccionar imagen
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      File imageFile = File(pickedFile.path);

      // Recortar imagen si se solicita
      if (cropImage) {
        final croppedFile = await _cropImage(imageFile);
        if (croppedFile != null) {
          imageFile = croppedFile;
        }
      }

      return imageFile;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Recortar imagen en forma circular
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Recortar Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  /// Mostrar opciones de selección de imagen
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final ImagePickerService service = ImagePickerService();

    return await showModalBottomSheet<File>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Galería'),
                onTap: () async {
                  final file = await service.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Cámara'),
                onTap: () async {
                  final file = await service.pickImage(
                    source: ImageSource.camera,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.error),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
