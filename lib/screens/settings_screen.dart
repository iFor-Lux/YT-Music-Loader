import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/services/enhanced_download_service.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';
import 'package:youtube_downloader_app/screens/api_metrics_screen.dart';
import 'package:youtube_downloader_app/widgets/glassmorph_card.dart';
import 'package:youtube_downloader_app/widgets/no_bounce_scroll_behavior.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedDirectory;
  bool _isLoading = false;
  bool _downloadWithCover = true;
  bool _downloadWithLyrics = false;
  String _downloadQuality = 'best';
  int _maxConcurrentDownloads = 3;
  bool _autoStartDownloads = true;
  bool _showNotifications = true;
  bool _keepScreenOn = false;

  // API settings
  final TextEditingController _apiKeyController = TextEditingController();
  final ApiUsageService _apiService = ApiUsageService();
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final directory = await EnhancedDownloadService.getDownloadDirectory();
      final withCover = await EnhancedDownloadService.getDownloadWithCover();
      final withLyrics = await EnhancedDownloadService.getDownloadWithLyrics();
      final quality = await EnhancedDownloadService.getDownloadQuality();
      final maxDownloads = await EnhancedDownloadService.getMaxConcurrentDownloads();
      final autoStart = await EnhancedDownloadService.getAutoStartDownloads();
      final notifications = await EnhancedDownloadService.getShowNotifications();
      final keepScreenOn = await EnhancedDownloadService.getKeepScreenOn();

      setState(() {
        _selectedDirectory = directory;
        _downloadWithCover = withCover;
        _downloadWithLyrics = withLyrics;
        _downloadQuality = quality;
        _maxConcurrentDownloads = maxDownloads;
        _autoStartDownloads = autoStart;
        _showNotifications = notifications;
        _keepScreenOn = keepScreenOn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _apiService.getApiKey();
    setState(() {
      _currentApiKey = apiKey;
      _apiKeyController.text = apiKey ?? '';
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isNotEmpty) {
      final candidate = _apiKeyController.text.trim();
      if (!candidate.startsWith('AIza') || candidate.length < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Formato de API Key inválido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _apiService.saveApiKey(candidate);
      setState(() {
        _currentApiKey = candidate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteApiKey() async {
    await _apiService.deleteApiKey();
    setState(() {
      _currentApiKey = null;
      _apiKeyController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key eliminada'), backgroundColor: Colors.red),
      );
    }
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
                  _buildSimpleHeader(themeProvider),

                  // Contenido principal
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildOptimizedContent(themeProvider),
                  ),
                ],
              ),
            ),
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
            Icons.settings,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Configuraciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedContent(ThemeProvider themeProvider) {
    return NoBounceListViewBuilder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: 7,
      cacheExtent: 200,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RepaintBoundary(
            key: ValueKey('settings_card_$index'),
            child: _buildSimpleCard(themeProvider, index),
          ),
        );
      },
    );
  }

  Widget _buildSimpleCard(ThemeProvider themeProvider, int index) {
    switch (index) {
      case 0:
        return _buildAppearanceCard(themeProvider);
      case 1:
        return _buildStorageCard(themeProvider);
      case 2:
        return _buildDownloadCard(themeProvider);
      case 3:
        return _buildPerformanceCard(themeProvider);
      case 4:
        return _buildApiCard(themeProvider);
      case 5:
        return _buildNotificationsCard(themeProvider);
      case 6:
        return _buildInfoCard(themeProvider);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppearanceCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Apariencia',
      Icons.palette,
      [
        SwitchListTile(
          title: Text(
            'Modo Oscuro',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: themeProvider.isDarkMode,
          onChanged: (value) => themeProvider.toggleDarkMode(),
          activeThumbColor: Colors.blue,
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.image,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            'Fondo Personalizado',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            themeProvider.backgroundImage != null
                ? 'Fondo personalizado activo'
                : 'Seleccionar imagen de fondo',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          trailing: themeProvider.backgroundImage != null
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => themeProvider.clearBackgroundImage(),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            if (themeProvider.backgroundImage != null) {
              themeProvider.clearBackgroundImage();
            } else {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );

              if (result != null && result.files.isNotEmpty) {
                final file = File(result.files.first.path!);
                themeProvider.setBackgroundImage(file);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildStorageCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Almacenamiento',
      Icons.storage,
      [
        ListTile(
          leading: Icon(
            Icons.folder,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            'Directorio de Descarga',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _selectedDirectory ?? 'Usando ubicación por defecto',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.refresh,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _loadSettings,
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.folder_open,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            'Cambiar Directorio',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Seleccionar nueva ubicación',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _selectDirectory,
        ),
      ],
    );
  }

  Widget _buildDownloadCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Descarga',
      Icons.music_note,
      [
        SwitchListTile(
          title: Text(
            'Incluir Portada',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Descargar imagen de portada del video',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: _downloadWithCover,
          onChanged: (value) {
            setState(() => _downloadWithCover = value);
            EnhancedDownloadService.setDownloadWithCover(_downloadWithCover);
          },
          activeThumbColor: Colors.blue,
        ),
        const Divider(),
        SwitchListTile(
          title: Text(
            'Incluir Letras',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Descargar letras de la canción si están disponibles',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: _downloadWithLyrics,
          onChanged: (value) {
            setState(() => _downloadWithLyrics = value);
            EnhancedDownloadService.setDownloadWithLyrics(_downloadWithLyrics);
          },
          activeThumbColor: Colors.blue,
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.high_quality,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            'Calidad de Descarga',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _getQualityDisplayName(_downloadQuality),
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showQualityDialog(),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Rendimiento',
      Icons.speed,
      [
        ListTile(
          leading: Icon(
            Icons.download,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          title: Text(
            'Descargas Simultáneas',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Máximo $_maxConcurrentDownloads descargas a la vez',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _maxConcurrentDownloads > 1
                  ? () => _setMaxConcurrentDownloads(_maxConcurrentDownloads - 1)
                  : null,
              icon: Icon(
                Icons.remove,
                color: _maxConcurrentDownloads > 1
                    ? (themeProvider.isDarkMode ? Colors.white : Colors.black)
                    : Colors.grey,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_maxConcurrentDownloads',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            IconButton(
              onPressed: _maxConcurrentDownloads < 5
                  ? () => _setMaxConcurrentDownloads(_maxConcurrentDownloads + 1)
                  : null,
              icon: Icon(
                Icons.add,
                color: _maxConcurrentDownloads < 5
                    ? (themeProvider.isDarkMode ? Colors.white : Colors.black)
                    : Colors.grey,
              ),
            ),
          ],
        ),
        const Divider(),
        SwitchListTile(
          title: Text(
            'Inicio Automático',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Iniciar descargas automáticamente',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: _autoStartDownloads,
          onChanged: (value) {
            setState(() => _autoStartDownloads = value);
            EnhancedDownloadService.setAutoStartDownloads(_autoStartDownloads);
          },
          activeThumbColor: Colors.blue,
        ),
        const Divider(),
        SwitchListTile(
          title: Text(
            'Mantener Pantalla Encendida',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Evitar que la pantalla se apague durante descargas',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: _keepScreenOn,
          onChanged: (value) {
            setState(() => _keepScreenOn = value);
            EnhancedDownloadService.setKeepScreenOn(_keepScreenOn);
          },
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildApiCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'API de YouTube',
      Icons.api,
      [
        Text(
          'API Key de YouTube',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa tu API Key de YouTube Data API v3',
            hintStyle: TextStyle(
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: themeProvider.isDarkMode
                ? Colors.grey[900]?.withValues(alpha: 0.5)
                : Colors.grey[100]?.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: (_apiKeyController.text.isNotEmpty)
                ? IconButton(
                    onPressed: _deleteApiKey,
                    icon: Icon(
                      Icons.close,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _currentApiKey != null ? Icons.check_circle : Icons.error,
              color: _currentApiKey != null ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _currentApiKey != null
                  ? 'API Key configurada correctamente'
                  : 'API Key no configurada',
              style: TextStyle(
                fontSize: 12,
                color: _currentApiKey != null ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveApiKey,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApiMetricsScreen()),
                  );
                },
                icon: const Icon(Icons.analytics, size: 18),
                label: const Text('Métricas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationsCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Notificaciones',
      Icons.notifications,
      [
        SwitchListTile(
          title: Text(
            'Notificaciones',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Recibir notificaciones de descarga',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          value: _showNotifications,
          onChanged: (value) {
            setState(() => _showNotifications = value);
            EnhancedDownloadService.setShowNotifications(_showNotifications);
          },
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      'Información',
      Icons.info,
      [
        _buildInfoRow('Calidad', _getQualityDisplayName(_downloadQuality), themeProvider),
        const Divider(),
        _buildInfoRow('Portada', _downloadWithCover ? 'Incluida' : 'No incluida', themeProvider),
        const Divider(),
        _buildInfoRow('Letras', _downloadWithLyrics ? 'Incluidas' : 'No incluidas', themeProvider),
        const Divider(),
        _buildInfoRow('Descargas simultáneas', '$_maxConcurrentDownloads', themeProvider),
        const Divider(),
        _buildInfoRow('Inicio automático', _autoStartDownloads ? 'Activado' : 'Desactivado', themeProvider),
        const Divider(),
        _buildInfoRow('Notificaciones', _showNotifications ? 'Activadas' : 'Desactivadas', themeProvider),
      ],
    );
  }

  Widget _buildCard(ThemeProvider themeProvider, String title, IconData icon, List<Widget> children) {
    return GlassmorphConfigCard(
      isDarkMode: themeProvider.isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e icono
          Row(
            children: [
              Icon(
                icon,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityDisplayName(String quality) {
    switch (quality) {
      case 'best':
        return 'Mejor calidad';
      case 'high':
        return 'Alta calidad';
      case 'medium':
        return 'Calidad media';
      case 'low':
        return 'Baja calidad';
      default:
        return 'Desconocida';
    }
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Seleccionar Calidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Mejor calidad'),
                value: 'best',
                groupValue: _downloadQuality,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _downloadQuality = value;
                    });
                    _setDownloadQuality(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Alta calidad'),
                value: 'high',
                groupValue: _downloadQuality,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _downloadQuality = value;
                    });
                    _setDownloadQuality(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Calidad media'),
                value: 'medium',
                groupValue: _downloadQuality,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _downloadQuality = value;
                    });
                    _setDownloadQuality(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Baja calidad'),
                value: 'low',
                groupValue: _downloadQuality,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _downloadQuality = value;
                    });
                    _setDownloadQuality(value);
                  }
                },
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
        ),
      ),
    );
  }

  void _setDownloadQuality(String quality) {
    setState(() {
      _downloadQuality = quality;
    });
    EnhancedDownloadService.setDownloadQuality(quality);
    Navigator.of(context).pop();
  }

  void _setMaxConcurrentDownloads(int value) {
    setState(() {
      _maxConcurrentDownloads = value;
    });
    EnhancedDownloadService.setMaxConcurrentDownloads(value);
  }

  void _selectDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      setState(() {
        _selectedDirectory = directory;
      });
      await EnhancedDownloadService.setDownloadDirectory(directory);
    }
  }
}
