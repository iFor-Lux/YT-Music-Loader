import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
}

// Widget para thumbnails de video optimizado
class OptimizedVideoThumbnail extends StatelessWidget {
  final String thumbnailUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final Color? errorColor;

  const OptimizedVideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.placeholderColor,
    this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: thumbnailUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      cacheWidth: (width * 2).round(), // Cache a 2x para pantallas de alta densidad
      cacheHeight: (height * 2).round(),
      placeholder: Container(
        width: width,
        height: height,
        color: placeholderColor ?? Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        color: errorColor ?? Colors.grey[300],
        child: const Icon(
          Icons.image,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}
