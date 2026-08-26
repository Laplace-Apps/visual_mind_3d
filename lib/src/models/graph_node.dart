import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

/// A single vertex in the 3D force-directed graph.
///
/// [position] and [velocity] live in world space and are mutated in place by
/// [ForceDirectedEngine]. Optional imagery is supplied via [imageProvider]
/// and resolved asynchronously into [resolvedImage] (see [NodeImageCache]).
class GraphNode {
  GraphNode({
    required this.id,
    Vector3? position,
    Vector3? velocity,
    this.mass = 1.0,
    this.radius = 24.0,
    this.color,
    this.label,
    this.imageProvider,
    this.resolvedImage,
    this.userData,
  })  : position = position ?? Vector3.zero(),
        velocity = velocity ?? Vector3.zero(),
        assert(mass > 0, 'mass must be positive'),
        assert(radius > 0, 'radius must be positive');

  /// Stable unique identifier referenced by [GraphEdge].
  final String id;

  /// World-space center.
  final Vector3 position;

  /// World-space velocity (units / second), integrated by the physics engine.
  final Vector3 velocity;

  /// Inertial mass; heavier nodes move less under the same force.
  final double mass;

  /// Base (unprojected) screen radius in logical pixels.
  final double radius;

  /// Fallback fill when no image is available.
  final Color? color;

  /// Optional display label (drawn by the painter when provided).
  final String? label;

  /// Source for a framed node image (asset, network, memory, etc.).
  final ImageProvider? imageProvider;

  /// Cached decoded bitmap used by [GraphPainter]. Prefer resolving via
  /// [NodeImageCache] rather than assigning this manually.
  final ui.Image? resolvedImage;

  /// Opaque payload for host apps (selection metadata, model refs, …).
  final Object? userData;

  GraphNode copyWith({
    String? id,
    Vector3? position,
    Vector3? velocity,
    double? mass,
    double? radius,
    Color? color,
    String? label,
    ImageProvider? imageProvider,
    ui.Image? resolvedImage,
    Object? userData,
    bool clearResolvedImage = false,
  }) {
    return GraphNode(
      id: id ?? this.id,
      position: position ?? this.position.clone(),
      velocity: velocity ?? this.velocity.clone(),
      mass: mass ?? this.mass,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      label: label ?? this.label,
      imageProvider: imageProvider ?? this.imageProvider,
      resolvedImage:
          clearResolvedImage ? null : (resolvedImage ?? this.resolvedImage),
      userData: userData ?? this.userData,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GraphNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GraphNode($id @ $position)';
}
