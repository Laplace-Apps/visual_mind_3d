import 'package:flutter/material.dart';
import 'package:visual_mind_3d/visual_mind_3d.dart';

void main() {
  runApp(const VisualMind3DExampleApp());
}

class VisualMind3DExampleApp extends StatelessWidget {
  const VisualMind3DExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoGraphPage(),
    );
  }
}

class DemoGraphPage extends StatefulWidget {
  const DemoGraphPage({super.key});

  @override
  State<DemoGraphPage> createState() => _DemoGraphPageState();
}

class _DemoGraphPageState extends State<DemoGraphPage> {
  late final List<GraphNode> _nodes;
  late final List<GraphEdge> _edges;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _nodes = List<GraphNode>.generate(12, (int i) {
      return GraphNode(
        id: 'n$i',
        label: 'N$i',
        radius: 22,
        // imageProvider: NetworkImage('https://example.com/a.png'),
      );
    });
    final List<GraphEdge> edges = <GraphEdge>[];
    for (int i = 0; i < _nodes.length - 1; i++) {
      edges.add(
        GraphEdge(sourceId: _nodes[i].id, targetId: _nodes[i + 1].id),
      );
    }
    edges.addAll(const <GraphEdge>[
      GraphEdge(sourceId: 'n0', targetId: 'n5'),
      GraphEdge(sourceId: 'n2', targetId: 'n8'),
      GraphEdge(sourceId: 'n3', targetId: 'n10'),
    ]);
    _edges = edges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: Stack(
        children: [
          VisualMind3DView(
            nodes: _nodes,
            edges: _edges,
            showLabels: true,
            selectedNodeId: _selected,
            forceConfig: const ForceConfig(
              idealEdgeLength: 140,
              centeringStrength: 0.015,
            ),
            onNodeTap: (GraphNode? node) {
              setState(() => _selected = node?.id);
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _selected == null
                      ? 'Drag to orbit · Pinch to zoom · Tap a node'
                      : 'Selected: $_selected',
                  style: const TextStyle(color: Color(0xB3FFFFFF)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
