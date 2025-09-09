import 'package:flutter/material.dart';

// Animaciones optimizadas para mejor rendimiento
class OptimizedAnimations {
  // Duración estándar para animaciones rápidas
  static const Duration fast = Duration(milliseconds: 200);
  
  // Duración estándar para animaciones normales
  static const Duration normal = Duration(milliseconds: 300);
  
  // Duración estándar para animaciones lentas
  static const Duration slow = Duration(milliseconds: 500);

  // Curvas optimizadas para mejor rendimiento
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
}

// Widget para animaciones de fade optimizadas
class OptimizedFadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Duration duration;
  final Curve curve;

  const OptimizedFadeTransition({
    super.key,
    required this.child,
    required this.animation,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }
}

// Widget para animaciones de slide optimizadas
class OptimizedSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<Offset> animation;
  final Duration duration;
  final Curve curve;

  const OptimizedSlideTransition({
    super.key,
    required this.child,
    required this.animation,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }
}

// Widget para animaciones de escala optimizadas
class OptimizedScaleTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Duration duration;
  final Curve curve;

  const OptimizedScaleTransition({
    super.key,
    required this.child,
    required this.animation,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }
}

// Widget para animaciones de altura optimizadas
class OptimizedAnimatedContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onEnd;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.height,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      height: height,
      onEnd: onEnd,
      child: child,
    );
  }
}

// Widget para animaciones de opacidad optimizadas
class OptimizedAnimatedOpacity extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Duration duration;
  final Curve curve;

  const OptimizedAnimatedOpacity({
    super.key,
    required this.child,
    required this.opacity,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      curve: curve,
      opacity: opacity,
      child: child,
    );
  }
}

// Widget para animaciones de posición optimizadas
class OptimizedAnimatedPositioned extends StatelessWidget {
  final Widget child;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Duration duration;
  final Curve curve;

  const OptimizedAnimatedPositioned({
    super.key,
    required this.child,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

// Widget para animaciones de padding optimizadas
class OptimizedAnimatedPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Duration duration;
  final Curve curve;

  const OptimizedAnimatedPadding({
    super.key,
    required this.child,
    required this.padding,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: duration,
      curve: curve,
      padding: padding,
      child: child,
    );
  }
}

// Widget para animaciones de margen optimizadas
class OptimizedAnimatedContainerWithMargin extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Duration duration;
  final Curve curve;

  const OptimizedAnimatedContainerWithMargin({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.duration = OptimizedAnimations.normal,
    this.curve = OptimizedAnimations.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      margin: margin,
      padding: padding,
      child: child,
    );
  }
}
