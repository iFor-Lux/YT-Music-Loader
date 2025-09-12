import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Servicio para optimización de memoria y rendimiento
class MemoryOptimizationService {
  static final MemoryOptimizationService _instance = MemoryOptimizationService._internal();
  factory MemoryOptimizationService() => _instance;
  MemoryOptimizationService._internal();

  Timer? _memoryCleanupTimer;
  Timer? _performanceMonitorTimer;
  int _maxImageCacheSize = 100; // Máximo 100 imágenes en cache
  final List<String> _cachedImages = [];
  bool _isLowMemory = false;

  /// Inicializar el servicio de optimización
  void initialize() {
    _startMemoryCleanup();
    _startPerformanceMonitoring();
    _setupMemoryWarningListener();
  }

  /// Configurar listener de advertencias de memoria
  void _setupMemoryWarningListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == 'AppLifecycleState.paused') {
        _cleanupMemory();
      } else if (message == 'AppLifecycleState.resumed') {
        _resumeOptimization();
      }
      return null;
    });
  }

  /// Iniciar limpieza automática de memoria
  void _startMemoryCleanup() {
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _cleanupMemory();
    });
  }

  /// Iniciar monitoreo de rendimiento
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _monitorPerformance();
    });
  }

  /// Limpiar memoria
  void _cleanupMemory() {
    if (kDebugMode) {

    }
    
    // Limpiar cache de imágenes si excede el límite
    if (_cachedImages.length > _maxImageCacheSize) {
      final imagesToRemove = _cachedImages.take(_cachedImages.length - _maxImageCacheSize).toList();
      for (final imageUrl in imagesToRemove) {
        _cachedImages.remove(imageUrl);
      }
    }

    // Forzar garbage collection
    if (kDebugMode) {

    }
  }

  /// Monitorear rendimiento
  void _monitorPerformance() {
    // Verificar si hay problemas de memoria
    _checkMemoryStatus();
    
    // Optimizar cache si es necesario
    _optimizeCache();
  }

  /// Verificar estado de memoria
  void _checkMemoryStatus() {
    // Simular verificación de memoria (en una app real usarías platform channels)
    _isLowMemory = _cachedImages.length > _maxImageCacheSize * 0.8;
    
    if (_isLowMemory && kDebugMode) {

    }
  }

  /// Optimizar cache
  void _optimizeCache() {
    if (_isLowMemory) {
      // Reducir tamaño de cache
      _maxImageCacheSize = (_maxImageCacheSize * 0.7).round();
      
      // Limpiar cache inmediatamente
      _cleanupMemory();
    }
  }

  /// Reanudar optimización
  void _resumeOptimization() {
    if (kDebugMode) {

    }
    
    // Restaurar tamaño de cache
    _maxImageCacheSize = 100;
    _isLowMemory = false;
  }

  /// Registrar imagen en cache
  void registerImage(String imageUrl) {
    if (!_cachedImages.contains(imageUrl)) {
      _cachedImages.add(imageUrl);
    }
  }

  /// Verificar si una imagen está en cache
  bool isImageCached(String imageUrl) {
    return _cachedImages.contains(imageUrl);
  }

  /// Obtener estadísticas de memoria
  Map<String, dynamic> getMemoryStats() {
    return {
      'cachedImages': _cachedImages.length,
      'maxCacheSize': _maxImageCacheSize,
      'isLowMemory': _isLowMemory,
      'cacheUtilization': (_cachedImages.length / _maxImageCacheSize * 100).round(),
    };
  }

  /// Limpiar cache específico
  void clearImageCache() {
    _cachedImages.clear();
    if (kDebugMode) {

    }
  }

  /// Optimizar para dispositivos de baja memoria
  void optimizeForLowMemory() {
    _maxImageCacheSize = 50;
    _cleanupMemory();
    if (kDebugMode) {

    }
  }

  /// Restaurar configuración normal
  void restoreNormalSettings() {
    _maxImageCacheSize = 100;
    _isLowMemory = false;
    if (kDebugMode) {

    }
  }

  /// Verificar si el dispositivo tiene poca memoria
  bool get isLowMemory => _isLowMemory;

  /// Obtener tamaño actual del cache
  int get currentCacheSize => _cachedImages.length;

  /// Obtener tamaño máximo del cache
  int get maxCacheSize => _maxImageCacheSize;

  /// Disposed del servicio
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _performanceMonitorTimer?.cancel();
    _cachedImages.clear();
  }
}

/// Mixin para widgets que necesitan optimización de memoria
mixin MemoryOptimizedMixin<T extends StatefulWidget> on State<T> {
  late MemoryOptimizationService _memoryService;

  @override
  void initState() {
    super.initState();
    _memoryService = MemoryOptimizationService();
  }

  @override
  void dispose() {
    _memoryService.dispose();
    super.dispose();
  }

  /// Registrar imagen en cache
  void registerImage(String imageUrl) {
    _memoryService.registerImage(imageUrl);
  }

  /// Verificar si una imagen está en cache
  bool isImageCached(String imageUrl) {
    return _memoryService.isImageCached(imageUrl);
  }

  /// Obtener estadísticas de memoria
  Map<String, dynamic> getMemoryStats() {
    return _memoryService.getMemoryStats();
  }
}

/// Widget optimizado para memoria
class MemoryOptimizedWidget extends StatefulWidget {
  final Widget child;
  final bool enableMemoryOptimization;
  final int? maxCacheSize;

  const MemoryOptimizedWidget({
    super.key,
    required this.child,
    this.enableMemoryOptimization = true,
    this.maxCacheSize,
  });

  @override
  State<MemoryOptimizedWidget> createState() => _MemoryOptimizedWidgetState();
}

class _MemoryOptimizedWidgetState extends State<MemoryOptimizedWidget>
    with MemoryOptimizedMixin {
  @override
  void initState() {
    super.initState();
    if (widget.enableMemoryOptimization) {
      _memoryService.initialize();
      if (widget.maxCacheSize != null) {
        _memoryService._maxImageCacheSize = widget.maxCacheSize!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
