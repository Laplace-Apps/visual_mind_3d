import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import '../models/graph_node.dart';

/// Resolves [ImageProvider]s on [GraphNode]s into [ui.Image] bitmaps.
///
/// Call [sync] whenever the node list changes. Listeners are notified when
/// any decode completes so the host widget can `setState` / mark the painter
/// dirty.
class NodeImageCache extends ChangeNotifier {
  NodeImageCache();

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  final Map<String, ImageStream> _streams = <String, ImageStream>{};
  final Map<String, ImageStreamListener> _listeners =
      <String, ImageStreamListener>{};

  /// Currently decoded images keyed by node id.
  Map<String, ui.Image> get images => Map<String, ui.Image>.unmodifiable(_images);

  ui.Image? operator [](String nodeId) => _images[nodeId];

  /// Ensures providers for [nodes] are loading / cached; drops stale entries.
  void sync(List<GraphNode> nodes, {double pixelRatio = 1.0}) {
    final Set<String> keep = <String>{};

    for (final GraphNode node in nodes) {
      final ImageProvider? provider = node.imageProvider;
      if (provider == null) {
        continue;
      }
      keep.add(node.id);

      // Already have a bitmap and an active stream for this id.
      if (_images.containsKey(node.id) && _streams.containsKey(node.id)) {
        continue;
      }
      if (_streams.containsKey(node.id)) {
        continue;
      }

      _listen(node.id, provider, pixelRatio: pixelRatio);
    }

    final List<String> stale = _streams.keys
        .where((String id) => !keep.contains(id))
        .toList(growable: false);
    for (final String id in stale) {
      _cancel(id);
      _images.remove(id);
    }
  }

  void _listen(String id, ImageProvider provider, {required double pixelRatio}) {
    final ImageConfiguration config = ImageConfiguration(
      devicePixelRatio: pixelRatio,
      platform: defaultTargetPlatform,
    );
    final ImageStream stream = provider.resolve(config);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        _images[id] = info.image;
        if (synchronousCall) {
          // Defer notify to avoid setState during build.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
        } else {
          notifyListeners();
        }
      },
      onError: (Object exception, StackTrace? stackTrace) {
        assert(() {
          debugPrint('NodeImageCache: failed to resolve image for $id: $exception');
          return true;
        }());
      },
    );
    stream.addListener(listener);
    _streams[id] = stream;
    _listeners[id] = listener;
  }

  void _cancel(String id) {
    final ImageStream? stream = _streams.remove(id);
    final ImageStreamListener? listener = _listeners.remove(id);
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
  }

  /// Applies cached bitmaps onto a copy of each node (`resolvedImage`).
  List<GraphNode> applyTo(List<GraphNode> nodes) {
    return nodes
        .map(
          (GraphNode n) => n.copyWith(
            resolvedImage: _images[n.id] ?? n.resolvedImage,
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final String id in _streams.keys.toList(growable: false)) {
      _cancel(id);
    }
    _images.clear();
    super.dispose();
  }
}
