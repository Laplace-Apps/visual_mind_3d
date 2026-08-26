import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:visual_mind_3d/visual_mind_3d.dart';

void main() {
  group('ForceDirectedEngine', () {
    test('repulsion pushes coincident nodes apart', () {
      final engine = ForceDirectedEngine(
        config: const ForceConfig(
          idealEdgeLength: 100,
          damping: 0.9,
          centeringStrength: 0,
        ),
      );
      final nodes = <GraphNode>[
        GraphNode(id: 'a', position: Vector3.zero()),
        GraphNode(id: 'b', position: Vector3(0.1, 0, 0)),
      ];

      for (var i = 0; i < 30; i++) {
        engine.step(nodes: nodes, edges: const [], dt: 1 / 60);
      }

      expect(
        (nodes[0].position - nodes[1].position).length,
        greaterThan(5),
      );
    });

    test('attraction pulls linked nodes closer', () {
      final engine = ForceDirectedEngine(
        config: const ForceConfig(
          idealEdgeLength: 80,
          repulsionStrength: 0.2,
          attractionStrength: 2.0,
          damping: 0.85,
          centeringStrength: 0,
        ),
      );
      final nodes = <GraphNode>[
        GraphNode(id: 'a', position: Vector3(-200, 0, 0)),
        GraphNode(id: 'b', position: Vector3(200, 0, 0)),
      ];
      const edges = [GraphEdge(sourceId: 'a', targetId: 'b')];
      final initial = (nodes[0].position - nodes[1].position).length;

      for (var i = 0; i < 120; i++) {
        engine.step(nodes: nodes, edges: edges, dt: 1 / 60);
      }

      final after = (nodes[0].position - nodes[1].position).length;
      expect(after, lessThan(initial));
    });

    test('seedRandomPositions fills zeroed nodes', () {
      final engine = ForceDirectedEngine();
      final nodes = <GraphNode>[
        GraphNode(id: 'a'),
        GraphNode(id: 'b', position: Vector3(10, 0, 0)),
      ];
      engine.seedRandomPositions(nodes, radius: 50);
      expect(nodes[0].position.length, greaterThan(0));
      expect(nodes[1].position.x, 10);
    });
  });

  group('GraphCamera', () {
    test('projects origin near viewport center', () {
      final camera = GraphCamera(
        pan: Offset.zero,
        pitch: 0,
        yaw: 0,
        distance: 800,
      );
      const size = Size(400, 300);
      final projected = camera.projectPoint(Vector3.zero(), size);
      expect(projected, isNotNull);
      expect(projected!.screen.dx, closeTo(200, 2));
      expect(projected.screen.dy, closeTo(150, 2));
      expect(projected.scale, greaterThan(0));
    });

    test('zoom clamps distance', () {
      final camera = GraphCamera(distance: 800);
      camera.zoom(0.0001);
      expect(camera.distance, greaterThanOrEqualTo(80));
      camera.distance = 800;
      camera.zoom(1000);
      expect(camera.distance, lessThanOrEqualTo(5000));
    });

    test('rotate clamps pitch', () {
      final camera = GraphCamera(pitch: 0);
      camera.rotate(dx: 0, dy: 100000, sensitivity: 1);
      expect(camera.pitch, lessThan(1.6));
      camera.rotate(dx: 0, dy: -100000, sensitivity: 1);
      expect(camera.pitch, greaterThan(-1.6));
    });
  });

  group('models', () {
    test('GraphEdge key defaults', () {
      const edge = GraphEdge(sourceId: 'a', targetId: 'b');
      expect(edge.key, 'a->b');
    });

    test('GraphNode equality is by id', () {
      final a = GraphNode(id: 'x', position: Vector3(1, 0, 0));
      final b = GraphNode(id: 'x', position: Vector3(9, 9, 9));
      expect(a, equals(b));
    });
  });
}
