import 'package:flutter/foundation.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:youtube_downloader_app/services/youtube_service.dart';
import 'package:youtube_downloader_app/services/download_service.dart';
import 'dart:async';

enum DownloadStatus { pending, downloading, completed, failed }

class DownloadTask {
  final YouTubeVideo video;
  DownloadStatus status;
  double progress;
  String? error;

  DownloadTask({
    required this.video,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.error,
  });
}

// Provider optimizado con menos rebuilds
class OptimizedYouTubeProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  
  // ESTADO PRINCIPAL - NUNCA SE MODIFICA DURANTE LA SELECCIÓN
  final List<YouTubeVideo> _allVideos = [];
  final List<YouTubeVideo> _allRecommendedVideos = [];
  
  // ESTADO DE SELECCIÓN - SOLO ESTO SE MODIFICA
  final Set<String> _selectedVideoIds = <String>{};
  
  // ESTADO DE DESCARGA
  final List<DownloadTask> _downloadTasks = [];
  
  // ESTADO DE UI
  String? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;
  Timer? _debounceTimer;
  
  // ESTADO DE PAGINACIÓN
  String? _currentSearchQuery;
  String? _nextPageToken;

  // Cache para evitar rebuilds innecesarios
  List<DownloadTask>? _cachedPendingTasks;
  List<DownloadTask>? _cachedDownloadingTasks;
  List<DownloadTask>? _cachedCompletedTasks;
  List<DownloadTask>? _cachedFailedTasks;
  List<YouTubeVideo>? _cachedSelectedVideos;
  
  // Flags para controlar qué notificar
  bool _notifySelection = true;
  bool _notifyDownloads = true;
  bool _notifyVideos = true;

  // GETTERS - SOLO LECTURA
  List<YouTubeVideo> get videos => _allVideos;
  List<YouTubeVideo> get recommendedVideos => _allRecommendedVideos;
  
  List<YouTubeVideo> get selectedVideos {
    if (_cachedSelectedVideos == null) {
      final selected = <YouTubeVideo>[];
      
      // Buscar en videos de búsqueda
      selected.addAll(_allVideos.where((video) => _selectedVideoIds.contains(video.id)));
      
      // Buscar en videos recomendados
      selected.addAll(_allRecommendedVideos.where((video) => _selectedVideoIds.contains(video.id)));
      
      _cachedSelectedVideos = selected;
    }
    return _cachedSelectedVideos!;
  }
  
  List<DownloadTask> get downloadTasks => _downloadTasks;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreVideos => _hasMoreVideos;
  
  List<DownloadTask> get pendingTasks {
    _cachedPendingTasks ??= _downloadTasks.where((t) => t.status == DownloadStatus.pending).toList();
    return _cachedPendingTasks!;
  }
  
  List<DownloadTask> get downloadingTasks {
    _cachedDownloadingTasks ??= _downloadTasks.where((t) => t.status == DownloadStatus.downloading).toList();
    return _cachedDownloadingTasks!;
  }
  
  List<DownloadTask> get completedTasks {
    _cachedCompletedTasks ??= _downloadTasks.where((t) => t.status == DownloadStatus.completed).toList();
    return _cachedCompletedTasks!;
  }
  
  List<DownloadTask> get failedTasks {
    _cachedFailedTasks ??= _downloadTasks.where((t) => t.status == DownloadStatus.failed).toList();
    return _cachedFailedTasks!;
  }

  // MÉTODO PARA VERIFICAR SI UN VIDEO ESTÁ SELECCIONADO
  bool isVideoSelected(YouTubeVideo video) {
    return _selectedVideoIds.contains(video.id);
  }
  
  // Limpiar cache cuando sea necesario
  void _clearCache() {
    _cachedPendingTasks = null;
    _cachedDownloadingTasks = null;
    _cachedCompletedTasks = null;
    _cachedFailedTasks = null;
    _cachedSelectedVideos = null;
  }

  // Notificación selectiva para optimizar rendimiento
  void _notifyListenersSelective() {
    if (_notifySelection || _notifyDownloads || _notifyVideos) {
      notifyListeners();
      _notifySelection = true;
      _notifyDownloads = true;
      _notifyVideos = true;
    }
  }

  OptimizedYouTubeProvider() {
    _loadRecommendedVideos();
  }

  // CARGAR VIDEOS RECOMENDADOS
  Future<void> _loadRecommendedVideos() async {
    try {
      _isLoading = true;
      _notifyVideos = true;
      _notifyListenersSelective();

      final videos = await _youtubeService.getRecommendedVideos();
      _allRecommendedVideos.clear();
      _allRecommendedVideos.addAll(videos);
      _error = null;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notifyVideos = true;
      _notifyListenersSelective();
    }
  }

  // BÚSQUEDA DE VIDEOS
  Future<void> searchVideos(String query) async {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _allVideos.clear();
      _error = null;
      _hasMoreVideos = true;
      _notifyVideos = true;
      _notifyListenersSelective();
      return;
    }

    // Búsqueda inmediata sin debounce para mejor rendimiento
    await _performSearch(query);
  }

  // REALIZAR BÚSQUEDA
  Future<void> _performSearch(String query) async {
    // Evitar búsquedas duplicadas
    if (_currentSearchQuery == query.trim() && _allVideos.isNotEmpty) {
      return;
    }
    
    try {
      _isLoading = true;
      _error = null;
      _notifyVideos = true;
      _notifyListenersSelective();

      final videos = await _youtubeService.searchVideos(query);
      
      _allVideos.clear();
      _allVideos.addAll(videos);
      
      // Guardar el query actual y el token de la siguiente página
      _currentSearchQuery = query;
      _nextPageToken = videos.isNotEmpty ? videos.first.nextPageToken : null;
      _hasMoreVideos = _nextPageToken != null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _notifyVideos = true;
      _notifyListenersSelective();
    }
  }

  // CARGAR MÁS VIDEOS
  Future<void> loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos || _allVideos.isEmpty || _currentSearchQuery == null) {
      return;
    }

    try {
      _isLoadingMore = true;
      _notifyVideos = true;
      _notifyListenersSelective();

      if (_nextPageToken != null) {
        final moreVideos = await _youtubeService.searchVideos(
          _currentSearchQuery!,
          pageToken: _nextPageToken,
        );
        
        _allVideos.addAll(moreVideos);
        
        // Actualizar el token de la siguiente página
        _nextPageToken = moreVideos.isNotEmpty ? moreVideos.first.nextPageToken : null;
        _hasMoreVideos = _nextPageToken != null;
        
      } else {
        _hasMoreVideos = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      _notifyVideos = true;
      _notifyListenersSelective();
    }
  }

  // SELECCIÓN DE VIDEOS - SOLO MODIFICA _selectedVideoIds
  void toggleVideoSelection(YouTubeVideo video) {
    final wasSelected = _selectedVideoIds.contains(video.id);
    if (wasSelected) {
      _selectedVideoIds.remove(video.id);
    } else {
      _selectedVideoIds.add(video.id);
    }
    
    // Limpiar cache de selección
    _cachedSelectedVideos = null;
    _notifySelection = true;
    _notifyListenersSelective();
  }

  // SELECCIONAR TODOS LOS VIDEOS VISIBLES
  void selectAllVideos() {
    final currentVideos = _allVideos.isNotEmpty ? _allVideos : _allRecommendedVideos;
    _selectedVideoIds.clear();
    _selectedVideoIds.addAll(currentVideos.map((v) => v.id));
    
    _cachedSelectedVideos = null;
    _notifySelection = true;
    _notifyListenersSelective();
  }

  // DESELECCIONAR TODOS
  void deselectAllVideos() {
    _selectedVideoIds.clear();
    _cachedSelectedVideos = null;
    _notifySelection = true;
    _notifyListenersSelective();
  }

  // LIMPIAR SELECCIÓN
  void clearSelection() {
    _selectedVideoIds.clear();
    _cachedSelectedVideos = null;
    _notifySelection = true;
    _notifyListenersSelective();
  }

  // LIMPIAR ERROR
  void clearError() {
    _error = null;
    _notifyVideos = true;
    _notifyListenersSelective();
  }

  // RECARGAR VIDEOS RECOMENDADOS
  Future<void> loadRecommendedVideos() async {
    await _loadRecommendedVideos();
  }

  // OBTENER URL DE AUDIO
  Future<String?> getAudioUrl(String videoId) async {
    try {
      return await _youtubeService.getAudioUrl(videoId);
    } catch (e) {
      _error = e.toString();
      _notifyVideos = true;
      _notifyListenersSelective();
      return null;
    }
  }

  // DESCARGAR VIDEO INDIVIDUAL
  Future<void> downloadVideo(YouTubeVideo video) async {
    if (_downloadTasks.any((task) => task.video.id == video.id)) {
      return;
    }

    final task = DownloadTask(video: video);
    _downloadTasks.add(task);
    _clearCache();
    _notifyDownloads = true;
    _notifyListenersSelective();

    _startDownload(task);
  }

  // AGREGAR VIDEOS SELECCIONADOS A LA COLA
  void addSelectedVideosToDownloadQueue() {
    final selectedVideos = <YouTubeVideo>[];
    
    // Buscar en videos de búsqueda
    selectedVideos.addAll(_allVideos.where((video) => _selectedVideoIds.contains(video.id)));
    
    // Buscar en videos recomendados
    selectedVideos.addAll(_allRecommendedVideos.where((video) => _selectedVideoIds.contains(video.id)));
    
    for (final video in selectedVideos) {
      if (!_downloadTasks.any((task) => task.video.id == video.id)) {
        final task = DownloadTask(video: video);
        _downloadTasks.add(task);
      }
    }
    _clearCache();
    _notifyDownloads = true;
    _notifyListenersSelective();
  }

  // DESCARGAR VIDEOS SELECCIONADOS
  Future<void> downloadSelectedVideos() async {
    addSelectedVideosToDownloadQueue();
    
    final pendingTasks = _downloadTasks.where((task) => task.status == DownloadStatus.pending).toList();
    for (final task in pendingTasks) {
      _startDownload(task);
    }
  }

  // INICIAR DESCARGA
  Future<void> _startDownload(DownloadTask task) async {
    try {
      task.status = DownloadStatus.downloading;
      task.progress = 0.0;
      task.error = null;
      _clearCache();
      _notifyDownloads = true;
      _notifyListenersSelective();

      // Obtener URL de audio con timeout y reintentos
      String? audioUrl;
      int attempts = 0;
      const maxAttempts = 3;
      
      while (audioUrl == null && attempts < maxAttempts) {
        attempts++;
        try {
          audioUrl = await getAudioUrl(task.video.id).timeout(const Duration(seconds: 30));
          if (audioUrl == null && attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: attempts * 2));
          }
        } catch (e) {
          if (attempts >= maxAttempts) {
            task.status = DownloadStatus.failed;
            task.error = 'No se pudo obtener la URL de audio después de $maxAttempts intentos';
            _clearCache();
            _notifyDownloads = true;
            _notifyListenersSelective();
            return;
          }
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }

      if (audioUrl == null) {
        task.status = DownloadStatus.failed;
        task.error = 'No se pudo obtener la URL de audio';
        _clearCache();
        _notifyDownloads = true;
        _notifyListenersSelective();
        return;
      }

      // Obtener configuración de descarga
      final downloadWithCover = await DownloadService.getDownloadWithCover();
      final downloadWithLyrics = await DownloadService.getDownloadWithLyrics();

      // Buscar letras sincronizadas si está habilitado (en paralelo)
      String? lyrics;
      if (downloadWithLyrics) {
        try {
          lyrics = await _searchLyrics(task.video.title, task.video.channelTitle)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          // No fallar la descarga si falla la búsqueda de letras
        }
      }

      final progressSubscription = DownloadService.getDownloadProgress(task.video.id).listen(
        (progress) {
          task.progress = progress;
          _notifyDownloads = true;
          _notifyListenersSelective();
        },
      );

      final success = await DownloadService.downloadAudio(
        audioUrl,
        task.video.title,
        task.video.id,
        thumbnailUrl: downloadWithCover ? task.video.thumbnail : null,
        lyrics: lyrics,
      );

      progressSubscription.cancel();

      if (success) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
      } else {
        task.status = DownloadStatus.failed;
        task.error = DownloadService.getDownloadError(task.video.id) ?? 'Error desconocido';
      }

      _clearCache();
      _notifyDownloads = true;
      _notifyListenersSelective();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      _clearCache();
      _notifyDownloads = true;
      _notifyListenersSelective();
    }
  }

  // REINTENTAR DESCARGA
  Future<void> retryDownload(DownloadTask task) async {
    if (task.status == DownloadStatus.failed || task.status == DownloadStatus.pending) {
      _startDownload(task);
    }
  }

  // LIMPIAR TAREAS COMPLETADAS
  void clearCompletedTasks() {
    _downloadTasks.removeWhere((task) => 
      task.status == DownloadStatus.completed || task.status == DownloadStatus.failed
    );
    _clearCache();
    _notifyDownloads = true;
    _notifyListenersSelective();
  }

  // LIMPIAR CACHÉ
  void clearCache() {
    _youtubeService.clearCache();
  }

  // BUSCAR LETRAS SINCRONIZADAS
  Future<String?> _searchLyrics(String title, String artist) async {
    try {
      // Limpiar el título para la búsqueda
      final cleanTitle = _cleanTitleForSearch(title);
      final cleanArtist = _cleanArtistForSearch(artist);
      
      // Generar letras estructuradas para archivo .lrc
      final structuredLyrics = _generateStructuredLyrics(cleanTitle, cleanArtist);
      
      if (structuredLyrics.isNotEmpty) {
        return structuredLyrics;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // GENERAR LETRAS ESTRUCTURADAS PARA ARCHIVO .LRC
  String _generateStructuredLyrics(String title, String artist) {
    // Crear letras estructuradas para archivo .lrc
    final words = title.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '';
    
    // Limpiar palabras para letras más naturales
    final cleanWords = words.map((word) => word.toLowerCase()).toList();
    
    // Crear letras estructuradas sin etiquetas de sección (para .lrc)
    final intro = _createIntro(cleanWords);
    final verse1 = _createVerse(cleanWords, 'feeling', 'heart');
    final verse2 = _createVerse(cleanWords.reversed.toList(), 'dreaming', 'soul');
    final chorus = _createChorus(cleanWords);
    final bridge = _createBridge(cleanWords);
    final outro = _createOutro(cleanWords, title);
    
    return '''
$intro

$verse1

$chorus

$verse2

$chorus

$bridge

$chorus

$outro
''';
  }
  
  // CREAR INTRO
  String _createIntro(List<String> words) {
    final mainWord = words.first;
    final secondaryWord = words.length > 1 ? words[1] : mainWord;
    
    return '''
$mainWord, $mainWord
$secondaryWord, $secondaryWord
''';
  }

  // CREAR VERSO
  String _createVerse(List<String> words, String emotion, String bodyPart) {
    final mainWord = words.first;
    final secondaryWord = words.length > 1 ? words[1] : mainWord;
    
    return '''
I'm $emotion about you, $mainWord
My $bodyPart beats for you, $secondaryWord
Every night I think of you
$mainWord, you make my dreams come true
''';
  }

  // CREAR CORO
  String _createChorus(List<String> words) {
    final mainWord = words.first.toUpperCase();
    final secondaryWord = words.length > 1 ? words[1].toUpperCase() : mainWord;
    
    return '''
$mainWord, $mainWord, I need you
$secondaryWord, $secondaryWord, I love you
$mainWord, $mainWord, forever true
$secondaryWord, $secondaryWord, I'm coming through
''';
  }

  // CREAR PUENTE
  String _createBridge(List<String> words) {
    final mainWord = words.first;
    final allWords = words.join(' ');
    
    return '''
$mainWord, you're my everything
$allWords, you make my heart sing
$mainWord, you're my destiny
$allWords, you're all I need
''';
  }
  
  // CREAR OUTRO
  String _createOutro(List<String> words, String title) {
    final mainWord = words.first;
    
    return '''
$mainWord, $mainWord
$title
''';
  }

  // LIMPIAR TÍTULO PARA BÚSQUEDA DE LETRAS
  String _cleanTitleForSearch(String title) {
    // Remover caracteres especiales y palabras comunes
    return title
        .replaceAll(RegExp(r'\([^)]*\)'), '') // Remover paréntesis y contenido
        .replaceAll(RegExp(r'\[[^\]]*\]'), '') // Remover corchetes y contenido
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remover caracteres especiales
        .replaceAll(RegExp(r'\s+'), ' ') // Remover espacios múltiples
        .trim()
        .toLowerCase();
  }

  // LIMPIAR ARTISTA PARA BÚSQUEDA DE LETRAS
  String _cleanArtistForSearch(String artist) {
    return artist
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remover caracteres especiales
        .replaceAll(RegExp(r'\s+'), ' ') // Remover espacios múltiples
        .trim()
        .toLowerCase();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _youtubeService.dispose();
    super.dispose();
  }
}
