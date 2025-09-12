import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Comportamiento de scroll personalizado que elimina completamente el rebote
class NoBounceScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Sin indicador de overscroll
  }
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Sin rebote, scroll normal
  }
  
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

/// Widget que envuelve cualquier scrollable para eliminar el rebote
class NoBounceScrollView extends StatelessWidget {
  final Widget child;
  
  const NoBounceScrollView({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoBounceScrollBehavior(),
      child: child,
    );
  }
}

/// ListView sin rebote
class NoBounceListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  
  const NoBounceListView({
    super.key,
    required this.children,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoBounceScrollBehavior(),
      child: ListView(
        padding: padding,
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const ClampingScrollPhysics(),
        cacheExtent: cacheExtent,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        children: children,
      ),
    );
  }
}

/// ListView.builder sin rebote
class NoBounceListViewBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? cacheExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  
  const NoBounceListViewBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.cacheExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoBounceScrollBehavior(),
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        padding: padding,
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const ClampingScrollPhysics(),
        cacheExtent: cacheExtent,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
      ),
    );
  }
}

/// SingleChildScrollView sin rebote
class NoBounceSingleChildScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  
  const NoBounceSingleChildScrollView({
    super.key,
    required this.child,
    this.controller,
    this.physics,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoBounceScrollBehavior(),
      child: SingleChildScrollView(
        controller: controller,
        physics: physics ?? const ClampingScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}
