import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Inicializar Remote Config
  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Valores por defecto
      await _remoteConfig.setDefaults({
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'update_url':
            'https://drive.google.com/file/d/YOUR_FILE_ID/view?usp=sharing',
        'update_message':
            'Hay una nueva versión disponible. Por favor, actualiza la app.',
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Error initializing Remote Config: $e');
    }
  }

  /// Verificar si hay actualización disponible
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      await _remoteConfig.fetchAndActivate();

      final minVersion = _remoteConfig.getString('min_version');
      final latestVersion = _remoteConfig.getString('latest_version');
      final forceUpdate = _remoteConfig.getBool('force_update');
      final updateUrl = _remoteConfig.getString('update_url');
      final updateMessage = _remoteConfig.getString('update_message');

      final needsUpdate = _compareVersions(currentVersion, latestVersion) < 0;
      final mustUpdate =
          forceUpdate || _compareVersions(currentVersion, minVersion) < 0;

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        needsUpdate: needsUpdate,
        mustUpdate: mustUpdate,
        updateUrl: updateUrl,
        updateMessage: updateMessage,
      );
    } catch (e) {
      print('Error checking for update: $e');
      return UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        needsUpdate: false,
        mustUpdate: false,
        updateUrl: '',
        updateMessage: '',
      );
    }
  }

  /// Comparar versiones (1.0.0 vs 1.0.1)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// Abrir URL de descarga
  static Future<void> openUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Mostrar diálogo de actualización
  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.mustUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !updateInfo.mustUpdate,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                updateInfo.mustUpdate
                    ? 'Actualización Requerida'
                    : 'Actualización Disponible',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(updateInfo.updateMessage),
              const SizedBox(height: 16),
              Text(
                'Versión actual: ${updateInfo.currentVersion}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Última versión: ${updateInfo.latestVersion}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            if (!updateInfo.mustUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Más tarde'),
              ),
            ElevatedButton(
              onPressed: () {
                openUpdateUrl(updateInfo.updateUrl);
                if (!updateInfo.mustUpdate) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool needsUpdate;
  final bool mustUpdate;
  final String updateUrl;
  final String updateMessage;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.needsUpdate,
    required this.mustUpdate,
    required this.updateUrl,
    required this.updateMessage,
  });
}
