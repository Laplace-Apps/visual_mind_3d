import 'package:flutter/foundation.dart';

/// An undirected (or directed) link between two [GraphNode]s by id.
@immutable
class GraphEdge {
  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.weight = 1.0,
    this.id,
  }) : assert(weight > 0, 'weight must be positive');

  /// Optional edge identifier; defaults to `"$sourceId->$targetId"`.
  final String? id;

  /// Id of the source node.
  final String sourceId;

  /// Id of the target node.
  final String targetId;

  /// Spring stiffness multiplier for Hooke attraction.
  final double weight;

  String get key => id ?? '$sourceId->$targetId';

  GraphEdge copyWith({
    String? sourceId,
    String? targetId,
    double? weight,
    String? id,
  }) {
    return GraphEdge(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      weight: weight ?? this.weight,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GraphEdge &&
        other.sourceId == sourceId &&
        other.targetId == targetId &&
        other.weight == weight &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(sourceId, targetId, weight, id);

  @override
  String toString() => 'GraphEdge($sourceId -> $targetId, w=$weight)';
}
