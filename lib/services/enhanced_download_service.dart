import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:youtube_downloader_app/services/permission_service.dart';

class EnhancedDownloadService {
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
    
    if (remainingMs.isInfinite || remainingMs.isNaN) return '';
    
    final remainingSeconds = (remainingMs / 1000).round();
    if (remainingSeconds < 60) {
      return '${remainingSeconds}s';
    } else if (remainingSeconds < 3600) {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = remainingSeconds ~/ 3600;
      final minutes = (remainingSeconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  // Obtener velocidad de descarga
  static String getDownloadSpeed(String videoId) {
    final startTime = _downloadStartTime[videoId];
    final currentBytes = _downloadCurrentBytes[videoId];
    
    if (startTime == null || currentBytes == null || currentBytes == 0) return '';
    
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    if (elapsed == 0) return '';
    
    final bytesPerMs = currentBytes / elapsed;
    final bytesPerSecond = bytesPerMs * 1000;
    
    return '${_formatFileSize(bytesPerSecond.round())}/s';
  }

  // Obtener tamaño total del archivo
  static String getTotalFileSize(String videoId) {
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
    try {
      
      // Solicitar permisos de almacenamiento de forma inteligente
      final storageGranted = await PermissionService.requestStoragePermissions();
      
      if (!storageGranted) {
        return false;
      }
      
      // Solicitar permisos de notificaciones (opcional)
      await PermissionService.requestNotificationPermissions();
      
      return storageGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getDownloadDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('download_path');
      
      if (customPath != null && await Directory(customPath).exists()) {
        final youtubeDir = Directory('$customPath/Luxury Music');
        if (!await youtubeDir.exists()) {
          await youtubeDir.create(recursive: true);
        }
        return youtubeDir.path;
      }

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadsDir = Directory('${externalDir.path}/Download/Luxury Music');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir.path;
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/Luxury Music');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir.path;
    } catch (e) {
      // ignore: empty_catches
    }
    return null;
  }

  static Future<void> setDownloadDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_path', path);
  }

  // Obtener la ubicación actual de descarga para mostrar al usuario
  static Future<String> getCurrentDownloadPath() async {
    final directory = await getDownloadDirectory();
    return directory ?? 'No configurado';
  }

  static Future<String?> selectDirectoryManually() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar carpeta de descarga',
        initialDirectory: '/storage',
      );
      
