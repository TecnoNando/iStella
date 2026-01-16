import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ota_update/ota_update.dart';

class UpdateService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Inicializar Remote Config
  static Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(
            hours: 1,
          ), // 1 hora para produccion
        ),
      );

      // Valores por defecto
      await _remoteConfig.setDefaults({
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'update_url': '',
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
    try {
      final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        if (i >= parts1.length || i >= parts2.length) break;
        if (parts1[i] < parts2[i]) return -1;
        if (parts1[i] > parts2[i]) return 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Abrir URL de descarga (Backup flow)
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
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Más moderno
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.rocket_launch, size: 50, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  updateInfo.mustUpdate
                      ? '¡Actualización Necesaria!'
                      : 'Nueva Versión Disponible',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  updateInfo.updateMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Comparación Visual de Versiones
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _VersionBadge(
                        label: 'Versión Actual',
                        version: updateInfo.currentVersion,
                        color: Colors.grey,
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      _VersionBadge(
                        label: 'Nueva Versión',
                        version: updateInfo.latestVersion,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Botón Principal
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra diálogo actual
                    _OtaUpdateHandler.run(
                      context,
                      updateInfo.updateUrl,
                    ); // Inicia OTA
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'INSTALAR AHORA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                if (!updateInfo.mustUpdate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Recordarme más tarde',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Badge helper
class _VersionBadge extends StatelessWidget {
  final String label;
  final String version;
  final MaterialColor color;

  const _VersionBadge({
    required this.label,
    required this.version,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.shade200),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

// Manejador OTA separado y limpio
class _OtaUpdateHandler {
  static void run(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OtaProgressDialog(url: url),
    );
  }
}

// Diálogo de Progreso Stateful
class _OtaProgressDialog extends StatefulWidget {
  final String url;
  const _OtaProgressDialog({required this.url});

  @override
  State<_OtaProgressDialog> createState() => _OtaProgressDialogState();
}

class _OtaProgressDialogState extends State<_OtaProgressDialog> {
  String status = 'Conectando...';
  double progress = 0.0;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() {
    try {
      OtaUpdate()
          .execute(widget.url, destinationFilename: 'iStella_update.apk')
          .listen(
            (OtaEvent event) {
              if (!mounted) return;
              setState(() {
                switch (event.status) {
                  case OtaStatus.DOWNLOADING:
                    status = 'Descargando... ${event.value}%';
                    progress = (double.tryParse(event.value ?? '0') ?? 0) / 100;
                    break;
                  case OtaStatus.INSTALLING:
                    status = 'Instalando paquete...';
                    progress = 1.0;
                    break;
                  case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                    status = 'Error: Permisos no concedidos';
                    hasError = true;
                    break;
                  case OtaStatus.INTERNAL_ERROR:
                    status = 'Error Interno';
                    hasError = true;
                    break;
                  case OtaStatus.DOWNLOAD_ERROR:
                    status = 'Error de Descarga';
                    hasError = true;
                    break;
                  default:
                    status = 'Procesando...';
                    break;
                }
              });

              // Cerrar diálogo automáticamente si empieza a instalar (OtaUpdate lanza el intent y cierra)
              if (event.status == OtaStatus.INSTALLING) {
                // Opcional: Esperar un momento o cerrar
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) Navigator.pop(context);
                });
              }
            },
            onError: (e) {
              if (mounted) {
                setState(() {
                  status = 'Error inesperado: $e';
                  hasError = true;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          status = 'Excepción: $e';
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(hasError ? 'Error en Actualización' : 'Actualizando iStella'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasError) ...[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 20),
            Text(status, style: const TextStyle(fontWeight: FontWeight.w500)),
          ] else ...[
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cierra OTA
                UpdateService.openUpdateUrl(widget.url); // Fallback
              },
              child: const Text('Descargar vía Navegador (Alternativo)'),
            ),
          ],
        ],
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
