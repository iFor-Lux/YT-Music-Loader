import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader_app/providers/theme_provider.dart';
import 'dart:ui';

class OptimizedSettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool useBackdropFilter;

  const OptimizedSettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.useBackdropFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        Widget cardContent = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: themeProvider.isDarkMode 
                ? Colors.grey[900]?.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
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
            padding: const EdgeInsets.all(16),
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
          ),
        );

        // Solo usar BackdropFilter si está habilitado
        if (useBackdropFilter) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Reducido de 10 a 5
              child: cardContent,
            ),
          );
        }

        return cardContent;
      },
    );
  }
}
