import 'package:flutter/material.dart';
import 'package:youtube_downloader_app/services/permission_service.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cómo activar los permisos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Ve a Configuración del dispositivo\n'
                  '2. Busca "Aplicaciones" o "Apps"\n'
                  '3. Encuentra "YouTube Downloader"\n'
                  '4. Toca "Permisos"\n'
                  '5. Activa "Almacenamiento" o "Archivos y multimedia"',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Intentar de nuevo'),
          ),
        if (onSettings != null)
          TextButton(
            onPressed: onSettings,
            child: const Text('Abrir configuración'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  // Mostrar diálogo de permisos de almacenamiento
  static Future<void> showStoragePermissionDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialog(
          title: 'Permisos de Almacenamiento',
          message: 'La aplicación necesita acceso al almacenamiento para descargar videos.',
          onRetry: onRetry,
          onSettings: () async {
            Navigator.of(context).pop();
            await PermissionService.openAppSettings();
          },
        );
      },
    );
  }

  // Mostrar diálogo de permisos permanentemente denegados
  static Future<void> showPermanentlyDeniedDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialog(
          title: 'Permisos Bloqueados',
          message: 'Los permisos de almacenamiento han sido bloqueados permanentemente. Debes activarlos manualmente en la configuración del dispositivo.',
          onRetry: onRetry,
          onSettings: () async {
            Navigator.of(context).pop();
            await PermissionService.openAppSettings();
          },
        );
      },
    );
  }
}
