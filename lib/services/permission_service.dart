import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Verificar si necesitamos permisos especiales para Android 11+
  static Future<bool> needsManageExternalStoragePermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 30; // Android 11+
    } catch (e) {
      return false;
    }
  }

  // Solicitar permisos de almacenamiento de forma inteligente
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;



      if (sdkInt >= 30) {
        // Android 11+ - Usar MANAGE_EXTERNAL_STORAGE

        
        final manageStorageStatus = await Permission.manageExternalStorage.request();

        
        if (manageStorageStatus == PermissionStatus.granted) {
          return true;
        }
        
        // Si no se otorga MANAGE_EXTERNAL_STORAGE, intentar con permisos básicos

        return await _requestBasicStoragePermissions();
        
      } else if (sdkInt >= 23) {
        // Android 6-10 - Usar permisos básicos de almacenamiento

        return await _requestBasicStoragePermissions();
        
      } else {
        // Android 5 y anteriores - Los permisos se otorgan automáticamente

        return true;
      }
    } catch (e) {

      return await _requestBasicStoragePermissions();
    }
  }

  // Solicitar permisos básicos de almacenamiento
  static Future<bool> _requestBasicStoragePermissions() async {
    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];


      
      final results = await permissions.request();

      
      // Verificar si al menos uno de los permisos fue otorgado
      final hasAnyPermission = results.values.any((status) => status == PermissionStatus.granted);
      
      if (hasAnyPermission) {

        return true;
      }
      
      // Si no se otorgaron permisos, verificar si están permanentemente denegados
      final permanentlyDenied = results.values.any((status) => status == PermissionStatus.permanentlyDenied);
      if (permanentlyDenied) {

        return false;
      }
      

      return false;
    } catch (e) {

      return false;
    }
  }

  // Verificar si tenemos permisos de almacenamiento
  static Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // Android 11+ - Verificar MANAGE_EXTERNAL_STORAGE
        final manageStorageStatus = await Permission.manageExternalStorage.status;
        if (manageStorageStatus == PermissionStatus.granted) {
          return true;
        }
        
        // Si no tiene MANAGE_EXTERNAL_STORAGE, verificar permisos básicos
        return await _hasBasicStoragePermissions();
      } else {
        // Android 10 y anteriores - Verificar permisos básicos
        return await _hasBasicStoragePermissions();
      }
    } catch (e) {

      return false;
    }
  }

  // Verificar permisos básicos de almacenamiento
  static Future<bool> _hasBasicStoragePermissions() async {
    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        if (status == PermissionStatus.granted) {
          return true;
        }
      }
      
      return false;
    } catch (e) {

      return false;
    }
  }

  // Solicitar permisos de notificaciones
  static Future<bool> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // Android 13+ - Solicitar permiso de notificaciones
        final notificationStatus = await Permission.notification.request();
        return notificationStatus == PermissionStatus.granted;
      } else {
        // Android 12 y anteriores - Las notificaciones no requieren permiso
        return true;
      }
    } catch (e) {

      return true; // No fallar si no se pueden solicitar notificaciones
    }
  }

  // Abrir configuración de permisos de la app
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      // ignore: empty_catches
    }
  }

  // Obtener mensaje de error personalizado para permisos
  static String getPermissionErrorMessage() {
    return 'Permisos de almacenamiento requeridos.\n\n'
           'Para descargar videos, la app necesita acceso al almacenamiento.\n\n'
           'Por favor, ve a Configuración > Aplicaciones > YouTube Downloader > Permisos\n'
           'y activa "Almacenamiento" o "Archivos y multimedia".';
  }

  // Verificar si los permisos están permanentemente denegados
  static Future<bool> arePermissionsPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;

    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        if (status == PermissionStatus.permanentlyDenied) {
          return true;
        }
      }
      
      return false;
    } catch (e) {

      return false;
    }
  }
}
