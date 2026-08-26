import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../camera/graph_camera.dart';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';
import '../models/projected_node.dart';
import '../physics/force_config.dart';
import '../physics/force_directed_engine.dart';
import '../rendering/graph_painter.dart';
import '../rendering/node_image_cache.dart';

/// Callback when the user taps a node (or empty space when null).
typedef NodeTapCallback = void Function(GraphNode? node);

/// Interactive 3D force-directed graph rendered with [CustomPainter].
///
/// Gestures:
/// - **1-finger drag** — orbit camera (yaw / pitch)
/// - **2-finger pinch** — zoom along the camera Z axis
/// - **2-finger pan** — translate the camera
/// - **Tap** — hit-test the nearest node and invoke [onNodeTap]
class VisualMind3DView extends StatefulWidget {
  const VisualMind3DView({
    super.key,
    required this.nodes,
    required this.edges,
    this.camera,
    this.forceConfig = const ForceConfig(),
    this.physicsEnabled = true,
    this.onNodeTap,
    this.selectedNodeId,
    this.backgroundColor = const Color(0xFF0E1116),
    this.edgeColor = const Color(0x66B0BEC5),
    this.showLabels = false,
    this.seedRandomPositions = true,
  });

  /// Mutable simulation nodes (positions / velocities updated in place).
  final List<GraphNode> nodes;

  final List<GraphEdge> edges;

  /// Optional external camera; otherwise one is created and owned internally.
  final GraphCamera? camera;

  final ForceConfig forceConfig;
  final bool physicsEnabled;
  final NodeTapCallback? onNodeTap;
  final String? selectedNodeId;
  final Color backgroundColor;
  final Color edgeColor;
  final bool showLabels;

  /// When true, zero-position nodes are scattered on first frame.
  final bool seedRandomPositions;

  @override
  State<VisualMind3DView> createState() => VisualMind3DViewState();
}

class VisualMind3DViewState extends State<VisualMind3DView>
    with SingleTickerProviderStateMixin {
  late final GraphCamera _camera;
  late final ForceDirectedEngine _engine;
  late final Ticker _ticker;
  late final NodeImageCache _imageCache;

  Duration _lastElapsed = Duration.zero;
  bool _seeded = false;

  /// Pointer tracking for 1- vs 2-finger gestures.
  final Map<int, Offset> _pointers = <int, Offset>{};
  double? _lastPinchDistance;
  Offset? _lastFocalPoint;

  GraphCamera get camera => _camera;

  ForceDirectedEngine get engine => _engine;

  @override
  void initState() {
    super.initState();
    _camera = widget.camera ?? GraphCamera();
    _engine = ForceDirectedEngine(config: widget.forceConfig);
    _imageCache = NodeImageCache()..addListener(_onImages);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImages();
  }

  @override
  void didUpdateWidget(covariant VisualMind3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _engine.config = widget.forceConfig;
    if (!identical(oldWidget.nodes, widget.nodes)) {
      _syncImages();
    }
  }

  void _onImages() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncImages() {
    final double dpr = View.of(context).devicePixelRatio;
    _imageCache.sync(widget.nodes, pixelRatio: dpr);
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? 0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    if (!_seeded && widget.seedRandomPositions) {
      _engine.seedRandomPositions(widget.nodes);
      _seeded = true;
    }

    if (widget.physicsEnabled && dt > 0 && dt < 0.1) {
      _engine.step(nodes: widget.nodes, edges: widget.edges, dt: dt);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _imageCache
      ..removeListener(_onImages)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    _refreshGestureAnchors();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) {
      return;
    }
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length == 1) {
      _camera.rotate(dx: event.delta.dx, dy: event.delta.dy);
      setState(() {});
      return;
    }

    if (_pointers.length >= 2) {
      final List<Offset> pts = _pointers.values.take(2).toList(growable: false);
      final double dist = (pts[0] - pts[1]).distance;
      final Offset focal = Offset(
        (pts[0].dx + pts[1].dx) / 2,
        (pts[0].dy + pts[1].dy) / 2,
      );

      if (_lastPinchDistance != null && _lastPinchDistance! > 0) {
        final double zoomFactor = _lastPinchDistance! / dist;
        _camera.zoom(zoomFactor);
      }
      if (_lastFocalPoint != null) {
        // Pan opposite to finger motion so content follows the pinch center.
        final Offset delta = focal - _lastFocalPoint!;
        _camera.translate(delta, sensitivity: _camera.distance / 600);
      }

      _lastPinchDistance = dist;
      _lastFocalPoint = focal;
      setState(() {});
    }
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    _refreshGestureAnchors();
  }

  void _refreshGestureAnchors() {
    if (_pointers.length >= 2) {
      final List<Offset> pts = _pointers.values.take(2).toList(growable: false);
      _lastPinchDistance = (pts[0] - pts[1]).distance;
      _lastFocalPoint = Offset(
        (pts[0].dx + pts[1].dx) / 2,
        (pts[0].dy + pts[1].dy) / 2,
      );
    } else {
      _lastPinchDistance = null;
      _lastFocalPoint = null;
    }
  }

  void _onTapUp(TapUpDetails details) {
    final NodeTapCallback? cb = widget.onNodeTap;
    if (cb == null) {
      return;
    }

    final Size size = context.size ?? Size.zero;
    final List<ProjectedNode> projected =
        _camera.projectNodes(widget.nodes, size);
    GraphNode? hit;
    double best = double.infinity;

    for (final ProjectedNode p in projected) {
      final double d = (p.screen - details.localPosition).distance;
      if (d <= p.screenRadius * 1.15 && d < best) {
        best = d;
        hit = p.node;
      }
    }
    cb(hit);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        child: CustomPaint(
          painter: GraphPainter(
            nodes: widget.nodes,
            edges: widget.edges,
            camera: _camera,
            images: _imageCache.images,
            backgroundColor: widget.backgroundColor,
            edgeColor: widget.edgeColor,
            selectedNodeId: widget.selectedNodeId,
            showLabels: widget.showLabels,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