      if (result != null) {
        final youtubeDir = Directory('$result/Luxury Music');
        if (!await youtubeDir.exists()) {
          await youtubeDir.create(recursive: true);
        }
        await setDownloadDirectory(result);
        return youtubeDir.path;
      }
    } catch (e) {
      // ignore: empty_catches
    }
    return null;
  }

  // Obtener preferencia de portada
  static Future<bool> getDownloadWithCover() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('download_with_cover') ?? true;
  }

  // Establecer preferencia de portada
  static Future<void> setDownloadWithCover(bool withCover) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('download_with_cover', withCover);
  }

  // Obtener preferencia de letras
  static Future<bool> getDownloadWithLyrics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('download_with_lyrics') ?? false;
  }

  // Establecer preferencia de letras
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

  // DESCARGA MEJORADA DE AUDIO
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
      
      // Verificar permisos existentes primero
      final hasExistingPermission = await PermissionService.hasStoragePermissions();
      if (!hasExistingPermission) {
        
        // Solicitar permisos
        final hasPermission = await requestPermissions();
        if (!hasPermission) {
          // Verificar si los permisos están permanentemente denegados
          final permanentlyDenied = await PermissionService.arePermissionsPermanentlyDenied();
          if (permanentlyDenied) {
            _downloadErrors[videoId] = 'Permisos de almacenamiento permanentemente denegados. Ve a Configuración > Aplicaciones > YouTube Downloader > Permisos y activa "Almacenamiento".';
          } else {
            _downloadErrors[videoId] = 'Permisos de almacenamiento denegados. Intenta de nuevo.';
          }
          _downloadStatus[videoId] = false;
          return false;
        }
      } else {
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
        int counter = 1;
        String newFilePath = filePath;
        while (await File(newFilePath).exists()) {
          final nameWithoutExt = safeFileName;
          newFilePath = '$downloadDir/$nameWithoutExt $counter.mp3';
          counter++;
        }
        final file = File(newFilePath);
        
        // Realizar la descarga con progreso optimizado
        final success = await _performEnhancedDownload(file, url, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);
        return success;
      } else {
        final file = File(filePath);
        final success = await _performEnhancedDownload(file, url, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);
        return success;
      }
    } catch (e) {
      _downloadErrors[videoId] = 'Error: $e';
      _downloadStatus[videoId] = false;
      return false;
    }
  }

  static Future<bool> _performEnhancedDownload(File file, String url, String videoId, {String? thumbnailUrl, String? lyrics}) async {
    const int maxRetries = 5; // Más reintentos
    const Duration timeout = Duration(minutes: 10); // Timeout más largo
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        
        final client = http.Client();
        final request = http.Request('GET', Uri.parse(url));
        
        // Headers optimizados para mejor compatibilidad
        request.headers.addAll({
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Accept-Language': 'en-US,en;q=0.9,es;q=0.8',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Range': 'bytes=0-', // Permitir descarga por partes
        });
        
        final response = await client.send(request).timeout(timeout);

        if (response.statusCode == 200 || response.statusCode == 206) {
          final sink = file.openWrite();
          int downloaded = 0;
          final total = response.contentLength ?? 0;
          _downloadTotalBytes[videoId] = total;
          final stopwatch = Stopwatch()..start();

          await for (final chunk in response.stream) {
            sink.add(chunk);
            downloaded += chunk.length;
            _downloadCurrentBytes[videoId] = downloaded;
            
            // Actualizar progreso cada 25KB o cada 250ms para mejor responsividad
            if (total > 0 && (downloaded % 25600 == 0 || stopwatch.elapsed.inMilliseconds >= 250)) {
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

            
            // Procesar metadatos después de descarga exitosa
            if (thumbnailUrl != null || lyrics != null) {
              try {
                await _processMP3Metadata(file, videoId, thumbnailUrl: thumbnailUrl, lyrics: lyrics);

              } catch (e) {

                // No fallar la descarga si falla el procesamiento de metadatos
              }
            }
            
            return true;
          } else {

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

          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          _downloadErrors[videoId] = 'Error HTTP: ${response.statusCode} después de $maxRetries intentos';
          _downloadStatus[videoId] = false;
          return false;
        }
      } catch (e) {

        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        _downloadErrors[videoId] = 'Error después de $maxRetries intentos: $e';
        _downloadStatus[videoId] = false;
        return false;
      }
    }
    
    return false;
  }

  static Future<bool> _verifyFileIntegrity(File file) async {
    try {
      if (!await file.exists()) {

        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {

        return false;
      }
      
      // Verificar que el archivo tenga un tamaño mínimo razonable (al menos 10KB)
      if (fileSize < 10240) {

        return false;
      }
      

      return true;
    } catch (e) {

      return false;
    }
  }

  static Future<void> _processMP3Metadata(File mp3File, String videoId, {String? thumbnailUrl, String? lyrics}) async {
    try {
      final mp3Dir = mp3File.parent;
      final baseName = path.basenameWithoutExtension(mp3File.path);
      

      
      // Descargar portada si está disponible
      if (thumbnailUrl != null) {
        try {

          final response = await http.get(Uri.parse(thumbnailUrl));
          if (response.statusCode == 200) {
            // Guardar portada como archivo separado
            final coverFile = File('${mp3Dir.path}/$baseName.jpg');
            await coverFile.writeAsBytes(response.bodyBytes);

          } else {
            // ignore: empty_catches
          }
        } catch (e) {
          // ignore: empty_catches
        }
      }

      // Generar y guardar archivo .lrc si hay letras disponibles
      if (lyrics != null && lyrics.isNotEmpty) {
        try {
          // Generar archivo .lrc con timestamps
          final lrcContent = _generateLrcFile(baseName, lyrics);
          final lrcFile = File('${mp3Dir.path}/$baseName.lrc');
          await lrcFile.writeAsString(lrcContent);

        } catch (e) {
          // ignore: empty_catches
        }
      }
      

    } catch (e) {

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
  
  static String _formatLrcTimestamp(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final ms = milliseconds % 1000;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
  }

  static String _createSafeFileName(String fileName) {
    // Remover caracteres no válidos para nombres de archivo
    final safeName = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Limitar longitud
    if (safeName.length > 100) {
      return safeName.substring(0, 100);
    }
    
    return safeName;
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
