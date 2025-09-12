/// Configuración de rendimiento para la aplicación
class PerformanceConfig {
  // Configuración de ListView
  static const int defaultCacheExtent = 200;
  static const int reducedCacheExtent = 150;
  static const int minimalCacheExtent = 100;
  
  // Configuración de imágenes
  static const int defaultImageCacheSize = 100;
  static const int lowMemoryImageCacheSize = 50;
  static const int minimalImageCacheSize = 25;
  
  // Configuración de glassmorphing
  static const double defaultBlurSigma = 8.0;
  static const double reducedBlurSigma = 6.0;
  static const double minimalBlurSigma = 4.0;
  
  // Configuración de animaciones
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration minimalAnimationDuration = Duration(milliseconds: 150);
  
  // Configuración de memoria
  static const int memoryCleanupIntervalMinutes = 2;
  static const int performanceMonitorIntervalSeconds = 30;
  static const double lowMemoryThreshold = 0.8;
  
  // Configuración de scroll
  static const bool enableScrollPhysics = true;
  static const bool enableRepaintBoundaries = true;
  static const bool enableAutomaticKeepAlives = false;
  static const bool enableSemanticIndexes = false;
}