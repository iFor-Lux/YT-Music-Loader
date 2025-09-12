import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  // API key is provided by the user and stored via ApiUsageService
  // Resolve it at runtime instead of hardcoding
  Future<String?> _resolveApiKey() async {
    try {
      final key = await ApiUsageService().getApiKey();
      if (key == null || key.trim().isEmpty) {
        return null;
      }
      return key.trim();
    } catch (_) {
      return null;
    }
  }
  
  Map<String, String> _buildHeaders() {
    return const {
      'Accept': 'application/json',
      'User-Agent': 'YouTubeDownloader/1.0 (Flutter)'
    };
  }

  Map<String, String> _headersWithKey(String apiKey) {
    final headers = _buildHeaders();
    return {
      ...headers,
      // Suministrar también la API key vía header para evitar "unregistered callers"
      'X-Goog-Api-Key': apiKey.trim(),
    };
  }

  String _appendKey(String url, String apiKey) {
    final encoded = Uri.encodeQueryComponent(apiKey.trim());
    return '$url&key=$encoded';
  }
  
  // Cache para mejorar rendimiento
  final Map<String, List<YouTubeVideo>> _searchCache = {};
  final Map<String, Map<String, dynamic>> _videoInfoCache = {};
  
  // Obtener videos recomendados/trending con variedad
  Future<List<YouTubeVideo>> getRecommendedVideos({int maxResults = 20}) async {
    try {
      
      // Lista de categorías populares para variedad (excluyendo shorts)
      final categories = ['music', 'entertainment', 'gaming', 'sports', 'news'];
      final randomCategory = categories[DateTime.now().millisecond % categories.length];
      
      
      
      final apiKey = await _resolveApiKey();
      if (apiKey == null) {
        throw Exception('API key no configurada. Configúrala en Ajustes.');
      }
      final url = _appendKey('$_baseUrl/search?part=snippet&q=$randomCategory&type=video&order=viewCount&videoDuration=medium&maxResults=${maxResults * 3}', apiKey);
      // Debug seguro
      // ignore: avoid_print

      
      // Usar búsqueda por categoría con filtros para excluir shorts
      final response = await http.get(
        Uri.parse(url),
        headers: _headersWithKey(apiKey),
      ).timeout(const Duration(seconds: 15));
      
      // Registrar uso de API siempre (incluso si falla)
      await ApiUsageService().recordUsage('recommended', ApiUsageService.getUnitsForOperation('recommended'));
      
      if (response.statusCode == 200) {
        
        final data = json.decode(response.body);
        final items = data['items'] as List;
        final nextPageToken = data['nextPageToken'];
        
        // Procesar videos directamente sin información adicional para mejor rendimiento
        var videos = items.map((item) {
          final video = YouTubeVideo.fromJson(item);
          
          // Validar que el video tenga un ID válido
          if (video.id.isEmpty) {
            return null;
          }
          
          // Usar información básica de la API sin llamadas adicionales
          return video.copyWith(
            duration: '0:00', // Placeholder
            viewCount: 0, // Placeholder
          );
        }).where((video) => video != null).cast<YouTubeVideo>().toList();
        
        // Agregar el token de la siguiente página al primer video para facilitar la paginación
        if (videos.isNotEmpty && nextPageToken != null) {
          videos.first = videos.first.copyWith(nextPageToken: nextPageToken);
        }
        
        // Filtro adicional: excluir títulos que sugieran Shorts o contenido no deseado
        // Sin filtrado adicional para obtener máximo de resultados
        // videos = videos; // Mantener todos los videos
        
        // Limitar al número solicitado
        if (videos.length > maxResults) {
          videos = videos.take(maxResults).toList();
        }
        
        return videos;
      } else {
        // Log detallado
        // ignore: avoid_print

        // Manejo explícito de errores de API
        if (response.statusCode == 403) {
          try {
            final err = json.decode(response.body);
            final msg = err['error']?['message'] ?? 'Acceso denegado (403)';
            final reason = err['error']?['errors']?[0]?['reason'];
            
            if (reason == 'quotaExceeded') {
              throw Exception('Cuota diaria de API excedida. La cuota se renueva cada 24 horas. Intenta mañana o usa otra API key.');
            } else if (reason == 'forbidden') {
              throw Exception('API key inválida o con restricciones. Verifica en Google Cloud Console.');
            } else {
              throw Exception('API 403 (${reason ?? 'forbidden'}): $msg');
            }
          } catch (e) {
            if (e.toString().contains('Cuota diaria')) {
              rethrow;
            }
            throw Exception('API key inválida o con restricciones (403). Verifica en Google Cloud: API habilitada y sin restricciones de HTTP referrer/Android/iOS.');
          }
        }
        // Si falla por otros motivos, usar método alternativo
        return await _getFallbackVideos(maxResults);
      }
    } catch (e) {
      try {
        return await _getFallbackVideos(maxResults);
      } catch (fallbackError) {
        try {
          return await _getHardcodedVideos(maxResults);
        } catch (hardcodedError) {
          throw Exception('Error de conexión: $e. Fallback también falló: $fallbackError. Hardcoded también falló: $hardcodedError');
        }
      }
    }
  }

  // Método de último recurso: videos hardcodeados
  Future<List<YouTubeVideo>> _getHardcodedVideos(int maxResults) async {
    try {
      
      // Lista de videos de ejemplo para cuando todo falla
      final hardcodedVideos = [
        {
          'id': {'videoId': 'dQw4w9WgXcQ'},
          'snippet': {
            'title': 'Rick Astley - Never Gonna Give You Up',
            'channelTitle': 'Rick Astley',
            'thumbnails': {
              'medium': {'url': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg'}
            },
            'publishedAt': '2009-10-25T06:57:33Z',
          }
        },
        {
          'id': {'videoId': '9bZkp7q19f0'},
          'snippet': {
            'title': 'PSY - GANGNAM STYLE',
            'channelTitle': 'officialpsy',
            'thumbnails': {
              'medium': {'url': 'https://i.ytimg.com/vi/9bZkp7q19f0/mqdefault.jpg'}
            },
            'publishedAt': '2012-07-15T07:46:32Z',
          }
        },
        {
          'id': {'videoId': 'kJQP7kiw5Fk'},
          'snippet': {
            'title': 'Luis Fonsi - Despacito ft. Daddy Yankee',
            'channelTitle': 'Luis Fonsi',
            'thumbnails': {
              'medium': {'url': 'https://i.ytimg.com/vi/kJQP7kiw5Fk/mqdefault.jpg'}
            },
            'publishedAt': '2017-01-12T18:08:02Z',
          }
        },
        {
          'id': {'videoId': 'y6120QOlsfU'},
          'snippet': {
            'title': 'Ed Sheeran - Shape of You',
            'channelTitle': 'Ed Sheeran',
            'thumbnails': {
              'medium': {'url': 'https://i.ytimg.com/vi/y6120QOlsfU/mqdefault.jpg'}
            },
            'publishedAt': '2017-01-30T12:00:00Z',
          }
        },
        {
          'id': {'videoId': 'hT_nvWreIhg'},
          'snippet': {
            'title': 'OneRepublic - Counting Stars',
            'channelTitle': 'OneRepublic',
            'thumbnails': {
              'medium': {'url': 'https://i.ytimg.com/vi/hT_nvWreIhg/mqdefault.jpg'}
            },
            'publishedAt': '2013-03-31T15:00:00Z',
          }
        },
      ];
      
      // Limitar al número solicitado
      final limitedVideos = hardcodedVideos.take(maxResults).toList();
      
      // Crear videos manualmente para evitar problemas con fromJson
      return limitedVideos.map((item) {
        final id = item['id'] as Map<String, dynamic>;
        final snippet = item['snippet'] as Map<String, dynamic>;
        final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
        final medium = thumbnails['medium'] as Map<String, dynamic>;
        
        return YouTubeVideo(
          id: id['videoId'] as String,
          title: snippet['title'] as String,
          channelTitle: snippet['channelTitle'] as String,
          thumbnail: medium['url'] as String,
          duration: 'N/A',
          viewCount: 0,
          publishedAt: snippet['publishedAt'] as String,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error en videos hardcodeados: $e');
    }
  }

  // Método alternativo para obtener videos recomendados
  Future<List<YouTubeVideo>> _getFallbackVideos(int maxResults) async {
    try {
      
      // Usar búsquedas simples que suelen funcionar
      final fallbackQueries = [
        'music',
        'songs',
        'videos',
        'entertainment',
        'gaming',
      ];
      
      final randomQuery = fallbackQueries[DateTime.now().millisecond % fallbackQueries.length];
      
      
      final apiKey = await _resolveApiKey();
      if (apiKey == null) {
        throw Exception('API key no configurada. Configúrala en Ajustes.');
      }
      final url = _appendKey('$_baseUrl/search?part=snippet&q=$randomQuery&type=video&order=relevance&videoDuration=medium&maxResults=$maxResults', apiKey);
      // ignore: avoid_print

      
      final response = await http.get(
        Uri.parse(url),
        headers: _headersWithKey(apiKey),
      ).timeout(const Duration(seconds: 10));

      // Registrar uso de API siempre (incluso si falla)
      await ApiUsageService().recordUsage('fallback', ApiUsageService.getUnitsForOperation('search'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else {
        // ignore: avoid_print

        if (response.statusCode == 403) {
          try {
            final err = json.decode(response.body);
            final msg = err['error']?['message'] ?? 'Acceso denegado (403)';
            final reason = err['error']?['errors']?[0]?['reason'];
            throw Exception('API 403 (${reason ?? 'forbidden'}): $msg');
          } catch (_) {
            throw Exception('API key inválida o con restricciones (403). Verifica en Google Cloud: API habilitada y sin restricciones.');
          }
        }
        throw Exception('Fallback también falló: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en método alternativo: $e');
    }
  }

  Future<List<YouTubeVideo>> searchVideos(String query, {int maxResults = 20, String? pageToken}) async {
    try {
      // Verificar cache para búsquedas sin paginación
      if (pageToken == null && _searchCache.containsKey(query)) {
        return _searchCache[query]!;
      }

      // Usar query original sin filtros para obtener más resultados
      final filteredQuery = query;
      
      final apiKey = await _resolveApiKey();
      if (apiKey == null) {
        throw Exception('API key no configurada. Configúrala en Ajustes.');
      }
      
      // Solicitar exactamente lo que necesitamos para optimizar tokens
      final requestedResults = maxResults; // Solicitar solo lo necesario (20 tokens)
      
      // Excluir Shorts: sin restricción de duración para obtener más resultados
      String url = _appendKey('$_baseUrl/search?part=snippet&q=$filteredQuery&type=video&maxResults=$requestedResults&order=relevance', apiKey);
      if (pageToken != null) {
        url += '&pageToken=$pageToken';
      }
      // ignore: avoid_print



      final response = await http.get(Uri.parse(url), headers: _headersWithKey(apiKey)).timeout(const Duration(seconds: 15));

      // Registrar uso de API siempre (incluso si falla)
      await ApiUsageService().recordUsage('search', ApiUsageService.getUnitsForOperation('search'));

      if (response.statusCode == 200) {
        
        final data = json.decode(response.body);
        final items = data['items'] as List;
        final nextPageToken = data['nextPageToken'];
        
        // ignore: avoid_print

        // Comentado para mejor rendimiento - solo activar si necesitas debug

        
        // Procesar videos directamente sin información adicional para mejor rendimiento
        var videos = items.map((item) {
          final video = YouTubeVideo.fromJson(item);
          
          // Validar que el video tenga un ID válido
          if (video.id.isEmpty) {
            return null;
          }
          
          // Usar información básica de la API sin llamadas adicionales
          return video.copyWith(
            duration: '0:00', // Placeholder
            viewCount: 0, // Placeholder
          );
        }).where((video) => video != null).cast<YouTubeVideo>().toList();
        
        // Filtro adicional: excluir títulos que sugieran Shorts o contenido no deseado
        // Sin filtrado adicional para obtener máximo de resultados
        // videos = videos; // Mantener todos los videos
        
        // Limitar al número solicitado
        if (videos.length > maxResults) {
          videos = videos.take(maxResults).toList();
        }
        
        // Agregar el token de la siguiente página al primer video para facilitar la paginación
        if (videos.isNotEmpty && nextPageToken != null) {
          videos.first = videos.first.copyWith(nextPageToken: nextPageToken);
        }
        
        // ignore: avoid_print

        
        // Guardar en cache solo para búsquedas sin paginación
        if (pageToken == null) {
          _searchCache[query] = videos;
        }
        
        return videos;
      } else {
        // ignore: avoid_print

        if (response.statusCode == 403) {
          try {
            final err = json.decode(response.body);
            final msg = err['error']?['message'] ?? 'Acceso denegado (403)';
            final reason = err['error']?['errors']?[0]?['reason'];
            
            if (reason == 'quotaExceeded') {
              throw Exception('Cuota diaria de API excedida. La cuota se renueva cada 24 horas. Intenta mañana o usa otra API key.');
            } else if (reason == 'forbidden') {
              throw Exception('API key inválida o con restricciones. Verifica en Google Cloud Console.');
            } else {
              throw Exception('API 403 (${reason ?? 'forbidden'}): $msg');
            }
          } catch (e) {
            if (e.toString().contains('Cuota diaria')) {
              rethrow;
            }
            throw Exception('API key inválida o con restricciones (403). Verifica en Google Cloud: API habilitada y sin restricciones adecuadas.');
          }
        }
        throw Exception('Error al buscar videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }


  Future<String?> getAudioUrl(String videoId) async {
    try {
      final yt = YoutubeExplode();
      
      // Intentar obtener el manifest con timeout
      final manifest = await yt.videos.streamsClient.getManifest(videoId)
          .timeout(const Duration(seconds: 30));
      
      // Buscar streams de audio disponibles
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        yt.close();
        return null;
      }
      
      // Priorizar streams de mejor calidad
      StreamInfo? audioStream;
      try {
        audioStream = audioStreams.withHighestBitrate();
      } catch (e) {
        // Si falla, tomar el primero disponible
        audioStream = audioStreams.first;
      }
      
      final url = audioStream.url.toString();
      yt.close();
      
      // Verificar que la URL sea válida
      if (url.isEmpty || !url.startsWith('http')) {
        return null;
      }
      
      return url;
    } catch (e) {

      return null;
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      yt.close();
      return audioStream.url.toString();
    } catch (e) {

      return null;
    }
  }

  Future<String?> getVideoStreamUrl(String videoId) async {
    try {
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final videoStream = manifest.muxed.withHighestBitrate();
      
      yt.close();
      return videoStream.url.toString();
    } catch (e) {

      return null;
    }
  }

  Future<String?> getThumbnailUrl(String videoId) async {
    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(videoId);
      final thumbnailUrl = video.thumbnails.highResUrl;
      
      yt.close();
      return thumbnailUrl;
    } catch (e) {

      return null;
    }
  }

  Future<String?> searchLyrics(String title, String artist) async {
    try {
      // Implementación básica de búsqueda de letras
      // En el futuro, se puede integrar con APIs como Musixmatch o Genius
      
      // Por ahora, retornar letras de ejemplo
      return _generateSampleLyrics(title, artist);
    } catch (e) {

      return null;
    }
  }


  String _generateSampleLyrics(String title, String artist) {
    // Generar letras de ejemplo basadas en el título y artista
    final lines = [
      '[Verse 1]',
      'This is a sample song',
      'With lyrics that are made up',
      'But they sound pretty good',
      '',
      '[Chorus]',
      '$title by $artist',
      'A beautiful melody',
      'That touches the heart',
      '',
      '[Verse 2]',
      'Music brings us together',
      'In ways we never imagined',
      'Creating memories forever',
      '',
      '[Outro]',
      'Thank you for listening',
      'To this sample song',
    ];
    
    return lines.join('\n');
  }

  void clearCache() {
    _searchCache.clear();
    _videoInfoCache.clear();
  }

  Future<void> dispose() async {
    // Limpiar recursos si es necesario
    clearCache();
  }

}
