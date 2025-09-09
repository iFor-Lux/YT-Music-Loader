class PerformanceConfig {
  // Configuraciones de scroll
  static const double scrollCacheExtent = 500.0;
  static const bool addAutomaticKeepAlives = false;
  static const bool addRepaintBoundaries = true;
  static const bool addSemanticIndexes = false;
  
  // Configuraciones de animaciones
  static const int animationDurationMs = 100; // Reducido de 150
  static const String animationCurve = 'easeOut';
  
  // Configuraciones de BackdropFilter
  static const double backdropBlurSigma = 10.0; // Reducido de 20
  static const double backdropBlurSigmaLight = 5.0; // Para elementos ligeros
  
  // Configuraciones de imágenes
  static const int imageCacheWidth = 140;
  static const int imageCacheHeight = 100;
  static const int imageMemCacheWidth = 140;
  static const int imageMemCacheHeight = 100;
  
  // Configuraciones de lista
  static const int listItemHeight = 100;
  static const double listItemMargin = 6.0;
  
  // Configuraciones de debounce
  static const int searchDebounceMs = 1000;
  
  // Configuraciones de timeout
  static const int apiTimeoutSeconds = 30;
  static const int lyricsTimeoutSeconds = 10;
  
  // Configuraciones de reintentos
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
}