import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/services/memory_optimization_service.dart';

class OptimizedVideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final bool isSelected;
  final YouTubeProvider provider;

  const OptimizedVideoCard({
    super.key,
    required this.video,
    required this.isSelected,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return _VideoCardContent(
            video: video,
            isSelected: isSelected,
            themeProvider: themeProvider,
            onTap: () => provider.toggleVideoSelection(video),
          );
        },
      ),
    );
  }
}

// Widget separado para el contenido del card (optimización de reconstrucción)
class _VideoCardContent extends StatelessWidget {
  final YouTubeVideo video;
  final bool isSelected;
  final ThemeProvider themeProvider;
  final VoidCallback onTap;

  const _VideoCardContent({
    required this.video,
    required this.isSelected,
    required this.themeProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: themeProvider.isDarkMode 
              ? Colors.grey[900]?.withValues(alpha:0.8)
              : Colors.white.withValues(alpha:0.9),
          border: Border.all(
            color: isSelected 
                ? Colors.red.withValues(alpha:0.6)
                : Colors.grey.withValues(alpha:0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Thumbnail optimizado con mejor cache
              _OptimizedThumbnail(
                imageUrl: video.thumbnail,
                isDarkMode: themeProvider.isDarkMode,
              ),
              const SizedBox(width: 12),
              
              // Información del video
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        video.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              
              // Indicador de selección optimizado
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget optimizado para thumbnails
class _OptimizedThumbnail extends StatelessWidget {
  final String imageUrl;
  final bool isDarkMode;

  const _OptimizedThumbnail({
    required this.imageUrl,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Registrar imagen en cache de memoria
    MemoryOptimizationService().registerImage(imageUrl);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 70,
        height: 50,
        fit: BoxFit.cover,
        // Optimizaciones de memoria mejoradas
        memCacheWidth: 140,
        memCacheHeight: 100,
        maxWidthDiskCache: 280,
        maxHeightDiskCache: 200,
        // Configuración de placeholder optimizada
        placeholder: (context, url) => Container(
          width: 70,
          height: 50,
          color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        // Widget de error optimizado
        errorWidget: (context, url, error) => Container(
          width: 70,
          height: 50,
          color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          child: Icon(
            Icons.image, 
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500], 
            size: 16,
          ),
        ),
      ),
    );
  }
}