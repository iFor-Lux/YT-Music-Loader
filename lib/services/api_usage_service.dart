import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiUsageService extends ChangeNotifier {
  static const String _apiKeyKey = 'youtube_api_key';
  static const String _usageDataKey = 'api_usage_data';
  static const String _dailyUsageKey = 'daily_usage';
  static const String _lastResetDateKey = 'last_reset_date';
  
  // Límites de la API
  static const int _dailyQuotaLimit = 10000;
  static const int _alertThreshold = 8000; // 80%
  
  // Singleton
  static final ApiUsageService _instance = ApiUsageService._internal();
  factory ApiUsageService() => _instance;
  ApiUsageService._internal();
  
  // Contexto global para mostrar alertas
  static BuildContext? _globalContext;
  static void setGlobalContext(BuildContext context) {
    _globalContext = context;
  }

  // Datos de uso diario
  Map<String, int> _dailyUsage = {
    'search': 0,
    'videoDetails': 0,
    'recommended': 0,
    'total': 0,
  };

  // Historial de uso (últimos 30 días)
  List<Map<String, dynamic>> _usageHistory = [];

  // Getters
  Map<String, int> get dailyUsage => Map.from(_dailyUsage);
  List<Map<String, dynamic>> get usageHistory => List.from(_usageHistory);
  int get totalUsage => _dailyUsage['total'] ?? 0;
  int get remainingQuota => _dailyQuotaLimit - totalUsage;
  double get usagePercentage => (totalUsage / _dailyQuotaLimit) * 100;
  bool get isNearLimit => totalUsage >= _alertThreshold;
  bool get isOverLimit => totalUsage >= _dailyQuotaLimit;

  // Inicializar el servicio
  Future<void> initialize() async {
    await _loadUsageData();
    await _checkDailyReset();
  }

  // Guardar API Key
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    notifyListeners(); // Notificar cambios
  }

  // Eliminar API Key
  Future<void> deleteApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    notifyListeners(); // Notificar cambios
  }

  // Obtener API Key
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  // Registrar uso de la API
  Future<void> recordUsage(String operation, int units) async {
    await _checkDailyReset();
    
    _dailyUsage[operation] = (_dailyUsage[operation] ?? 0) + units;
    _dailyUsage['total'] = (_dailyUsage['total'] ?? 0) + units;
    
    // Debug: mostrar el uso registrado
    print('[API Usage] $operation: +$units units, total: ${_dailyUsage['total']}');
    
    await _saveUsageData();
    
    // Verificar si está cerca del límite
    if (isNearLimit && !isOverLimit) {
      print('[API Usage] Near limit: ${_dailyUsage['total']}/$_dailyQuotaLimit');
      _showUsageAlert();
    }
  }

  // Cargar datos de uso
  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cargar uso diario
    final dailyUsageJson = prefs.getString(_dailyUsageKey);
    if (dailyUsageJson != null) {
      _dailyUsage = Map<String, int>.from(json.decode(dailyUsageJson));
    }
    
    // Cargar historial
    final historyJson = prefs.getString(_usageDataKey);
    if (historyJson != null) {
      _usageHistory = List<Map<String, dynamic>>.from(json.decode(historyJson));
    }
  }

  // Guardar datos de uso
  Future<void> _saveUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_dailyUsageKey, json.encode(_dailyUsage));
    await prefs.setString(_usageDataKey, json.encode(_usageHistory));
  }

  // Verificar reset diario
  Future<void> _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastReset = prefs.getString(_lastResetDateKey);
    
    if (lastReset == null) {
      // Primera vez, guardar fecha actual
      await prefs.setString(_lastResetDateKey, now.toIso8601String());
      return;
    }
    
    final lastResetDate = DateTime.parse(lastReset);
    final today = DateTime(now.year, now.month, now.day);
    final lastResetDay = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);
    
    if (today.isAfter(lastResetDay)) {
      // Nuevo día, guardar historial y resetear
      await _saveDailyToHistory();
      _dailyUsage = {
        'search': 0,
        'videoDetails': 0,
        'recommended': 0,
        'total': 0,
      };
      await prefs.setString(_lastResetDateKey, now.toIso8601String());
      await _saveUsageData();
    }
  }

  // Guardar día actual en historial
  Future<void> _saveDailyToHistory() async {
    final today = DateTime.now();
    final dayData = {
      'date': today.toIso8601String(),
      'usage': Map.from(_dailyUsage),
      'percentage': usagePercentage,
    };
    
    _usageHistory.insert(0, dayData);
    
    // Mantener solo últimos 30 días
    if (_usageHistory.length > 30) {
      _usageHistory = _usageHistory.take(30).toList();
    }
  }

  // Mostrar alerta de uso
  void _showUsageAlert() {
    print('⚠️ API Usage Alert: ${usagePercentage.toStringAsFixed(1)}% used');
    
    if (_globalContext != null && _globalContext!.mounted) {
      ScaffoldMessenger.of(_globalContext!).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ API Usage: ${usagePercentage.toStringAsFixed(1)}% used (${_dailyUsage['total']}/$_dailyQuotaLimit)',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ver Métricas',
            textColor: Colors.white,
            onPressed: () {
              // Navegar a métricas si es necesario
            },
          ),
        ),
      );
    }
  }

  // Obtener estadísticas
  Map<String, dynamic> getStatistics() {
    final avgDailyUsage = _usageHistory.isNotEmpty
        ? _usageHistory.map((day) => day['usage']['total'] as int).reduce((a, b) => a + b) / _usageHistory.length
        : 0.0;
    
    final maxDailyUsage = _usageHistory.isNotEmpty
        ? _usageHistory.map((day) => day['usage']['total'] as int).reduce((a, b) => a > b ? a : b)
        : 0;
    
    final daysOver80 = _usageHistory.where((day) => (day['percentage'] as double) >= 80).length;
    
    return {
      'currentUsage': totalUsage,
      'remainingQuota': remainingQuota,
      'usagePercentage': usagePercentage,
      'averageDailyUsage': avgDailyUsage,
      'maxDailyUsage': maxDailyUsage,
      'daysOver80': daysOver80,
      'totalDays': _usageHistory.length,
      'isNearLimit': isNearLimit,
      'isOverLimit': isOverLimit,
    };
  }

  // Reset manual (para testing)
  Future<void> resetUsage() async {
    _dailyUsage = {
      'search': 0,
      'videoDetails': 0,
      'recommended': 0,
      'total': 0,
    };
    await _saveUsageData();
  }

  // Obtener unidades por operación
  static int getUnitsForOperation(String operation) {
    switch (operation) {
      case 'search':
        return 100;
      case 'videoDetails':
        return 1;
      case 'recommended':
        return 1;
      default:
        return 1;
    }
  }
}
