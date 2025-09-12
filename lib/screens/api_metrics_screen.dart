import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';
import 'package:youtube_downloader_app/widgets/no_bounce_scroll_behavior.dart';
import 'dart:ui';

class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Scroll normal sin rebote
  }
}



class ApiMetricsScreen extends StatefulWidget {
  const ApiMetricsScreen({super.key});

  @override
  State<ApiMetricsScreen> createState() => _ApiMetricsScreenState();
}

class _ApiMetricsScreenState extends State<ApiMetricsScreen> {
  final ApiUsageService _apiService = ApiUsageService();

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
                  
                  // Contenido con scroll controlado - Sin rebote
                  Expanded(
                    child: NoBounceListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      cacheExtent: 200,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      addSemanticIndexes: false,
                      children: [
                        RepaintBoundary(
                          key: const ValueKey('usage_card'),
                          child: _buildUsageCard(themeProvider),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: const ValueKey('statistics_card'),
                          child: _buildStatisticsCard(themeProvider),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: const ValueKey('history_card'),
                          child: _buildHistoryCard(themeProvider),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          key: const ValueKey('info_card'),
                          child: _buildInfoCard(themeProvider),
                        ),
                        const SizedBox(height: 16),
                      ],
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Botón de retroceder
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.white.withValues(alpha:0.1)
                          : Colors.black.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Métricas de API',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                // Indicador de uso actual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _apiService.isNearLimit
                          ? [
                              Colors.orange.withValues(alpha:0.8),
                              Colors.red[600]!,
                            ]
                          : [
                              Colors.green.withValues(alpha:0.8),
                              Colors.green[600]!,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_apiService.isNearLimit ? Colors.orange : Colors.green).withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_apiService.usagePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildUsageCard(ThemeProvider themeProvider) {
    final stats = _apiService.getStatistics();
    final usagePercentage = (stats['usagePercentage'] as num?)?.toDouble() ?? 0.0;
    final currentUsage = (stats['currentUsage'] as num?)?.toInt() ?? 0;
    final remainingQuota = (stats['remainingQuota'] as num?)?.toInt() ?? 0;
    final isNearLimit = stats['isNearLimit'] as bool;
    final isOverLimit = stats['isOverLimit'] as bool;

    return _buildCard(
      themeProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Uso Diario de API',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Barra de progreso simplificada
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '${usagePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(usagePercentage, themeProvider),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: themeProvider.isDarkMode 
                      ? Colors.grey[800] 
                      : Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usagePercentage / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(usagePercentage, themeProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Estadísticas de uso
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Usado',
                  '$currentUsage',
                  Icons.arrow_upward,
                  _getProgressColor(usagePercentage, themeProvider),
                  themeProvider,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Restante',
                  '$remainingQuota',
                  Icons.arrow_downward,
                  Colors.green,
                  themeProvider,
                ),
              ),
            ],
          ),
          
          if (isNearLimit || isOverLimit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverLimit 
                    ? Colors.red.withValues(alpha:0.1)
                    : Colors.orange.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverLimit 
                      ? Colors.red.withValues(alpha:0.3)
                      : Colors.orange.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverLimit ? Icons.error : Icons.warning,
                    color: isOverLimit ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOverLimit 
                          ? 'Límite diario excedido. Las búsquedas están deshabilitadas.'
                          : 'Cerca del límite diario (80%). Considera reducir el uso.',
                      style: TextStyle(
                        color: isOverLimit ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(ThemeProvider themeProvider, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? Colors.grey[900]?.withValues(alpha:0.5)
            : Colors.grey[100]?.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(ThemeProvider themeProvider) {
    final stats = _apiService.getStatistics();
    final avgDailyUsage = (stats['averageDailyUsage'] as num?)?.toDouble() ?? 0.0;
    final maxDailyUsage = (stats['maxDailyUsage'] as num?)?.toInt() ?? 0;
    final daysOver80 = (stats['daysOver80'] as num?)?.toInt() ?? 0;
    final totalDays = (stats['totalDays'] as num?)?.toInt() ?? 0;

    return _buildCard(
      themeProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Promedio Diario',
                  avgDailyUsage.toStringAsFixed(0),
                  Icons.analytics,
                  Colors.blue,
                  themeProvider,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Máximo Diario',
                  '$maxDailyUsage',
                  Icons.arrow_upward,
                  Colors.red,
                  themeProvider,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Días > 80%',
                  '$daysOver80',
                  Icons.warning,
                  Colors.orange,
                  themeProvider,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Días',
                  '$totalDays',
                  Icons.calendar_today,
                  Colors.green,
                  themeProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ThemeProvider themeProvider) {
    final history = _apiService.usageHistory.take(7).toList(); // Últimos 7 días

    return _buildCard(
      themeProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Historial (Últimos 7 días)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (history.isEmpty)
            Center(
              child: Text(
                'No hay datos de historial',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          else
            ...history.map((day) => _buildHistoryItem(day, themeProvider)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> day, ThemeProvider themeProvider) {
    final date = DateTime.parse(day['date']);
    final usage = Map<String, int>.from(day['usage'] ?? {});
    final percentage = (day['percentage'] as num?)?.toDouble() ?? 0.0;
    final totalUsage = usage['total'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
            ? Colors.grey[900]?.withValues(alpha:0.5)
            : Colors.grey[100]?.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Búsquedas: ${usage['search'] ?? 0} | Videos: ${usage['videoDetails'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalUsage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getProgressColor(percentage, themeProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeProvider themeProvider) {
    return _buildCard(
      themeProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Información',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoItem('Límite diario', '10,000 unidades', themeProvider),
          _buildInfoItem('Búsqueda', '100 unidades', themeProvider),
          _buildInfoItem('Detalles de video', '1 unidad', themeProvider),
          _buildInfoItem('Videos recomendados', '1 unidad', themeProvider),
          _buildInfoItem('Renovación', 'Cada 24 horas', themeProvider),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage, ThemeProvider themeProvider) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    if (percentage >= 60) return Colors.yellow[700]!;
    return Colors.green;
  }
}
