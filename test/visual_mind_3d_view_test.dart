import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visual_mind_3d/visual_mind_3d.dart';

void main() {
  testWidgets('VisualMind3DView builds and paints', (WidgetTester tester) async {
    final nodes = <GraphNode>[
      GraphNode(id: 'a', label: 'A'),
      GraphNode(id: 'b', label: 'B'),
    ];
    const edges = <GraphEdge>[
      GraphEdge(sourceId: 'a', targetId: 'b'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualMind3DView(
            nodes: nodes,
            edges: edges,
            physicsEnabled: false,
            seedRandomPositions: true,
          ),
        ),
      ),
    );

    expect(find.byType(VisualMind3DView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  });
}
