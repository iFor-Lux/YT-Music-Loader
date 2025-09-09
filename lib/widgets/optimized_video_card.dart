import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';

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
          return GestureDetector(
            onTap: () => provider.toggleVideoSelection(video),
            child: Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: themeProvider.isDarkMode 
                    ? Colors.grey[900]?.withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                border: Border.all(
                  color: isSelected 
                      ? Colors.red.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Thumbnail optimizado
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbnail,
                        width: 70,
                        height: 50,
                        fit: BoxFit.cover,
                        memCacheWidth: 140, // Optimización de memoria
                        memCacheHeight: 100,
                        placeholder: (context, url) => Container(
                          width: 70,
                          height: 50,
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 70,
                          height: 50,
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                          child: Icon(
                            Icons.image, 
                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500], 
                            size: 16,
                          ),
                        ),
                      ),
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
                    
                    // Indicador de selección
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
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
        },
      ),
    );
  }
}