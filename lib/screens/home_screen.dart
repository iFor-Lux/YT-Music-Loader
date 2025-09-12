import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';
import 'package:youtube_downloader_app/widgets/optimized_video_card.dart';
import 'package:youtube_downloader_app/widgets/glassmorph_card.dart';
import 'package:youtube_downloader_app/widgets/no_bounce_scroll_behavior.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDownloads;
  
  const HomeScreen({super.key, this.onNavigateToDownloads});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchControllerChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchControllerChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final currentPixels = _scrollController.position.pixels;
    final scrollDelta = currentPixels - _lastScrollPosition;
    
    if (scrollDelta > 8 && currentPixels > 60 && _isHeaderVisible) {
      setState(() {
        _isHeaderVisible = false;
      });
    } else if (scrollDelta < -8 && !_isHeaderVisible) {
      setState(() {
        _isHeaderVisible = true;
      });
    }
    
    _lastScrollPosition = currentPixels;
    
    // Cargar más videos al llegar al final
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<YouTubeProvider>();
      if (provider.hasMoreVideos && !provider.isLoadingMore) {
        provider.loadMoreVideos();
      }
    }
  }

  void _onSearchControllerChanged() {
    final query = _searchController.text;
    _onSearchChanged(query);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      context.read<YouTubeProvider>().clearResults();
      return;
    }
    
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      context.read<YouTubeProvider>().searchVideos(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.grey[50],
          body: Container(
            decoration: themeProvider.backgroundImage != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: themeProvider.backgroundImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
            child: SafeArea(
              child: Column(
                children: [
                  // Header simple
                  if (_isHeaderVisible) _buildSimpleHeader(themeProvider),
                  
                  // Barra de búsqueda simple
                  if (_isHeaderVisible) _buildSimpleSearchBar(themeProvider),
                  
                  // Lista de videos
                  Expanded(
                    child: Consumer<YouTubeProvider>(
                      builder: (context, provider, child) {
                        return _buildOptimizedContent(provider, themeProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Consumer<YouTubeProvider>(
            builder: (context, provider, child) {
              if (provider.selectedVideos.isEmpty) return const SizedBox.shrink();
              
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 100, left: 20), // Un poco más arriba
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      provider.downloadSelectedVideos();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${provider.selectedVideos.length} videos agregados a la cola'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'Ver descargas',
                            textColor: Colors.white,
                            onPressed: () {
                              if (widget.onNavigateToDownloads != null) {
                                widget.onNavigateToDownloads!();
                              }
                            },
                          ),
                        ),
                      );
                    },
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.download, size: 24),
                    label: const Text('Descargar'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSimpleHeader(ThemeProvider themeProvider) {
    return GlassmorphHeader(
      isDarkMode: themeProvider.isDarkMode,
      child: Row(
        children: [
          Icon(
            Icons.home,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Inicio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Consumer<YouTubeProvider>(
            builder: (context, provider, child) {
              if (provider.selectedVideos.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.selectedVideos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSearchBar(ThemeProvider themeProvider) {
    return GlassmorphHeader(
      isDarkMode: themeProvider.isDarkMode,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          _debounceTimer?.cancel();
          if (value.trim().isNotEmpty) {
            context.read<YouTubeProvider>().searchVideos(value.trim());
          }
        },
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar videos de YouTube...',
          hintStyle: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: IconButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              context.read<YouTubeProvider>().clearResults();
            },
            icon: Icon(
              Icons.clear,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedContent(YouTubeProvider provider, ThemeProvider themeProvider) {
    if (provider.isLoading && provider.videos.isEmpty && provider.recommendedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.isDarkMode ? Colors.red[400] : Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando videos...',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }
    
    if (provider.isLoading && _searchController.text.trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.isDarkMode ? Colors.blue[400] : Colors.blue[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Buscando "${_searchController.text.trim()}"...',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.error != null && provider.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeProvider.isDarkMode ? Colors.red[300] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!.contains('Cuota diaria') 
                  ? 'Cuota diaria de API excedida.\nLa cuota se renueva cada 24 horas.\nIntenta mañana o usa otra API key.'
                  : 'Error: ${provider.error}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.red[300] : Colors.red[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.clearError(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final videos = provider.videos.isNotEmpty ? provider.videos : provider.recommendedVideos;
    final isSearchResults = provider.videos.isNotEmpty;

    if (videos.isEmpty) {
      return Consumer<ApiUsageService>(
        builder: (context, apiService, child) {
          return FutureBuilder<String?>(
            future: apiService.getApiKey(),
            builder: (context, snapshot) {
              final hasKey = (snapshot.data != null && snapshot.data!.trim().isNotEmpty);
              final title = isSearchResults
                  ? 'No se encontraron videos'
                  : (hasKey ? 'Empieza buscando tu música' : 'Configura tu API de YouTube');
              final subtitle = isSearchResults
                  ? 'Intenta con otro término o más específico'
                  : (hasKey
                      ? 'Escribe en la barra de búsqueda para encontrar videos'
                      : 'Ve a Configuración > API de YouTube y pega tu API Key');

              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur optimizado
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: themeProvider.isDarkMode 
                                ? [
                                    Colors.black.withValues(alpha:0.6),
                                    Colors.black.withValues(alpha:0.4),
                                  ]
                                : [
                                    Colors.white.withValues(alpha:0.7),
                                    Colors.white.withValues(alpha:0.5),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasKey ? Icons.search : Icons.vpn_key,
                              size: 48,
                              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return Column(
      children: [
        _buildSelectionBar(provider, themeProvider),
        Expanded(
          child: _buildOptimizedVideoList(provider, videos, themeProvider),
        ),
      ],
    );
  }

  Widget _buildSelectionBar(YouTubeProvider provider, ThemeProvider themeProvider) {
    return provider.selectedVideos.isNotEmpty
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.selectAllVideos,
                    icon: const Icon(Icons.select_all, size: 22),
                    label: const Text('Seleccionar todo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.deselectAllVideos,
                    icon: const Icon(Icons.clear, size: 22),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeProvider.isDarkMode 
                          ? [
                              Colors.grey[900]!.withValues(alpha: 0.8),
                              Colors.grey[800]!.withValues(alpha: 0.6),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: provider.selectAllVideos,
                    icon: const Icon(Icons.select_all, size: 22),
                    label: const Text('Seleccionar todos los videos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildOptimizedVideoList(YouTubeProvider provider, List<YouTubeVideo> videos, ThemeProvider themeProvider) {
    return NoBounceListViewBuilder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: videos.length + (provider.hasMoreVideos ? 1 : 0),
      cacheExtent: 200,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        if (index == videos.length && provider.hasMoreVideos) {
          return _buildLoadingIndicator(provider, themeProvider);
        }

        final video = videos[index];
        final isSelected = provider.isVideoSelected(video);

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: OptimizedVideoCard(
            key: ValueKey(video.id),
            video: video,
            isSelected: isSelected,
            provider: provider,
          ),
        );
      },
    );
  }

  // Widget separado para el indicador de carga (optimización)
  Widget _buildLoadingIndicator(YouTubeProvider provider, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            if (provider.isLoadingMore)
              CircularProgressIndicator(
                color: themeProvider.isDarkMode ? Colors.red[400] : Colors.red[600],
              )
            else
              Icon(
                Icons.keyboard_arrow_down,
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                size: 24,
              ),
            const SizedBox(height: 8),
            Text(
              provider.isLoadingMore ? 'Cargando más videos...' : 'Desliza para más',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
