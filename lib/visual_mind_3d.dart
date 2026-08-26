/// Pure Flutter 3D force-directed graph view (Canvas / CustomPainter).
///
/// No WebViews — all rendering uses [CustomPainter], [dart:ui], and
/// [Matrix4] / `vector_math` transforms.
library;

export 'src/camera/graph_camera.dart';
export 'src/models/graph_edge.dart';
export 'src/models/graph_node.dart';
export 'src/models/projected_node.dart';
export 'src/physics/force_config.dart';
export 'src/physics/force_directed_engine.dart';
export 'src/rendering/graph_painter.dart';
export 'src/rendering/node_image_cache.dart';
export 'src/widgets/visual_mind_3d_view.dart';
