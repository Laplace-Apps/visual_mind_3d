import 'package:flutter/foundation.dart';

/// Tunables for the 3D Fruchterman–Reingold / spring-embedder layout.
@immutable
class ForceConfig {
  const ForceConfig({
    this.idealEdgeLength = 120.0,
    this.repulsionStrength = 1.0,
    this.attractionStrength = 1.0,
    this.damping = 0.85,
    this.maxSpeed = 400.0,
    this.centeringStrength = 0.02,
    this.minDistance = 8.0,
    this.gravity = 0.0,
  })  : assert(idealEdgeLength > 0),
        assert(repulsionStrength >= 0),
        assert(attractionStrength >= 0),
        assert(damping > 0 && damping <= 1),
        assert(maxSpeed > 0),
        assert(minDistance > 0);

  /// Target spring rest length `k` (world units).
  final double idealEdgeLength;

  /// Multiplier on Coulomb repulsion (`k² / d`).
  final double repulsionStrength;

  /// Multiplier on Hooke attraction (`d² / k`).
  final double attractionStrength;

  /// Velocity retention each frame (`v *= damping`).
  final double damping;

  /// Hard clamp on velocity magnitude (world units / second).
  final double maxSpeed;

  /// Soft pull of each node toward the origin (stabilizes drift).
  final double centeringStrength;

  /// Floor distance used when computing repulsion to avoid singularities.
  final double minDistance;

  /// Optional downward acceleration (world Y+).
  final double gravity;

  ForceConfig copyWith({
    double? idealEdgeLength,
    double? repulsionStrength,
    double? attractionStrength,
    double? damping,
    double? maxSpeed,
    double? centeringStrength,
    double? minDistance,
    double? gravity,
  }) {
    return ForceConfig(
      idealEdgeLength: idealEdgeLength ?? this.idealEdgeLength,
      repulsionStrength: repulsionStrength ?? this.repulsionStrength,
      attractionStrength: attractionStrength ?? this.attractionStrength,
      damping: damping ?? this.damping,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      centeringStrength: centeringStrength ?? this.centeringStrength,
      minDistance: minDistance ?? this.minDistance,
      gravity: gravity ?? this.gravity,
    );
  }
}
