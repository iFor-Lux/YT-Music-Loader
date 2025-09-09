import 'dart:collection';
import 'dart:ui' as ui;

class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();
  factory MemoryCacheService() => _instance;
  MemoryCacheService._internal();

  // Cache para imágenes
  final Map<String, ui.Image> _imageCache = {};
  
  // Cache para datos de video
  final Map<String, dynamic> _videoDataCache = {};
  
  // Cache para URLs de audio
  final Map<String, String> _audioUrlCache = {};
  
  // Límites de cache
  static const int maxImageCacheSize = 50;
  static const int maxVideoDataCacheSize = 100;
  static const int maxAudioUrlCacheSize = 200;
  
  // Tiempo de expiración (en milisegundos)
  static const int imageCacheExpiry = 30 * 60 * 1000; // 30 minutos
  static const int videoDataCacheExpiry = 15 * 60 * 1000; // 15 minutos
  static const int audioUrlCacheExpiry = 5 * 60 * 1000; // 5 minutos

  // Cache con timestamp para expiración
  final Map<String, int> _imageCacheTimestamps = {};
  final Map<String, int> _videoDataCacheTimestamps = {};
  final Map<String, int> _audioUrlCacheTimestamps = {};

  // Cache de imágenes
  void cacheImage(String key, ui.Image image) {
    _cleanExpiredImages();
    
    if (_imageCache.length >= maxImageCacheSize) {
      _evictOldestImage();
    }
    
    _imageCache[key] = image;
    _imageCacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
  }

  ui.Image? getCachedImage(String key) {
    if (_imageCacheTimestamps.containsKey(key)) {
      final timestamp = _imageCacheTimestamps[key]!;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > imageCacheExpiry) {
        _imageCache.remove(key);
        _imageCacheTimestamps.remove(key);
        return null;
      }
    }
    
    return _imageCache[key];
  }

  // Cache de datos de video
  void cacheVideoData(String key, dynamic data) {
    _cleanExpiredVideoData();
    
    if (_videoDataCache.length >= maxVideoDataCacheSize) {
      _evictOldestVideoData();
    }
    
    _videoDataCache[key] = data;
    _videoDataCacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
  }

  dynamic getCachedVideoData(String key) {
    if (_videoDataCacheTimestamps.containsKey(key)) {
      final timestamp = _videoDataCacheTimestamps[key]!;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > videoDataCacheExpiry) {
        _videoDataCache.remove(key);
        _videoDataCacheTimestamps.remove(key);
        return null;
      }
    }
    
    return _videoDataCache[key];
  }

  // Cache de URLs de audio
  void cacheAudioUrl(String videoId, String url) {
    _cleanExpiredAudioUrls();
    
    if (_audioUrlCache.length >= maxAudioUrlCacheSize) {
      _evictOldestAudioUrl();
    }
    
    _audioUrlCache[videoId] = url;
    _audioUrlCacheTimestamps[videoId] = DateTime.now().millisecondsSinceEpoch;
  }

  String? getCachedAudioUrl(String videoId) {
    if (_audioUrlCacheTimestamps.containsKey(videoId)) {
      final timestamp = _audioUrlCacheTimestamps[videoId]!;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > audioUrlCacheExpiry) {
        _audioUrlCache.remove(videoId);
        _audioUrlCacheTimestamps.remove(videoId);
        return null;
      }
    }
    
    return _audioUrlCache[videoId];
  }

  // Limpiar cache expirado
  void _cleanExpiredImages() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];
    
    _imageCacheTimestamps.forEach((key, timestamp) {
      if (now - timestamp > imageCacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _imageCache.remove(key);
      _imageCacheTimestamps.remove(key);
    }
  }

  void _cleanExpiredVideoData() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];
    
    _videoDataCacheTimestamps.forEach((key, timestamp) {
      if (now - timestamp > videoDataCacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _videoDataCache.remove(key);
      _videoDataCacheTimestamps.remove(key);
    }
  }

  void _cleanExpiredAudioUrls() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = <String>[];
    
    _audioUrlCacheTimestamps.forEach((key, timestamp) {
      if (now - timestamp > audioUrlCacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _audioUrlCache.remove(key);
      _audioUrlCacheTimestamps.remove(key);
    }
  }

  // Evict elementos más antiguos
  void _evictOldestImage() {
    if (_imageCacheTimestamps.isEmpty) return;
    
    String oldestKey = _imageCacheTimestamps.keys.first;
    int oldestTimestamp = _imageCacheTimestamps[oldestKey]!;
    
    _imageCacheTimestamps.forEach((key, timestamp) {
      if (timestamp < oldestTimestamp) {
        oldestKey = key;
        oldestTimestamp = timestamp;
      }
    });
    
    _imageCache.remove(oldestKey);
    _imageCacheTimestamps.remove(oldestKey);
  }

  void _evictOldestVideoData() {
    if (_videoDataCacheTimestamps.isEmpty) return;
    
    String oldestKey = _videoDataCacheTimestamps.keys.first;
    int oldestTimestamp = _videoDataCacheTimestamps[oldestKey]!;
    
    _videoDataCacheTimestamps.forEach((key, timestamp) {
      if (timestamp < oldestTimestamp) {
        oldestKey = key;
        oldestTimestamp = timestamp;
      }
    });
    
    _videoDataCache.remove(oldestKey);
    _videoDataCacheTimestamps.remove(oldestKey);
  }

  void _evictOldestAudioUrl() {
    if (_audioUrlCacheTimestamps.isEmpty) return;
    
    String oldestKey = _audioUrlCacheTimestamps.keys.first;
    int oldestTimestamp = _audioUrlCacheTimestamps[oldestKey]!;
    
    _audioUrlCacheTimestamps.forEach((key, timestamp) {
      if (timestamp < oldestTimestamp) {
        oldestKey = key;
        oldestTimestamp = timestamp;
      }
    });
    
    _audioUrlCache.remove(oldestKey);
    _audioUrlCacheTimestamps.remove(oldestKey);
  }

  // Limpiar todo el cache
  void clearAllCache() {
    _imageCache.clear();
    _videoDataCache.clear();
    _audioUrlCache.clear();
    _imageCacheTimestamps.clear();
    _videoDataCacheTimestamps.clear();
    _audioUrlCacheTimestamps.clear();
  }

  // Limpiar cache específico
  void clearImageCache() {
    _imageCache.clear();
    _imageCacheTimestamps.clear();
  }

  void clearVideoDataCache() {
    _videoDataCache.clear();
    _videoDataCacheTimestamps.clear();
  }

  void clearAudioUrlCache() {
    _audioUrlCache.clear();
    _audioUrlCacheTimestamps.clear();
  }

  // Obtener estadísticas del cache
  Map<String, int> getCacheStats() {
    return {
      'images': _imageCache.length,
      'videoData': _videoDataCache.length,
      'audioUrls': _audioUrlCache.length,
    };
  }

  // Verificar si el cache está lleno
  bool isImageCacheFull() => _imageCache.length >= maxImageCacheSize;
  bool isVideoDataCacheFull() => _videoDataCache.length >= maxVideoDataCacheSize;
  bool isAudioUrlCacheFull() => _audioUrlCache.length >= maxAudioUrlCacheSize;
}
