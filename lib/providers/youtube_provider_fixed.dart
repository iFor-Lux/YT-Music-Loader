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

class YouTubeProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  
  List<YouTubeVideo> _videos = [];
  List<YouTubeVideo> _recommendedVideos = [];
  List<YouTubeVideo> _selectedVideos = [];
  List<DownloadTask> _downloadTasks = [];
  
  String? _error;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;
  Timer? _debounceTimer;

  // Getters
  List<YouTubeVideo> get videos => _videos;
  List<YouTubeVideo> get recommendedVideos => _recommendedVideos;
  List<YouTubeVideo> get selectedVideos => _selectedVideos;
  List<DownloadTask> get downloadTasks => _downloadTasks;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreVideos => _hasMoreVideos;

  YouTubeProvider() {
    _loadRecommendedVideos();
  }

  Future<void> _loadRecommendedVideos() async {
    try {
      _isLoading = true;
      notifyListeners();

      final videos = await _youtubeService.getRecommendedVideos();
      _recommendedVideos = videos;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchVideos(String query) async {
    // Cancelar búsqueda anterior si hay una en curso
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      // IMPORTANTE: NO limpiar _videos cuando la búsqueda está vacía
      // Esto permite que los videos recomendados permanezcan visibles
      _error = null;
      _hasMoreVideos = true;
      notifyListeners();
      return;
    }

    // Debounce de 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final videos = await _youtubeService.searchVideos(query);
      _videos = videos;
      _hasMoreVideos = videos.isNotEmpty && videos.first.nextPageToken != null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos || _videos.isEmpty) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final firstVideo = _videos.first;
      final pageToken = firstVideo.nextPageToken;
      
      if (pageToken != null) {
        final moreVideos = await _youtubeService.searchVideos(
          '', // Query vacío para usar el token de página
          pageToken: pageToken,
        );
        
        _videos.addAll(moreVideos);
        _hasMoreVideos = moreVideos.isNotEmpty && moreVideos.first.nextPageToken != null;
      } else {
        _hasMoreVideos = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void toggleVideoSelection(YouTubeVideo video) {
    print('🔍 DEBUG: toggleVideoSelection called for video: ${video.title}');
    print('🔍 DEBUG: _selectedVideos before: ${_selectedVideos.length}');
    print('🔍 DEBUG: _videos length: ${_videos.length}');
    print('🔍 DEBUG: _recommendedVideos length: ${_recommendedVideos.length}');
    print('🔍 DEBUG: _isLoading: $_isLoading');
    print('🔍 DEBUG: _error: $_error');
    
    final index = _selectedVideos.indexWhere((v) => v.id == video.id);
    if (index != -1) {
      print('🔍 DEBUG: Removing video from selection');
      _selectedVideos.removeAt(index);
    } else {
      print('🔍 DEBUG: Adding video to selection');
      _selectedVideos.add(video);
    }
    
    print('🔍 DEBUG: _selectedVideos after: ${_selectedVideos.length}');
    print('🔍 DEBUG: Calling notifyListeners()');
    notifyListeners();
    print('🔍 DEBUG: notifyListeners() completed');
  }

  void selectAllVideos() {
    final currentVideos = _videos.isNotEmpty ? _videos : _recommendedVideos;
    _selectedVideos = List.from(currentVideos);
    notifyListeners();
  }

  void deselectAllVideos() {
    _selectedVideos.clear();
    notifyListeners();
  }

  void clearSelection() {
    _selectedVideos.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> getAudioUrl(String videoId) async {
    try {
      return await _youtubeService.getAudioUrl(videoId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> downloadVideo(YouTubeVideo video) async {
    // Verificar si ya está en la cola
    if (_downloadTasks.any((task) => task.video.id == video.id)) {
      return;
    }

    // Crear nueva tarea de descarga
    final task = DownloadTask(video: video);
    _downloadTasks.add(task);
    notifyListeners();

    // Iniciar descarga en segundo plano
    _startDownload(task);
  }

  void addSelectedVideosToDownloadQueue() {
    for (final video in _selectedVideos) {
      if (!_downloadTasks.any((task) => task.video.id == video.id)) {
        final task = DownloadTask(video: video);
        _downloadTasks.add(task);
      }
    }
    notifyListeners();
  }

  Future<void> downloadSelectedVideos() async {
    addSelectedVideosToDownloadQueue();
    
    // Iniciar descarga de todas las tareas pendientes
    final pendingTasks = _downloadTasks.where((task) => task.status == DownloadStatus.pending).toList();
    for (final task in pendingTasks) {
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    try {
      task.status = DownloadStatus.downloading;
      task.progress = 0.0;
      task.error = null;
      notifyListeners();

      // Obtener URL de audio
      final audioUrl = await getAudioUrl(task.video.id);
      if (audioUrl == null) {
        task.status = DownloadStatus.failed;
        task.error = 'No se pudo obtener la URL de audio';
        notifyListeners();
        return;
      }

      // Suscribirse al progreso de descarga
      final progressSubscription = DownloadService.getDownloadProgress(task.video.id).listen(
        (progress) {
          task.progress = progress;
          notifyListeners();
        },
      );

      // Realizar descarga
      final success = await DownloadService.downloadAudio(
        audioUrl,
        task.video.title,
        task.video.id,
      );

      progressSubscription.cancel();

      if (success) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
      } else {
        task.status = DownloadStatus.failed;
        task.error = DownloadService.getDownloadError(task.video.id) ?? 'Error desconocido';
      }

      notifyListeners();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryDownload(DownloadTask task) async {
    if (task.status == DownloadStatus.failed || task.status == DownloadStatus.pending) {
      _startDownload(task);
    }
  }

  void clearCompletedTasks() {
    _downloadTasks.removeWhere((task) => 
      task.status == DownloadStatus.completed || task.status == DownloadStatus.failed
    );
    notifyListeners();
  }

  Future<void> loadRecommendedVideos() async {
    await _loadRecommendedVideos();
  }

  void clearCache() {
    _youtubeService.clearCache();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _youtubeService.dispose();
    super.dispose();
  }
}
