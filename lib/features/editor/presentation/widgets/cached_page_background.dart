import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/ink_models.dart';
import 'page_background_painter.dart';

/// Renders the paper background once into a bitmap and reuses it while
/// panning/zooming. Regenerates only when size or paper settings change.
class CachedPageBackground extends StatefulWidget {
  const CachedPageBackground({
    super.key,
    required this.pageSize,
    required this.template,
    this.paper,
    this.pdfImage,
  });

  final Size pageSize;
  final PageTemplate template;
  final PaperTemplate? paper;
  final ui.Image? pdfImage;

  @override
  State<CachedPageBackground> createState() => _CachedPageBackgroundState();
}

class _CachedPageBackgroundState extends State<CachedPageBackground> {
  ui.Image? _image;
  int _token = 0;
  Object? _builtKey;

  Object get _cacheKey => (
    widget.pageSize.width,
    widget.pageSize.height,
    widget.template,
    widget.pdfImage,
    widget.paper?.id,
    widget.paper?.style,
    widget.paper?.backgroundColor,
    widget.paper?.lineColor,
    widget.paper?.lineSpacing,
    widget.paper?.gridSize,
    widget.paper?.marginLeft,
    widget.paper?.marginTop,
    widget.paper?.horizontalLines,
    widget.paper?.verticalLines,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCache());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCache();
  }

  @override
  void didUpdateWidget(covariant CachedPageBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_cacheKey != _builtKey) {
      _ensureCache();
    }
  }

  @override
  void dispose() {
    _token++;
    _image?.dispose();
    super.dispose();
  }

  Future<void> _ensureCache() async {
    if (!mounted) return;
    final key = _cacheKey;
    if (_image != null && _builtKey == key) return;

    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    // 1.25× DPR is sharp enough at fit/moderate zoom and much cheaper on
    // page flips than a 2× raster (less main-thread toImage jank).
    var scale = dpr * 1.25;
    const maxEdge = 2048.0;
    final longest = math.max(widget.pageSize.width, widget.pageSize.height);
    if (longest * scale > maxEdge) {
      scale = maxEdge / longest;
    }
    final pixelWidth = math.max(1, (widget.pageSize.width * scale).round());
    final pixelHeight = math.max(1, (widget.pageSize.height * scale).round());
    final sx = pixelWidth / widget.pageSize.width;
    final sy = pixelHeight / widget.pageSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(sx, sy);
    PageBackgroundPainter(
      template: widget.template,
      pdfImage: widget.pdfImage,
      paper: widget.paper,
      infinite: false,
    ).paint(canvas, widget.pageSize);
    final picture = recorder.endRecording();

    final token = ++_token;
    final image = await picture.toImage(pixelWidth, pixelHeight);
    picture.dispose();
    if (!mounted || token != _token) {
      image.dispose();
      return;
    }
    _image?.dispose();
    setState(() {
      _image = image;
      _builtKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      // First frame / while regenerating after a paper change.
      return CustomPaint(
        size: widget.pageSize,
        isComplex: true,
        willChange: false,
        painter: PageBackgroundPainter(
          template: widget.template,
          pdfImage: widget.pdfImage,
          paper: widget.paper,
          infinite: false,
        ),
      );
    }
    return RawImage(
      image: image,
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }
}
