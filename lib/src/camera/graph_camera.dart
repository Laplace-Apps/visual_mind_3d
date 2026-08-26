import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/graph_node.dart';
import '../models/projected_node.dart';

/// Interactive camera: pan, pitch/yaw orbit, and distance (zoom).
///
/// Projection pipeline:
/// 1. View matrix — translate world by [pan], then rotate by [yaw]/[pitch],
///    then push the scene along −Z by [distance].
/// 2. Perspective divide using [fieldOfView] and [near]/[far].
/// 3. Map NDC → screen pixels.
class GraphCamera {
  GraphCamera({
    this.pan = Offset.zero,
    this.pitch = 0.2,
    this.yaw = 0.4,
    this.distance = 800,
    this.fieldOfView = math.pi / 4,
    this.near = 1,
    this.far = 5000,
  });

  /// World-space XY translation applied before rotation (screen pan).
  Offset pan;

  /// Rotation about X (radians). Clamped in [rotate] to avoid flips.
  double pitch;

  /// Rotation about Y (radians).
  double yaw;

  /// Distance from the orbit origin to the camera along view −Z.
  double distance;

  /// Vertical field of view in radians.
  double fieldOfView;

  double near;
  double far;

  static const double _minPitch = -math.pi / 2 + 0.05;
  static const double _maxPitch = math.pi / 2 - 0.05;
  static const double _minDistance = 80;
  static const double _maxDistance = 5000;

  /// Orbit by screen-space deltas (positive [dx] → yaw right).
  void rotate({required double dx, required double dy, double sensitivity = 0.005}) {
    yaw += dx * sensitivity;
    pitch = (pitch + dy * sensitivity).clamp(_minPitch, _maxPitch);
  }

  /// Pinch / scroll zoom: [factor] > 1 moves farther (zoom out).
  void zoom(double factor) {
    distance = (distance * factor).clamp(_minDistance, _maxDistance);
  }

  /// Translate along the view-facing XY plane (after rotation).
  void translate(Offset delta, {double sensitivity = 1.0}) {
    pan += delta * sensitivity;
  }

  /// Builds the view matrix for the current orientation.
  Matrix4 viewMatrix() {
    return Matrix4.identity()
      ..translateByDouble(0, 0, -distance, 1)
      ..rotateX(pitch)
      ..rotateY(yaw)
      ..translateByDouble(-pan.dx, -pan.dy, 0, 1);
  }

  /// Perspective projection matrix for a viewport of [size].
  Matrix4 projectionMatrix(Size size) {
    final double aspect =
        size.height == 0 ? 1.0 : size.width / size.height;
    return makePerspectiveMatrix(fieldOfView, aspect, near, far);
  }

  /// Combined model-view-projection (world identity).
  Matrix4 mvpMatrix(Size size) => projectionMatrix(size) * viewMatrix();

  /// Projects a world-space point into screen coordinates.
  ///
  /// Returns `null` when the point is behind the near plane (`w <= 0`) or
  /// outside a generous clip range.
  ProjectedPoint? projectPoint(Vector3 world, Size size) {
    final Matrix4 mvp = mvpMatrix(size);
    final Vector4 clip = mvp.transform(Vector4(world.x, world.y, world.z, 1));
    if (clip.w <= 1e-5) {
      return null;
    }

    final double invW = 1.0 / clip.w;
    final double ndcX = clip.x * invW;
    final double ndcY = clip.y * invW;
    final double ndcZ = clip.z * invW;

    // Discard points far outside NDC to skip drawing.
    if (ndcZ < -1.2 || ndcZ > 1.2) {
      return null;
    }

    final Offset screen = Offset(
      (ndcX + 1) * 0.5 * size.width,
      (1 - ndcY) * 0.5 * size.height,
    );

    // Perspective scale ≈ focal / view-depth. Use clip.w as a stable proxy.
    final double scale = (distance / clip.w).clamp(0.15, 4.0);

    return ProjectedPoint(
      screen: screen,
      depth: ndcZ,
      scale: scale,
    );
  }

  /// Projects every node; drops points that fail the clip test.
  List<ProjectedNode> projectNodes(List<GraphNode> nodes, Size size) {
    final List<ProjectedNode> out = <ProjectedNode>[];
    for (final GraphNode node in nodes) {
      final ProjectedPoint? p = projectPoint(node.position, size);
      if (p == null) {
        continue;
      }
      out.add(
        ProjectedNode(
          node: node,
          screen: p.screen,
          depth: p.depth,
          scale: p.scale,
        ),
      );
    }
    return out;
  }

  GraphCamera copy() {
    return GraphCamera(
      pan: pan,
      pitch: pitch,
      yaw: yaw,
      distance: distance,
      fieldOfView: fieldOfView,
      near: near,
      far: far,
    );
  }
}

/// Result of projecting a single world point.
@immutable
class ProjectedPoint {
  const ProjectedPoint({
    required this.screen,
    required this.depth,
    required this.scale,
  });

  final Offset screen;
  final double depth;
  final double scale;
}
