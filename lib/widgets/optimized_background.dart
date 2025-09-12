import 'package:flutter/material.dart';

class OptimizedBackground extends StatelessWidget {
  final ImageProvider? backgroundImage;
  final bool isDarkMode;
  final Widget child;

  const OptimizedBackground({
    super.key,
    required this.backgroundImage,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.grey[50],
      ),
      child: Stack(
        children: [
          // Background personalizado optimizado
          if (backgroundImage != null)
            _OptimizedBackgroundImage(
              image: backgroundImage!,
              isDarkMode: isDarkMode,
            ),
          // Contenido principal
          child,
        ],
      ),
    );
  }
}

class _OptimizedBackgroundImage extends StatefulWidget {
  final ImageProvider image;
  final bool isDarkMode;

  const _OptimizedBackgroundImage({
    required this.image,
    required this.isDarkMode,
  });

  @override
  State<_OptimizedBackgroundImage> createState() => _OptimizedBackgroundImageState();
}

class _OptimizedBackgroundImageState extends State<_OptimizedBackgroundImage> {
  late ImageProvider _cachedImage;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _cachedImage = widget.image;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadImage();
  }

  @override
  void didUpdateWidget(_OptimizedBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _cachedImage = widget.image;
      _preloadImage();
    }
  }

  void _preloadImage() {
    if (mounted) {
      precacheImage(_cachedImage, context).then((_) {
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      }).catchError((_) {
        // Si falla la carga, usar fondo sólido
        if (mounted) {
          setState(() {
            _isImageLoaded = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImageLoaded) {
      // Mostrar fondo sólido mientras carga
      return Container(
        color: widget.isDarkMode ? Colors.black : Colors.grey[50],
      );
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _cachedImage,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.4),
              BlendMode.darken,
            ),
          ),
        ),
      ),
    );
  }
}
