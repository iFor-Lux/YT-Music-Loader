import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/youtube_provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'package:youtube_downloader_app/services/api_usage_service.dart';
import 'package:youtube_downloader_app/services/memory_optimization_service.dart';
import 'package:youtube_downloader_app/screens/home_screen.dart';
import 'package:youtube_downloader_app/screens/download_screen.dart';
import 'package:youtube_downloader_app/screens/settings_screen.dart';
import 'package:youtube_downloader_app/widgets/optimized_background.dart';
import 'dart:ui';

void main() {
  // Optimizaciones de rendimiento
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar modo de debug para mejor rendimiento
  if (kDebugMode) {
    // Reducir logs en debug
    debugPrint = (String? message, {int? wrapWidth}) {
      // Solo imprimir logs importantes
    };
  }
  
  // Inicializar servicio de optimización de memoria
  MemoryOptimizationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => YouTubeProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ApiUsageService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'YouTube Downloader',
            theme: themeProvider.getTheme(),
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
            // Optimizaciones de rendimiento
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0), // Evitar escalado de texto
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Configurar contexto global para alertas de API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiUsageService.setGlobalContext(context);
    });
  }
  
  // Crear las pantallas una sola vez
  late final List<Widget> _screens = [
    HomeScreen(onNavigateToDownloads: () => changeTab(1)),
    const DownloadScreen(),
    const SettingsScreen(),
  ];

  // Método para cambiar de pestaña desde otras pantallas
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // Fondo optimizado
                OptimizedBackground(
                  backgroundImage: themeProvider.backgroundImage,
                  isDarkMode: themeProvider.isDarkMode,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
                // Navbar flotante con glassmorphing optimizado
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur optimizado
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: themeProvider.isDarkMode 
                                ? [
                                    Colors.black.withValues(alpha: 0.6),
                                    Colors.black.withValues(alpha: 0.4),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.7),
                                    Colors.white.withValues(alpha: 0.5),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildNavItem(
                                icon: Icons.home,
                                label: 'Inicio',
                                index: 0,
                                themeProvider: themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                icon: Icons.download,
                                label: 'Descargas',
                                index: 1,
                                themeProvider: themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                icon: Icons.settings,
                                label: 'Configuración',
                                index: 2,
                                themeProvider: themeProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeProvider themeProvider,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? (themeProvider.isDarkMode ? Colors.red[300] : Colors.red[600])
        : (themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700]);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: (themeProvider.isDarkMode ? Colors.red[300] : Colors.red[600])?.withValues(alpha: 0.1),
        highlightColor: (themeProvider.isDarkMode ? Colors.red[300] : Colors.red[600])?.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
