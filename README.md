# visual_mind_3d

Pure Flutter **3D force-directed graph** view — Obsidian-style — rendered with
`CustomPainter` + `Matrix4` / `vector_math`. **No WebViews.**

Nodes can show framed images (`ImageProvider` / `ui.Image`) with screen-facing
billboarding and depth-sorted painter's algorithm occlusion.

## Install

```yaml
dependencies:
  visual_mind_3d:
    path: ../visual_mind_3d   # or pub / git once published
```

## Quick start

```dart
import 'package:visual_mind_3d/visual_mind_3d.dart';
import 'package:vector_math/vector_math_64.dart';

final nodes = [
  GraphNode(
    id: 'home',
    label: 'Home',
    imageProvider: const NetworkImage('https://example.com/a.png'),
  ),
  GraphNode(id: 'notes', label: 'Notes', position: Vector3(80, 0, 0)),
];

final edges = [
  const GraphEdge(sourceId: 'home', targetId: 'notes'),
];

VisualMind3DView(
  nodes: nodes,
  edges: edges,
  showLabels: true,
  onNodeTap: (node) => debugPrint('tapped ${node?.id}'),
);
```

## Architecture

| Component | Role |
|-----------|------|
| `GraphNode` / `GraphEdge` | Graph model (id, `Vector3` position/velocity, mass, `ImageProvider`) |
| `ForceDirectedEngine` | 3D Fruchterman–Reingold step (Coulomb repulsion + Hooke springs) |
| `GraphCamera` | Pan / pitch / yaw / distance → perspective projection |
| `GraphPainter` | Depth-sorted edges + circular billboarded nodes |
| `NodeImageCache` | Resolves `ImageProvider` → `ui.Image` for the painter |
| `VisualMind3DView` | Ticker-driven physics + gesture wrapper |

### Gestures

- **1-finger drag** — orbit (yaw / pitch)
- **2-finger pinch** — zoom (camera distance)
- **2-finger pan** — translate
- **Tap** — node hit-test → `onNodeTap`

## Package layout

```
lib/
  visual_mind_3d.dart
  src/
    models/
    physics/
    camera/
    rendering/
    widgets/
```

Drop this tree into a `flutter create --template=package` project as-is.

## License

MIT
