import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/graph_edge.dart';
import '../models/graph_node.dart';
import 'force_config.dart';

/// 3D force-directed layout (Fruchterman–Reingold style).
///
/// Each [step] applies:
/// - Coulomb repulsion between all node pairs (`k² / d`)
/// - Hooke attraction along edges (`d² / k * weight`)
/// - Optional centering spring + gravity
/// - Damped Euler integration of velocity / position
class ForceDirectedEngine {
  ForceDirectedEngine({
    this.config = const ForceConfig(),
    math.Random? random,
  }) : _random = random ?? math.Random();

  /// Layout tunables (safe to replace while the simulation runs).
  ForceConfig config;
  final math.Random _random;

  /// Advances the simulation by [dt] seconds, mutating [nodes] in place.
  ///
  /// Returns the same list for chaining. Nodes referenced by [edges] that are
  /// missing from [nodes] are ignored.
  List<GraphNode> step({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required double dt,
  }) {
    if (nodes.isEmpty || dt <= 0) {
      return nodes;
    }

    final int n = nodes.length;
    final List<Vector3> forces = List<Vector3>.generate(
      n,
      (_) => Vector3.zero(),
      growable: false,
    );
    final Map<String, int> indexById = <String, int>{
      for (int i = 0; i < n; i++) nodes[i].id: i,
    };

    final double k = config.idealEdgeLength;
    final double kSq = k * k;
    final double minD = config.minDistance;

    // --- Repulsion (Coulomb): O(n²) — fine for foundational graphs. ---
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final Vector3 delta = nodes[i].position - nodes[j].position;
        double dist = delta.length;
        if (dist < minD) {
          // Jitter coincident nodes so they separate next frame.
          delta.setValues(
            (_random.nextDouble() - 0.5) * minD,
            (_random.nextDouble() - 0.5) * minD,
            (_random.nextDouble() - 0.5) * minD,
          );
          dist = delta.length.clamp(minD * 0.5, double.infinity);
        }

        final Vector3 direction = delta / dist;
        final double magnitude =
            config.repulsionStrength * kSq / dist;
        final Vector3 force = direction * magnitude;
        forces[i].add(force);
        forces[j].sub(force);
      }
    }

    // --- Attraction (Hooke) along edges. ---
    for (final GraphEdge edge in edges) {
      final int? si = indexById[edge.sourceId];
      final int? ti = indexById[edge.targetId];
      if (si == null || ti == null || si == ti) {
        continue;
      }

      final Vector3 delta = nodes[ti].position - nodes[si].position;
      final double dist = math.max(delta.length, minD);
      final Vector3 direction = delta / dist;
      final double magnitude = config.attractionStrength *
          (dist * dist) /
          k *
          edge.weight;
      final Vector3 force = direction * magnitude;
      forces[si].add(force);
      forces[ti].sub(force);
    }

    // --- Centering + gravity, then integrate. ---
    final double damp = config.damping;
    final double maxSpeed = config.maxSpeed;
    final double centerK = config.centeringStrength;
    final double gravity = config.gravity;

    for (int i = 0; i < n; i++) {
      final GraphNode node = nodes[i];
      final Vector3 force = forces[i];

      if (centerK != 0) {
        force.sub(node.position * centerK);
      }
      if (gravity != 0) {
        force.y += gravity * node.mass;
      }

      final Vector3 acceleration = force / node.mass;
      node.velocity
        ..add(acceleration * dt)
        ..scale(damp);

      final double speed = node.velocity.length;
      if (speed > maxSpeed) {
        node.velocity.scale(maxSpeed / speed);
      }

      node.position.add(node.velocity * dt);
    }

    return nodes;
  }

  /// Scatters nodes with unset / zero positions into a sphere of [radius].
  void seedRandomPositions(
    List<GraphNode> nodes, {
    double radius = 200,
  }) {
    for (final GraphNode node in nodes) {
      if (node.position.length2 > 1e-6) {
        continue;
      }
      // Uniform-ish point in a ball via rejection-friendly spherical coords.
      final double u = _random.nextDouble();
      final double v = _random.nextDouble();
      final double theta = 2 * math.pi * u;
      final double phi = math.acos(2 * v - 1);
      final double r = radius * math.pow(_random.nextDouble(), 1 / 3).toDouble();
      node.position.setValues(
        r * math.sin(phi) * math.cos(theta),
        r * math.sin(phi) * math.sin(theta),
        r * math.cos(phi),
      );
      node.velocity.setZero();
    }
  }
}
