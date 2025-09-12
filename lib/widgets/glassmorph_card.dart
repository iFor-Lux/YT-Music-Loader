import 'package:flutter/material.dart';
import 'dart:ui';

/// Widget reutilizable para glassmorphing optimizado
/// Centraliza todo el código de glassmorphing para mejor rendimiento y mantenimiento
class GlassmorphCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool isDarkMode;
  final double blurSigma;
  final List<Color>? gradientColors;
  final double opacity;

  const GlassmorphCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.blurSigma = 8.0,
    this.gradientColors,
    this.opacity = 0.6,
  });

  // Cache para colores de gradiente (optimización)
  static final Map<String, List<Color>> _gradientCache = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? _getDefaultGradientColors(),
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ?? _getDefaultBorder(),
              boxShadow: boxShadow ?? _getDefaultBoxShadow(),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  List<Color> _getDefaultGradientColors() {
    final cacheKey = '${isDarkMode}_$opacity';
    
    if (_gradientCache.containsKey(cacheKey)) {
      return _gradientCache[cacheKey]!;
    }
    
    final colors = isDarkMode 
        ? [
            Colors.black.withValues(alpha: opacity),
            Colors.black.withValues(alpha: opacity * 0.7),
          ]
        : [
            Colors.white.withValues(alpha: opacity + 0.1),
            Colors.white.withValues(alpha: opacity * 0.7),
          ];
    
    _gradientCache[cacheKey] = colors;
    return colors;
  }

  Border _getDefaultBorder() {
    return Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1.5,
    );
  }

  List<BoxShadow> _getDefaultBoxShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, -8),
      ),
    ];
  }
}

/// Widget especializado para cards de configuración
class GlassmorphConfigCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool isDarkMode;

  const GlassmorphConfigCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphCard(
      isDarkMode: isDarkMode,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Widget especializado para headers
class GlassmorphHeader extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const GlassmorphHeader({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphCard(
      isDarkMode: isDarkMode,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      blurSigma: 8.0,
      child: child,
    );
  }
}

/// Widget especializado para botones de acción
class GlassmorphActionCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final List<Color>? gradientColors;

  const GlassmorphActionCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.margin,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphCard(
      isDarkMode: isDarkMode,
      margin: margin ?? const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 20),
      blurSigma: 8.0,
      gradientColors: gradientColors,
      child: child,
    );
  }
}

/// Widget especializado para estadísticas
class GlassmorphStatCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const GlassmorphStatCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphCard(
      isDarkMode: isDarkMode,
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(12),
      blurSigma: 8.0,
      child: child,
    );
  }
}

