import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'graph_node.dart';

/// A [GraphNode] after camera projection into screen space.
@immutable
class ProjectedNode {
  const ProjectedNode({
    required this.node,
    required this.screen,
    required this.depth,
    required this.scale,
  });

  final GraphNode node;

  /// Projected center in canvas coordinates.
  final Offset screen;

  /// View-space / clip depth used for painter sorting (larger = farther).
  final double depth;

  /// Perspective scale factor applied to [GraphNode.radius].
  final double scale;

  double get screenRadius => node.radius * scale;

  @override
  String toString() =>
      'ProjectedNode(${node.id} @ $screen, depth=$depth, scale=$scale)';
}
