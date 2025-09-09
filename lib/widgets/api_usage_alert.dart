import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';
import 'dart:ui';

class ApiUsageAlert extends StatefulWidget {
  const ApiUsageAlert({super.key});

  @override
  State<ApiUsageAlert> createState() => _ApiUsageAlertState();
}

class _ApiUsageAlertState extends State<ApiUsageAlert> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final ApiUsageService _apiService = ApiUsageService();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _checkUsageAndShowAlert();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkUsageAndShowAlert() {
    if (_apiService.isNearLimit && !_apiService.isOverLimit) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
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
                            colors: [
                              Colors.orange.withOpacity(0.9),
                              Colors.red.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icono de alerta
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.warning,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Título
                              Text(
                                'Alerta de Uso de API',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Mensaje
                              Text(
                                'Has alcanzado el ${_apiService.usagePercentage.toStringAsFixed(1)}% de tu límite diario de API.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Barra de progreso
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _apiService.usagePercentage / 100,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Estadísticas
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'Usado',
                                    '${_apiService.totalUsage}',
                                    Colors.white,
                                  ),
                                  _buildStatItem(
                                    'Restante',
                                    '${_apiService.remainingQuota}',
                                    Colors.white.withOpacity(0.8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isVisible = false;
                                        });
                                        _animationController.reverse();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Entendido'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Navegar a métricas
                                        Navigator.pushNamed(context, '/api-metrics');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.orange[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Ver Métricas'),
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

