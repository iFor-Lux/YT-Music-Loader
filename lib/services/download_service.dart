import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class DownloadService {
  static final Map<String, StreamController<double>> _downloadProgress = {};
  static final Map<String, bool> _downloadStatus = {};
  static final Map<String, String> _downloadErrors = {};
  static final Map<String, int> _downloadStartTime = {};
  static final Map<String, int> _downloadTotalBytes = {};
  static final Map<String, int> _downloadCurrentBytes = {};

  // Obtener progreso de descarga
  static Stream<double> getDownloadProgress(String videoId) {
    if (!_downloadProgress.containsKey(videoId)) {
      _downloadProgress[videoId] = StreamController<double>.broadcast();
    }
    return _downloadProgress[videoId]!.stream;
  }

  // Obtener estado de descarga
  static bool isDownloading(String videoId) {
    return _downloadStatus[videoId] ?? false;
  }

  // Obtener error de descarga
  static String? getDownloadError(String videoId) {
    return _downloadErrors[videoId];
  }

  // Obtener tiempo restante estimado
  static String getEstimatedTimeRemaining(String videoId) {
    final startTime = _downloadStartTime[videoId];
    final currentBytes = _downloadCurrentBytes[videoId];
    final totalBytes = _downloadTotalBytes[videoId];
    
    if (startTime == null || currentBytes == null || totalBytes == null || currentBytes == 0) return '';
    
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    if (elapsed == 0) return '';
    
    final bytesPerMs = currentBytes / elapsed;
    final remainingBytes = totalBytes - currentBytes;
    final remainingMs = remainingBytes / bytesPerMs;
    
    if (remainingMs <= 0) return '';
    
    final remainingSeconds = (remainingMs / 1000).round();
    if (remainingSeconds < 60) {
      return '${remainingSeconds}s';
    } else if (remainingSeconds < 3600) {
      final minutes = (remainingSeconds / 60).round();
      final seconds = remainingSeconds % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = (remainingSeconds / 3600).round();
      final minutes = ((remainingSeconds % 3600) / 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  // Obtener tamaño de archivo formateado
  static String getFileSizeFormatted(String videoId) {
    final totalBytes = _downloadTotalBytes[videoId];
    if (totalBytes == null) return '';
    return _formatFileSize(totalBytes);
  }

  // Obtener progreso formateado
  static String getProgressFormatted(String videoId) {
    final currentBytes = _downloadCurrentBytes[videoId];
    final totalBytes = _downloadTotalBytes[videoId];
    if (currentBytes == null || totalBytes == null || totalBytes == 0) return '';
    
    final downloaded = _formatFileSize(currentBytes);
    final total = _formatFileSize(totalBytes);
    return '$downloaded / $total';
  }

  // Limpiar progreso
  static void clearProgress(String videoId) {
    _downloadProgress[videoId]?.close();
    _downloadProgress.remove(videoId);
    _downloadStatus.remove(videoId);
    _downloadErrors.remove(videoId);
    _downloadStartTime.remove(videoId);
    _downloadTotalBytes.remove(videoId);
    _downloadCurrentBytes.remove(videoId);
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // print('🔍 DEBUG: Requesting Android permissions...');
      
      // Solicitar múltiples tipos de permisos para mayor compatibilidad
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.photos,
        Permission.audio,
        Permission.videos,
      ];
      
      Map<Permission, PermissionStatus> statuses = {};
      
      for (Permission permission in permissions) {
        try {
          final status = await permission.request();
          statuses[permission] = status;
          // print('🔍 DEBUG: Permission ${permission.toString()}: ${status.isGranted}');
        } catch (e) {
          // print('🔍 DEBUG: Error requesting permission ${permission.toString()}: $e');
        }
      }
      
      // Verificar si al menos uno de los permisos fue concedido
      final anyGranted = statuses.values.any((status) => status.isGranted);
      // print('🔍 DEBUG: Any permission granted: $anyGranted');
      
      return anyGranted;
    }
    return true;
  }

  static Future<String?> getDownloadDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('download_path');
      
      if (customPath != null && await Directory(customPath).exists()) {
        // Crear subcarpeta para YouTube Downloads si no existe
        final youtubeDir = Directory('$customPath/YouTube_Downloads');
        if (!await youtubeDir.exists()) {
          await youtubeDir.create(recursive: true);
        }
        return youtubeDir.path;
      }

      // Carpeta por defecto
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        final musicDir = Directory('${directory.path}/YouTube_Downloads');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        return musicDir.path;
      }
    } catch (e) {
      // print('Error getting download directory: $e');
    }
    return null;
  }

  static Future<void> setDownloadDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_path', path);
  }

  // Seleccionar directorio manualmente usando file_picker
  static Future<String?> selectDirectoryManually() async {
    try {
      // print('🔍 DEBUG: Opening directory picker...');
      
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar carpeta de descarga',
        initialDirectory: '/storage',
      );
      
      if (result != null) {
        // print('🔍 DEBUG: User selected directory: $result');
        
        // Verificar si el directorio es accesible
        try {
          final dir = Directory(result);
          if (await dir.exists()) {
            // Crear subcarpeta para YouTube Downloads
            final youtubeDir = Directory('$result/YouTube_Downloads');
            if (!await youtubeDir.exists()) {
              await youtubeDir.create(recursive: true);
            }
            
            // Guardar la selección
            await setDownloadDirectory(youtubeDir.path);
            // print('🔍 DEBUG: Directory set successfully: ${youtubeDir.path}');
            
            return youtubeDir.path;
          }
        } catch (e) {
          // print('🔍 DEBUG: Error verifying selected directory: $e');
        }
      } else {
        // print('🔍 DEBUG: User cancelled directory selection');
      }
    } catch (e) {
      // print('🔍 DEBUG: Error in manual directory selection: $e');
    }
    
    return null;
  }

  // Obtener preferencia de portada
  static Future<bool> getDownloadWithCover() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('download_with_cover') ?? true; // Por defecto con portada
  }

  // Establecer preferencia de portada
  static Future<void> setDownloadWithCover(bool withCover) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('download_with_cover', withCover);
  }

  // Obtener preferencia de letras sincronizadas
  static Future<bool> getDownloadWithLyrics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('download_with_lyrics') ?? false; // Por defecto sin letras
  }

  // Establecer preferencia de letras sincronizadas
  static Future<void> setDownloadWithLyrics(bool withLyrics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('download_with_lyrics', withLyrics);
  }

  // Obtener calidad de descarga
  static Future<String> getDownloadQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('download_quality') ?? 'best';
  }

  // Establecer calidad de descarga
  static Future<void> setDownloadQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_quality', quality);
  }

  // Obtener máximo de descargas simultáneas
  static Future<int> getMaxConcurrentDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('max_concurrent_downloads') ?? 3;
  }

  // Establecer máximo de descargas simultáneas
  static Future<void> setMaxConcurrentDownloads(int max) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_concurrent_downloads', max);
  }

  // Obtener inicio automático de descargas
  static Future<bool> getAutoStartDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_start_downloads') ?? true;
  }

  // Establecer inicio automático de descargas
  static Future<void> setAutoStartDownloads(bool autoStart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_downloads', autoStart);
  }

  // Obtener mostrar notificaciones
  static Future<bool> getShowNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_notifications') ?? true;
  }

  // Establecer mostrar notificaciones
  static Future<void> setShowNotifications(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_notifications', show);
  }

  // Obtener mantener pantalla encendida
  static Future<bool> getKeepScreenOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('keep_screen_on') ?? false;
  }

  // Establecer mantener pantalla encendida
  static Future<void> setKeepScreenOn(bool keepOn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_screen_on', keepOn);
  }

  static Future<bool> downloadAudio(String url, String fileName, String videoId, {String? thumbnailUrl, String? lyrics}) async {
    try {
      _downloadStatus[videoId] = true;
      _downloadErrors.remove(videoId);
      _downloadStartTime[videoId] = DateTime.now().millisecondsSinceEpoch;
      _downloadCurrentBytes[videoId] = 0;
      
      // Verificar que la URL sea válida
      if (url.isEmpty || !url.startsWith('http')) {
        _downloadErrors[videoId] = 'URL de audio inválida';
        _downloadStatus[videoId] = false;
        return false;
      }
      
      // Solicitar permisos
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _downloadErrors[videoId] = 'Permisos de almacenamiento denegados';
        _downloadStatus[videoId] = false;
        return false;
      }

      // Obtener directorio de descarga
      final downloadDir = await getDownloadDirectory();
      if (downloadDir == null) {
        _downloadErrors[videoId] = 'No se pudo acceder al directorio de descarga';
        _downloadStatus[videoId] = false;
        return false;
      }

      // Crear nombre de archivo seguro
      final safeFileName = _createSafeFileName(fileName);
      final filePath = '$downloadDir/$safeFileName.mp3';

      // Verificar si el archivo ya existe
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        // Si existe, agregar número al final
        int counter = 1;
        String newFilePath = filePath;
        while (await File(newFilePath).exists()) {
          final nameWithoutExt = safeFileName;
          newFilePath = '$downloadDir/${nameWithoutExt} $counter.mp3';
          counter++;
        }
        final file = File(newFilePath);
        
        // Realizar la descarga con progreso optimizado
        final success = await _performDownload(file, url, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);
        return success;
      } else {
        // Archivo no existe, descargar normalmente
        final file = File(filePath);
        final success = await _performDownload(file, url, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);
        return success;
      }
    } catch (e) {
      _downloadErrors[videoId] = 'Error: $e';
      _downloadStatus[videoId] = false;
      // print('Error downloading audio: $e');
      return false;
    }
  }

  static Future<bool> _performDownload(File file, String url, String videoId, {String? thumbnailUrl, String? lyrics}) async {
    const int maxRetries = 3;
    const Duration timeout = Duration(minutes: 3);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // print('🔍 DEBUG: Download attempt $attempt/$maxRetries for video $videoId');
        
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(url));
        
        // Headers mejorados para evitar bloqueos
        request.headers.addAll({
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Accept-Language': 'en-US,en;q=0.9,es;q=0.8',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        });
        
        final response = await client.send(request).timeout(timeout);

        if (response.statusCode == 200) {
          final sink = file.openWrite();
          int downloaded = 0;
          final total = response.contentLength ?? 0;
          _downloadTotalBytes[videoId] = total;
          final stopwatch = Stopwatch()..start();

          await for (final chunk in response.stream) {
            sink.add(chunk);
            downloaded += chunk.length;
            _downloadCurrentBytes[videoId] = downloaded;
            
            // Actualizar progreso cada 50KB o cada 500ms
            if (total > 0 && (downloaded % 51200 == 0 || stopwatch.elapsed.inMilliseconds >= 500)) {
              final progress = downloaded / total;
              _downloadProgress[videoId]?.add(progress);
              stopwatch.reset();
            }
          }

          await sink.close();
          client.close();
          
          // Verificar integridad del archivo
          if (await _verifyFileIntegrity(file)) {
            _downloadProgress[videoId]?.add(1.0);
            _downloadStatus[videoId] = false;
            // print('🔍 DEBUG: Download completed successfully on attempt $attempt');
            
            // Procesar metadatos después de descarga exitosa
            if (thumbnailUrl != null || lyrics != null) {
              try {
                await _processMP3Metadata(file, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);
                // print('🔍 DEBUG: MP3 metadata processed successfully');
              } catch (e) {
                // print('🔍 DEBUG: Error processing MP3 metadata: $e');
                // No fallar la descarga si falla el procesamiento de metadatos
              }
            }
            
            return true;
          } else {
            // print('🔍 DEBUG: File integrity check failed on attempt $attempt');
            if (attempt < maxRetries) {
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
            _downloadErrors[videoId] = 'Archivo descargado corrupto después de $maxRetries intentos';
            _downloadStatus[videoId] = false;
            return false;
          }
        } else {
          client.close();
          // print('🔍 DEBUG: HTTP error ${response.statusCode} on attempt $attempt');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2)); // Backoff exponencial
            continue;
          }
          _downloadErrors[videoId] = 'Error HTTP: ${response.statusCode} después de $maxRetries intentos';
          _downloadStatus[videoId] = false;
          return false;
        }
      } catch (e) {
        // print('🔍 DEBUG: Download error on attempt $attempt: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Backoff exponencial
          continue;
        }
        _downloadErrors[videoId] = 'Error después de $maxRetries intentos: $e';
        _downloadStatus[videoId] = false;
        return false;
      }
    }
    
    return false;
  }

  static String _createSafeFileName(String fileName) {
    // Remover caracteres especiales y reemplazar espacios múltiples por uno solo
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }

  static Future<List<File>> getDownloadedFiles() async {
    try {
      final downloadDir = await getDownloadDirectory();
      if (downloadDir == null) return [];

      final directory = Directory(downloadDir);
      if (!await directory.exists()) return [];

      final files = await directory.list().where((entity) => 
        entity is File && entity.path.endsWith('.mp3')
      ).cast<File>().toList();

      return files;
    } catch (e) {
      // print('Error getting downloaded files: $e');
      return [];
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // print('Error deleting file: $e');
      return false;
    }
  }

  static Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return _formatFileSize(bytes);
      }
      return '0 B';
    } catch (e) {
      return '0 B';
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Obtener directorios disponibles en Android (MEJORADO)
  static Future<List<String>> getAvailableDirectories() async {
    List<String> directories = [];
    
    if (Platform.isAndroid) {
      // print('🔍 DEBUG: Scanning available directories...');
      
      // Directorios internos del dispositivo
      final internalDirs = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Media',
      ];
      
      // Verificar directorios internos
      for (String dir in internalDirs) {
        try {
          if (await Directory(dir).exists()) {
            directories.add(dir);
            // print('🔍 DEBUG: Found internal directory: $dir');
          }
        } catch (e) {
          // print('🔍 DEBUG: Error checking internal directory $dir: $e');
        }
      }
      
      // Buscar SD cards externas con múltiples métodos
      try {
        // Método 1: Escaneo de patrones comunes
        await _scanWithPatterns(directories);
        
        // Método 2: Escaneo de rutas específicas
        await _scanSpecificPaths(directories);
        
        // Método 3: Escaneo recursivo de /storage
        await _scanRecursiveStorage(directories);
        
        // Método 4: Verificar variables de entorno
        await _scanEnvironmentPaths(directories);
        
        // print('🔍 DEBUG: Total directories found: ${directories.length}');
        
      } catch (e) {
        // print('🔍 DEBUG: Error scanning external storage: $e');
      }
    }
    
    // Eliminar duplicados y ordenar
    final uniqueDirectories = directories.toSet().toList();
    uniqueDirectories.sort();
    
    return uniqueDirectories;
  }
  
  // Método 1: Escaneo con patrones comunes
  static Future<void> _scanWithPatterns(List<String> directories) async {
    final sdCardPatterns = [
      'sdcard1', 'extSdCard', 'sdcard0', 'external', 'card',
      '02E8-120D', '0000-0000', '1234-5678', 'ABCD-EFGH',
      'emulated', 'legacy', 'primary', 'secondary',
      'sdcard', 'ext', 'external_sd', 'external_sdcard',
    ];
    
    final basePaths = [
      '/storage',
      '/mnt',
      '/mnt/media_rw',
      '/mnt/runtime',
      '/storage/emulated',
    ];
    
    for (String basePath in basePaths) {
      await _scanStorageDirectory(basePath, sdCardPatterns, directories);
    }
  }
  
  // Método 2: Escaneo de rutas específicas
  static Future<void> _scanSpecificPaths(List<String> directories) async {
    final specificPaths = [
      '/storage/sdcard1',
      '/storage/extSdCard',
      '/storage/sdcard0',
      '/mnt/sdcard',
      '/mnt/extSdCard',
      '/storage/02E8-120D',
      '/mnt/media_rw/02E8-120D',
      '/storage/emulated/1',
      '/sdcard',
      '/external_sd',
      '/external_sdcard',
      '/mnt/external_sd',
      '/mnt/external_sdcard',
    ];
    
    for (String path in specificPaths) {
      try {
        if (await Directory(path).exists()) {
          // print('🔍 DEBUG: Found specific SD card path: $path');
          final subDirs = ['Download', 'Music', 'Documents', 'DCIM', 'Movies', 'Pictures', 'Audio', 'Media'];
          for (String subDir in subDirs) {
            final subPath = '$path/$subDir';
            try {
              if (await Directory(subPath).exists()) {
                directories.add(subPath);
                // print('🔍 DEBUG: Added specific SD card directory: $subPath');
              } else {
                try {
                  await Directory(subPath).create(recursive: true);
                  directories.add(subPath);
                  // print('🔍 DEBUG: Created specific SD card directory: $subPath');
                } catch (e) {
                  // print('🔍 DEBUG: Could not create specific SD card directory $subPath: $e');
                }
              }
            } catch (e) {
              // print('🔍 DEBUG: Error with specific SD card subdirectory $subPath: $e');
            }
          }
        }
      } catch (e) {
        // print('🔍 DEBUG: Error checking specific path $path: $e');
      }
    }
  }
  
  // Método 3: Escaneo recursivo de /storage
  static Future<void> _scanRecursiveStorage(List<String> directories) async {
    try {
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final dirName = entity.path.split('/').last;
            // print('🔍 DEBUG: Found storage directory: $dirName');
            
            // Verificar si parece ser una SD card
            if (_looksLikeSDCard(dirName)) {
              // print('🔍 DEBUG: Potential SD card found: ${entity.path}');
              await _addSubdirectories(entity.path, directories);
            }
          }
        }
      }
    } catch (e) {
      // print('🔍 DEBUG: Error in recursive storage scan: $e');
    }
  }
  
  // Método 4: Verificar variables de entorno
  static Future<void> _scanEnvironmentPaths(List<String> directories) async {
    try {
      // Intentar obtener directorios externos del sistema
      final externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null) {
        for (Directory dir in externalDirs) {
          // print('🔍 DEBUG: Found external storage directory: ${dir.path}');
          await _addSubdirectories(dir.path, directories);
        }
      }
      
      // Intentar obtener directorios de aplicación externos
      final appDirs = await getExternalCacheDirectories();
      if (appDirs != null) {
        for (Directory dir in appDirs) {
          final parentDir = dir.parent.path;
          // print('🔍 DEBUG: Found external app directory: $parentDir');
          await _addSubdirectories(parentDir, directories);
        }
      }
    } catch (e) {
      // print('🔍 DEBUG: Error scanning environment paths: $e');
    }
  }
  
  // Función auxiliar para verificar si un nombre parece ser SD card
  static bool _looksLikeSDCard(String dirName) {
    final sdCardKeywords = [
      'sdcard', 'ext', 'external', 'card', 'sd', 'memory',
      '02E8-120D', '0000-0000', '1234-5678', 'ABCD-EFGH',
      'emulated', 'legacy', 'primary', 'secondary',
    ];
    
    return sdCardKeywords.any((keyword) => 
      dirName.toLowerCase().contains(keyword.toLowerCase())
    );
  }
  
  // Función auxiliar para agregar subdirectorios
  static Future<void> _addSubdirectories(String basePath, List<String> directories) async {
    final subDirs = ['Download', 'Music', 'Documents', 'DCIM', 'Movies', 'Pictures', 'Audio', 'Media'];
    for (String subDir in subDirs) {
      final subPath = '$basePath/$subDir';
      try {
        if (await Directory(subPath).exists()) {
          directories.add(subPath);
          // print('🔍 DEBUG: Added subdirectory: $subPath');
        } else {
          try {
            await Directory(subPath).create(recursive: true);
            directories.add(subPath);
            // print('🔍 DEBUG: Created and added subdirectory: $subPath');
          } catch (e) {
            // print('🔍 DEBUG: Could not create subdirectory $subPath: $e');
          }
        }
      } catch (e) {
        // print('🔍 DEBUG: Error with subdirectory $subPath: $e');
      }
    }
  }
  
  // Función auxiliar para escanear directorios de almacenamiento
  static Future<void> _scanStorageDirectory(String basePath, List<String> patterns, List<String> directories) async {
    try {
      final baseDir = Directory(basePath);
      if (!await baseDir.exists()) {
        // print('🔍 DEBUG: Base directory does not exist: $basePath');
        return;
      }
      
      await for (final entity in baseDir.list()) {
        if (entity is Directory) {
          final dirName = entity.path.split('/').last;
          final fullPath = entity.path;
          
          // Verificar si coincide con algún patrón de SD card
          bool isSDCard = patterns.any((pattern) => 
            dirName.toLowerCase().contains(pattern.toLowerCase())
          );
          
          if (isSDCard) {
            // print('🔍 DEBUG: Found potential SD card: $fullPath');
            
            // Agregar subdirectorios comunes
            final subDirs = ['Download', 'Music', 'Documents', 'DCIM', 'Movies', 'Pictures', 'Audio', 'Media'];
            for (String subDir in subDirs) {
              final subPath = '$fullPath/$subDir';
              try {
                if (await Directory(subPath).exists()) {
                  directories.add(subPath);
                  // print('🔍 DEBUG: Added SD card directory: $subPath');
                } else {
                  // Intentar crear el directorio si no existe
                  try {
                    await Directory(subPath).create(recursive: true);
                    directories.add(subPath);
                    // print('🔍 DEBUG: Created and added SD card directory: $subPath');
                  } catch (e) {
                    // print('🔍 DEBUG: Could not create directory $subPath: $e');
                  }
                }
              } catch (e) {
                // print('🔍 DEBUG: Error checking subdirectory $subPath: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      // print('🔍 DEBUG: Error scanning directory $basePath: $e');
    }
  }

  // REFRESCAR URL DE YOUTUBE SI HA EXPIRADO
  static Future<String?> _refreshYouTubeUrl(String url, String videoId) async {
    try {
      // Si la URL contiene parámetros de expiración, intentar obtener una nueva
      if (url.contains('expire=') || url.contains('googlevideo.com')) {
        // print('🔍 DEBUG: Attempting to refresh YouTube URL for video $videoId');
        
        // Aquí podrías implementar la lógica para obtener una nueva URL
        // Por ahora, retornamos la URL original
        return url;
      }
      return url;
    } catch (e) {
      // print('🔍 DEBUG: Error refreshing YouTube URL: $e');
      return url;
    }
  }

  // VERIFICAR CONECTIVIDAD
  static Future<bool> _checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      // print('🔍 DEBUG: Connectivity check failed: $e');
      return false;
    }
  }

  // VERIFICAR INTEGRIDAD DEL ARCHIVO
  static Future<bool> _verifyFileIntegrity(File file) async {
    try {
      if (!await file.exists()) {
        // print('🔍 DEBUG: File does not exist');
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        // print('🔍 DEBUG: File is empty');
        return false;
      }
      
      // Verificar que el archivo tenga un tamaño mínimo razonable (al menos 1KB)
      if (fileSize < 1024) {
        // print('🔍 DEBUG: File too small: $fileSize bytes');
        return false;
      }
      
      // print('🔍 DEBUG: File integrity check passed: ${fileSize} bytes');
      return true;
    } catch (e) {
      // print('🔍 DEBUG: File integrity check error: $e');
      return false;
    }
  }

  // PROCESAR METADATOS DEL MP3 CON PORTADA Y ARCHIVO .LRC
  static Future<void> _processMP3Metadata(File mp3File, String videoId, {String? thumbnailUrl, String? lyrics}) async {
    try {
      final mp3Dir = mp3File.parent;
      final baseName = path.basenameWithoutExtension(mp3File.path);
      
      // print('🔍 DEBUG: Starting metadata processing for: $baseName');
      
      // Descargar portada si está disponible
      if (thumbnailUrl != null) {
        try {
          // print('🔍 DEBUG: Downloading cover image from: $thumbnailUrl');
          final response = await http.get(Uri.parse(thumbnailUrl));
          if (response.statusCode == 200) {
            // Guardar portada como archivo separado
            final coverFile = File('${mp3Dir.path}/$baseName.jpg');
            await coverFile.writeAsBytes(response.bodyBytes);
            // print('🔍 DEBUG: Cover image saved: ${coverFile.path} (${response.bodyBytes.length} bytes)');
          } else {
            // print('🔍 DEBUG: Failed to download cover image: HTTP ${response.statusCode}');
          }
        } catch (e) {
          // print('🔍 DEBUG: Error downloading cover image: $e');
        }
      }

      // Generar y guardar archivo .lrc si hay letras disponibles
      if (lyrics != null && lyrics.isNotEmpty) {
        try {
          // Generar archivo .lrc con timestamps
          final lrcContent = _generateLrcFile(baseName, lyrics);
          final lrcFile = File('${mp3Dir.path}/$baseName.lrc');
          await lrcFile.writeAsString(lrcContent);
          // print('🔍 DEBUG: LRC file saved: ${lrcFile.path} (${lrcContent.length} characters)');
          
          // También guardar archivo .txt como respaldo
          final txtFile = File('${mp3Dir.path}/$baseName.txt');
          await txtFile.writeAsString(lyrics);
          // print('🔍 DEBUG: TXT backup saved: ${txtFile.path} (${lyrics.length} characters)');
        } catch (e) {
          // print('🔍 DEBUG: Error saving lyrics files: $e');
        }
      }
      
      // print('🔍 DEBUG: Metadata processing completed successfully');
      
    } catch (e) {
      // print('🔍 DEBUG: Error in _processMP3Metadata: $e');
      // No rethrow para no fallar la descarga principal
    }
  }
  
  // GENERAR ARCHIVO .LRC CON TIMESTAMPS
  static String _generateLrcFile(String title, String lyrics) {
    final lines = lyrics.split('\n');
    final lrcLines = <String>[];
    
    // Agregar información del archivo
    lrcLines.add('[ti:$title]');
    lrcLines.add('[ar:YouTube Downloader]');
    lrcLines.add('[al:YouTube Downloads]');
    lrcLines.add('[by:YouTube Downloader App]');
    lrcLines.add('');
    
    // Agregar letras con timestamps
    int currentTime = 0; // Tiempo en milisegundos
    const int lineDuration = 3000; // 3 segundos por línea
    
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        final timestamp = _formatLrcTimestamp(currentTime);
        lrcLines.add('[$timestamp]$line');
        currentTime += lineDuration;
      } else {
        lrcLines.add('');
      }
    }
    
    return lrcLines.join('\n');
  }
  
  // FORMATEAR TIMESTAMP PARA ARCHIVO .LRC
  static String _formatLrcTimestamp(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final centiseconds = (milliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }


}
