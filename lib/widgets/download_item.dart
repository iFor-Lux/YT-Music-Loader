import 'package:flutter/material.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/services/download_service.dart';

class DownloadItem extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onRetry;

  const DownloadItem({
    super.key,
    required this.task,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.video.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Información del canal
            Text(
              task.video.channelTitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Progreso y información de descarga
            if (task.status == DownloadStatus.downloading) ...[
              _buildProgressInfo(),
            ] else if (task.status == DownloadStatus.completed) ...[
              _buildCompletedInfo(),
            ] else if (task.status == DownloadStatus.failed) ...[
              _buildErrorInfo(),
            ],
            
            // Botón de acción
            if (task.status == DownloadStatus.failed && onRetry != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    IconData icon;
    String text;

    switch (task.status) {
      case DownloadStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        text = 'Pendiente';
        break;
      case DownloadStatus.downloading:
        color = Colors.blue;
        icon = Icons.download;
        text = 'Descargando';
        break;
      case DownloadStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Completado';
        break;
      case DownloadStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        text = 'Fallido';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo() {
    final progress = (task.progress * 100).toInt();
    final timeRemaining = DownloadService.getEstimatedTimeRemaining(task.video.id);
    final progressFormatted = DownloadService.getProgressFormatted(task.video.id);

    return Column(
      children: [
        // Barra de progreso
        LinearProgressIndicator(
          value: task.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
        ),
        
        const SizedBox(height: 8),
        
        // Información de progreso
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$progress%',
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (progressFormatted.isNotEmpty)
              Text(
                progressFormatted,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        
        if (timeRemaining.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.timer, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Tiempo restante: $timeRemaining',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Descarga completada exitosamente',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error en la descarga',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (task.error != null) ...[
            const SizedBox(height: 4),
            Text(
              task.error!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
