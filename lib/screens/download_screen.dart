import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/widgets/download_item.dart';
import 'package:youtube_downloader_app/models/youtube_video.dart';
import 'package:glass_kit/glass_kit.dart';

class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool _isSelectedVideosExpanded = false;

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
                  _buildHeader(themeProvider),
                  
                  // Contenido principal
                  Expanded(
                    child: Consumer<YouTubeProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          children: [
                            // Información de estado
                            _buildStatusInfo(provider, themeProvider),
                            
                            // Lista de descargas
                            Expanded(
                              child: _buildDownloadList(provider, themeProvider),
                            ),
                            
                            // Botones de acción simplificados
                            _buildActionButtons(provider, themeProvider),
                            
                            // Espacio adicional en la parte inferior para el navbar
                            const SizedBox(height: 100),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur optimizado
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode 
                    ? [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.download, 
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Descargas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusInfo(YouTubeProvider provider, ThemeProvider themeProvider) {
    final pendingTasks = provider.pendingTasks;
    final downloadingTasks = provider.downloadingTasks;
    final completedTasks = provider.completedTasks;
    final failedTasks = provider.failedTasks;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur optimizado
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode 
                    ? [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Título de estadísticas
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.blue[400],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Estadísticas de Descarga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Estadísticas en horizontal
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Pendientes', pendingTasks.length, Colors.orange)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('Descargando', downloadingTasks.length, Colors.blue)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('Completadas', completedTasks.length, Colors.green)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('Fallidas', failedTasks.length, Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                // Lista desplegable de videos seleccionados
                _buildSelectedVideosList(provider, themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedVideosList(YouTubeProvider provider, ThemeProvider themeProvider) {
    if (provider.selectedVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.only(bottom: 4),
        leading: Icon(
          Icons.playlist_play,
          color: Colors.blue[400],
          size: 18,
        ),
        title: Text(
          'Videos Seleccionados (${provider.selectedVideos.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blue[400],
          ),
        ),
        children: [
          SizedBox(
            height: 180, // Aumentada para aprovechar mejor el espacio
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.selectedVideos.length,
              itemBuilder: (context, index) {
                final video = provider.selectedVideos[index];
                return RepaintBoundary(
                  child: _SelectedVideoItem(
                    video: video,
                    themeProvider: themeProvider,
                    onRemove: () => provider.toggleVideoSelection(video),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList(YouTubeProvider provider, ThemeProvider themeProvider) {
    if (provider.downloadTasks.isEmpty) {
      return Center(
        child: Container(
          width: 320,
          height: 120,
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeProvider.isDarkMode 
                        ? [
                            Colors.black.withOpacity(0.6),
                            Colors.black.withOpacity(0.4),
                          ]
                        : [
                            Colors.white.withOpacity(0.7),
                            Colors.white.withOpacity(0.5),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeProvider.isDarkMode 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode 
                            ? Colors.grey.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.download_done,
                        size: 32,
                        color: themeProvider.isDarkMode 
                            ? Colors.grey[300] 
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No hay descargas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode 
                                ? Colors.white 
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Los videos aparecerán aquí',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.isDarkMode 
                                ? Colors.grey[300] 
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: NoGlowBehavior(),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(), // Física más fluida
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Padding bottom para el navbar
        itemCount: provider.downloadTasks.length,
        cacheExtent: 500,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          final task = provider.downloadTasks[index];
          return DownloadItem(task: task);
        },
      ),
    );
  }

  Widget _buildActionButtons(YouTubeProvider provider, ThemeProvider themeProvider) {
    final pendingTasks = provider.downloadTasks.where((t) => t.status == DownloadStatus.pending).toList();
    final failedTasks = provider.downloadTasks.where((t) => t.status == DownloadStatus.failed).toList();
    
    if (pendingTasks.isEmpty && failedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur optimizado
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode 
                    ? [
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.4),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                // Título de acciones
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      color: Colors.green[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Acciones de Descarga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón único para iniciar todas las descargas pendientes
                if (pendingTasks.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.8),
                            Colors.blue[600]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          for (final task in pendingTasks) {
                            provider.retryDownload(task);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Iniciando descarga de ${pendingTasks.length} videos'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 22),
                        label: Text(
                          'Iniciar ${pendingTasks.length} descargas pendientes',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Botón para reintentar fallidas
                if (failedTasks.isNotEmpty)
                  Container(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.8),
                            Colors.orange[600]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          for (final task in failedTasks) {
                            provider.retryDownload(task);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reintentando ${failedTasks.length} descargas fallidas'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 22),
                        label: Text(
                          'Reintentar ${failedTasks.length} descargas fallidas',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget optimizado para items de video seleccionado
class _SelectedVideoItem extends StatelessWidget {
  final YouTubeVideo video;
  final ThemeProvider themeProvider;
  final VoidCallback onRemove;

  const _SelectedVideoItem({
    required this.video,
    required this.themeProvider,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              video.thumbnail,
              width: 45,
              height: 30,
              fit: BoxFit.cover,
              cacheWidth: 90, // Optimización de cache
              cacheHeight: 60,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 45,
                  height: 30,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 18),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  video.channelTitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.red[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
