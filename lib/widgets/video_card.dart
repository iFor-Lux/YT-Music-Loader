import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';

class VideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;
  final bool isSelected;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Colors.red.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              // Thumbnail más pequeño
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Duración del video
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Indicador de selección
                  if (isSelected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              // Información del video
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Título del video
                      Text(
                        video.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.red[700] : Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Canal
                      Text(
                        video.channelTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Estadísticas
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatViewCount(video.viewCount),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(video.duration),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Indicador de estado
              if (isSelected)
                Container(
                  width: 4,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(String duration) {
    try {
      // Formato ISO 8601: PT4M13S
      if (duration.startsWith('PT')) {
        final time = duration.substring(2);
        String hours = '';
        String minutes = '';
        String seconds = '';

        if (time.contains('H')) {
          final parts = time.split('H');
          hours = parts[0];
          final remaining = parts[1];
          if (remaining.contains('M')) {
            final minParts = remaining.split('M');
            minutes = minParts[0];
            seconds = minParts[1].replaceAll('S', '');
          } else {
            seconds = remaining.replaceAll('S', '');
          }
        } else if (time.contains('M')) {
          final parts = time.split('M');
          minutes = parts[0];
          seconds = parts[1].replaceAll('S', '');
        } else {
          seconds = time.replaceAll('S', '');
        }

        if (hours.isNotEmpty) {
          return '${hours.padLeft(2, '0')}:${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}';
        } else if (minutes.isNotEmpty) {
          return '${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}';
        } else {
          return '0:${seconds.padLeft(2, '0')}';
        }
      }
      return duration;
    } catch (e) {
      return duration;
    }
  }

  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }
}


