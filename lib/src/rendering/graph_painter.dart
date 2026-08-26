import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../camera/graph_camera.dart';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';
import '../models/projected_node.dart';

/// Depth-sorted CustomPainter for the 3D graph.
///
/// Nodes are projected, sorted far→near (painter's algorithm), then drawn as
/// billboarded circles — the image always faces the viewer because drawing
/// happens entirely in screen space after perspective projection.
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.camera,
    this.images = const <String, ui.Image>{},
    this.backgroundColor = const Color(0xFF0E1116),
    this.edgeColor = const Color(0x66B0BEC5),
    this.edgeStrokeWidth = 1.25,
    this.nodeBorderColor = const Color(0xFFECEFF1),
    this.nodeBorderWidth = 1.5,
    this.selectedNodeId,
    this.selectedBorderColor = const Color(0xFFFFC107),
    this.labelStyle,
    this.showLabels = false,
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final GraphCamera camera;
  final Map<String, ui.Image> images;

  final Color backgroundColor;
  final Color edgeColor;
  final double edgeStrokeWidth;
  final Color nodeBorderColor;
  final double nodeBorderWidth;
  final String? selectedNodeId;
  final Color selectedBorderColor;
  final TextStyle? labelStyle;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final List<ProjectedNode> projected = camera.projectNodes(nodes, size);
    if (projected.isEmpty) {
      return;
    }

    // Farther (larger depth) first so nearer nodes occlude correctly.
    projected.sort((ProjectedNode a, ProjectedNode b) => b.depth.compareTo(a.depth));

    final Map<String, ProjectedNode> byId = <String, ProjectedNode>{
      for (final ProjectedNode p in projected) p.node.id: p,
    };

    _drawEdges(canvas, byId);
    _drawNodes(canvas, projected);
  }

  void _drawEdges(Canvas canvas, Map<String, ProjectedNode> byId) {
    final Paint paint = Paint()
      ..color = edgeColor
      ..strokeWidth = edgeStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (final GraphEdge edge in edges) {
      final ProjectedNode? a = byId[edge.sourceId];
      final ProjectedNode? b = byId[edge.targetId];
      if (a == null || b == null) {
        continue;
      }

      // Soften distant edges slightly via average scale.
      final double alpha = ((a.scale + b.scale) * 0.5).clamp(0.25, 1.0);
      paint.color = edgeColor.withValues(alpha: edgeColor.a * alpha);
      canvas.drawLine(a.screen, b.screen, paint);
    }
  }

  void _drawNodes(Canvas canvas, List<ProjectedNode> projected) {
    final Paint fillPaint = Paint()..isAntiAlias = true;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = nodeBorderWidth
      ..isAntiAlias = true;

    for (final ProjectedNode p in projected) {
      final double r = p.screenRadius;
      if (r < 0.5) {
        continue;
      }

      final Offset c = p.screen;
      final Rect bounds = Rect.fromCircle(center: c, radius: r);
      final ui.Image? image = images[p.node.id] ?? p.node.resolvedImage;

      canvas.save();
      canvas.clipPath(Path()..addOval(bounds));

      if (image != null) {
        _drawBillboardImage(canvas, image, bounds);
      } else {
        fillPaint.color = p.node.color ?? _colorForId(p.node.id);
        canvas.drawOval(bounds, fillPaint);
      }
      canvas.restore();

      final bool selected = p.node.id == selectedNodeId;
      borderPaint
        ..color = selected ? selectedBorderColor : nodeBorderColor
        ..strokeWidth = selected ? nodeBorderWidth * 1.8 : nodeBorderWidth;
      canvas.drawCircle(c, r, borderPaint);

      if (showLabels && p.node.label != null && r > 10) {
        _drawLabel(canvas, p.node.label!, c, r);
      }
    }
  }

  /// Draws [image] cover-fit inside [bounds] (already circularly clipped).
  ///
  /// Because projection already flattened the node to screen space, a simple
  /// 2D blit is true billboarding — the sprite always faces the viewer.
  void _drawBillboardImage(Canvas canvas, ui.Image image, Rect bounds) {
    final double srcW = image.width.toDouble();
    final double srcH = image.height.toDouble();
    final double scale = math.max(bounds.width / srcW, bounds.height / srcH);
    final double scaledW = srcW * scale;
    final double scaledH = srcH * scale;
    final Rect dest = Rect.fromCenter(
      center: bounds.center,
      width: scaledW,
      height: scaledH,
    );
    final Rect src = Rect.fromLTWH(0, 0, srcW, srcH);
    canvas.drawImageRect(
      image,
      src,
      dest,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double radius) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle ??
            const TextStyle(
              color: Color(0xFFECEFF1),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: radius * 3);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + radius + 4));
  }

  static Color _colorForId(String id) {
    final int hash = id.hashCode;
    final double h = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, h, 0.45, 0.55).toColor();
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return !identical(nodes, oldDelegate.nodes) ||
        !identical(edges, oldDelegate.edges) ||
        !identical(camera, oldDelegate.camera) ||
        !identical(images, oldDelegate.images) ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        backgroundColor != oldDelegate.backgroundColor ||
        edgeColor != oldDelegate.edgeColor ||
        showLabels != oldDelegate.showLabels;
  }
}
