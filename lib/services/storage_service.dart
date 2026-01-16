import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Subir foto de perfil
  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    try {
      // Comprimir imagen antes de subir
      final compressedFile = await _compressImage(imageFile);

      // Referencia al archivo en Storage
      final ref = _storage.ref().child('profile_photos/$userId.jpg');

      // Subir archivo
      final uploadTask = await ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Limpiar archivo temporal
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      rethrow;
    }
  }

  /// Eliminar foto de perfil
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting profile photo: $e');
      // No lanzar error si la foto no existe
    }
  }

  /// Comprimir imagen para reducir tamaño
  Future<File> _compressImage(File file) async {
    try {
      // Leer imagen
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Redimensionar si es muy grande (max 800x800)
      img.Image resized = image;
      if (image.width > 800 || image.height > 800) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
        );
      }

      // Comprimir a JPEG con calidad 85
      final compressedBytes = img.encodeJpg(resized, quality: 85);

      // Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      print(
        'Imagen comprimida: ${file.lengthSync()} bytes → ${tempFile.lengthSync()} bytes',
      );

      return tempFile;
    } catch (e) {
      print('Error compressing image: $e');
      // Si falla la compresión, devolver archivo original
      return file;
    }
  }

  /// Obtener URL de foto de perfil
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos/$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      // Foto no existe
      return null;
    }
  }
}
