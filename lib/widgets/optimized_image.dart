import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Widget optimizado para imágenes con cache mejorado
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.fadeInCurve = Curves.easeIn,
    this.fadeOutCurve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      fadeInCurve: fadeInCurve,
      fadeOutCurve: fadeOutCurve,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
      imageBuilder: (context, imageProvider) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: backgroundColor,
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
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
      color: backgroundColor ?? Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 24,
      ),
    );
  }
}

/// Widget optimizado para thumbnails de video
class OptimizedVideoThumbnail extends StatelessWidget {
  final String thumbnailUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showPlayIcon;
  final Color? playIconColor;
  final double? playIconSize;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedVideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.showPlayIcon = true,
    this.playIconColor,
    this.playIconSize,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OptimizedImage(
          imageUrl: thumbnailUrl,
          width: width,
          height: height,
          borderRadius: borderRadius,
          placeholder: placeholder,
          errorWidget: errorWidget,
          memCacheWidth: width != null ? (width! * 2).round() : null,
          memCacheHeight: height != null ? (height! * 2).round() : null,
        ),
        if (showPlayIcon)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: playIconColor ?? Colors.white,
                  size: playIconSize ?? (width != null ? width! * 0.3 : 24),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget optimizado para avatares de canal
class OptimizedChannelAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedChannelAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 40,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedImage(
      imageUrl: avatarUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      backgroundColor: backgroundColor,
      placeholder: placeholder,
      errorWidget: errorWidget,
      memCacheWidth: (size * 2).round(),
      memCacheHeight: (size * 2).round(),
    );
  }
}

/// Widget optimizado para imágenes de fondo
class OptimizedBackgroundImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? opacity;
  final Color? colorFilter;
  final BlendMode? blendMode;
  final Widget? child;

  const OptimizedBackgroundImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.opacity,
    this.colorFilter,
    this.blendMode,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(imageUrl),
          fit: fit,
          colorFilter: colorFilter != null
              ? ColorFilter.mode(colorFilter!, blendMode ?? BlendMode.srcOver)
              : opacity != null
                  ? ColorFilter.mode(Colors.white.withValues(alpha: opacity!), BlendMode.modulate)
                  : null,
        ),
      ),
      child: child,
    );
  }
}

/// Widget optimizado para imágenes con lazy loading
class OptimizedLazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;

  const OptimizedLazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.fadeInCurve = Curves.easeIn,
    this.fadeOutCurve = Curves.easeOut,
  });

  @override
  State<OptimizedLazyImage> createState() => _OptimizedLazyImageState();
}

class _OptimizedLazyImageState extends State<OptimizedLazyImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.imageUrl),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction > 0.1 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: _isVisible
          ? OptimizedImage(
              imageUrl: widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              borderRadius: widget.borderRadius,
              placeholder: widget.placeholder,
              errorWidget: widget.errorWidget,
              backgroundColor: widget.backgroundColor,
              enableMemoryCache: widget.enableMemoryCache,
              enableDiskCache: widget.enableDiskCache,
              memCacheWidth: widget.memCacheWidth,
              memCacheHeight: widget.memCacheHeight,
              fadeInDuration: widget.fadeInDuration,
              fadeOutDuration: widget.fadeOutDuration,
              fadeInCurve: widget.fadeInCurve,
              fadeOutCurve: widget.fadeOutCurve,
            )
          : Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                color: widget.backgroundColor ?? Colors.grey[300],
              ),
              child: widget.placeholder ?? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}