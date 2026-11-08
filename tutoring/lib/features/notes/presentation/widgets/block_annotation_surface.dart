import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_annotation_session_controller.dart';

class BlockAnnotationSurface extends StatefulWidget {
  const BlockAnnotationSurface({
    super.key,
    required this.blockId,
    required this.annotations,
    required this.mode,
    required this.tool,
    required this.visible,
    required this.strokeWidth,
    required this.colorValue,
    required this.onAddStroke,
    required this.onAddText,
    required this.onUpdateText,
    required this.onDelete,
    required this.child,
  });

  final String blockId;
  final List<StudyAnnotation> annotations;
  final NoteReaderMode mode;
  final AnnotationTool tool;
  final bool visible;
  final double strokeWidth;
  final int colorValue;
  final void Function(AnnotationStroke stroke, AnnotationType type) onAddStroke;
  final void Function(String content, double x, double y) onAddText;
  final void Function(
    StudyAnnotation annotation, {
    String? content,
    double? x,
    double? y,
  }) onUpdateText;
  final ValueChanged<StudyAnnotation> onDelete;
  final Widget child;

  @override
  State<BlockAnnotationSurface> createState() => _BlockAnnotationSurfaceState();
}

class _BlockAnnotationSurfaceState extends State<BlockAnnotationSurface> {
  final List<AnnotationPoint> _activePoints = <AnnotationPoint>[];

  List<StudyAnnotation> get _blockAnnotations => widget.annotations
      .where((annotation) => annotation.blockId == widget.blockId)
      .where(
        (annotation) => annotation.type == AnnotationType.drawing ||
            annotation.type == AnnotationType.freehandHighlight ||
            annotation.type == AnnotationType.text,
      )
      .toList(growable: false);

  bool get _isDrawing => widget.tool == AnnotationTool.pen ||
      widget.tool == AnnotationTool.highlighter;

  AnnotationPoint _normalized(Offset offset, Size size) => AnnotationPoint(
        x: (offset.dx / math.max(size.width, 1)).clamp(0, 1).toDouble(),
        y: (offset.dy / math.max(size.height, 1)).clamp(0, 1).toDouble(),
      );

  void _onPanStart(DragStartDetails details, Size size) {
    if (_isDrawing) {
      setState(() {
        _activePoints
          ..clear()
          ..add(_normalized(details.localPosition, size));
      });
    } else if (widget.tool == AnnotationTool.eraser) {
      _eraseAt(_normalized(details.localPosition, size));
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_isDrawing) {
      setState(() => _activePoints.add(_normalized(details.localPosition, size)));
    } else if (widget.tool == AnnotationTool.eraser) {
      _eraseAt(_normalized(details.localPosition, size));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing || _activePoints.isEmpty) return;
    final highlighter = widget.tool == AnnotationTool.highlighter;
    final highlighterColor =
        (widget.colorValue & 0x00FFFFFF) | 0x66000000;
    widget.onAddStroke(
      AnnotationStroke(
        points: List<AnnotationPoint>.unmodifiable(_activePoints),
        width: highlighter
            ? math.max(10.0, widget.strokeWidth * 4.5).toDouble()
            : widget.strokeWidth,
        colorValue: highlighter ? highlighterColor : widget.colorValue,
      ),
      highlighter
          ? AnnotationType.freehandHighlight
          : AnnotationType.drawing,
    );
    setState(_activePoints.clear);
  }

  void _eraseAt(AnnotationPoint point) {
    const radius = .045;
    for (final annotation in _blockAnnotations.reversed) {
      if (annotation.type == AnnotationType.text) {
        final dx = (annotation.positionX ?? 0) - point.x;
        final dy = (annotation.positionY ?? 0) - point.y;
        if (math.sqrt(dx * dx + dy * dy) <= radius * 1.8) {
          widget.onDelete(annotation);
          return;
        }
      }
      for (final stroke in annotation.strokes) {
        for (final candidate in stroke.points) {
          final dx = candidate.x - point.x;
          final dy = candidate.y - point.y;
          if (math.sqrt(dx * dx + dy * dy) <= radius) {
            widget.onDelete(annotation);
            return;
          }
        }
      }
    }
  }

  Future<void> _addText(AnnotationPoint point) async {
    final content = await _textDialog(context, title: '텍스트 필기');
    if (content == null || content.trim().isEmpty) return;
    widget.onAddText(content, point.x, point.y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (widget.visible)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AnnotationPainter(
                    annotations: _blockAnnotations,
                    activePoints: _activePoints,
                    activeTool: widget.tool,
                    activeStrokeWidth: widget.strokeWidth,
                    activeColorValue: widget.colorValue,
                  ),
                ),
              ),
            ),
          if (widget.mode == NoteReaderMode.annotate)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: widget.tool == AnnotationTool.text
                    ? (details) => _addText(
                          _normalized(details.localPosition, context.size ?? Size.zero),
                        )
                    : widget.tool == AnnotationTool.eraser
                        ? (details) => _eraseAt(
                              _normalized(
                                details.localPosition,
                                context.size ?? Size.zero,
                              ),
                            )
                        : null,
                onPanStart: (details) =>
                    _onPanStart(details, context.size ?? Size.zero),
                onPanUpdate: (details) =>
                    _onPanUpdate(details, context.size ?? Size.zero),
                onPanEnd: _onPanEnd,
              ),
            ),
          if (widget.visible)
            for (final annotation in _blockAnnotations.where(
              (item) => item.type == AnnotationType.text,
            ))
              Positioned.fill(
                child: _TextAnnotationChip(
                  key: ValueKey(annotation.id),
                  annotation: annotation,
                  editable: widget.mode == NoteReaderMode.annotate,
                  onUpdate: widget.onUpdateText,
                  onDelete: () => widget.onDelete(annotation),
                ),
              ),
        ],
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  const _AnnotationPainter({
    required this.annotations,
    required this.activePoints,
    required this.activeTool,
    required this.activeStrokeWidth,
    required this.activeColorValue,
  });

  final List<StudyAnnotation> annotations;
  final List<AnnotationPoint> activePoints;
  final AnnotationTool activeTool;
  final double activeStrokeWidth;
  final int activeColorValue;

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      if (annotation.type == AnnotationType.text) continue;
      for (final stroke in annotation.strokes) {
        _drawStroke(canvas, size, stroke);
      }
    }
    if (activePoints.isNotEmpty) {
      final highlighter = activeTool == AnnotationTool.highlighter;
      final highlighterColor =
          (activeColorValue & 0x00FFFFFF) | 0x66000000;
      _drawStroke(
        canvas,
        size,
        AnnotationStroke(
          points: activePoints,
          width: highlighter
              ? math.max(10.0, activeStrokeWidth * 4.5).toDouble()
              : activeStrokeWidth,
          colorValue: highlighter ? highlighterColor : activeColorValue,
        ),
      );
    }
  }

  void _drawStroke(Canvas canvas, Size size, AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    final first = stroke.points.first;
    path.moveTo(first.x * size.width, first.y * size.height);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    if (stroke.points.length == 1) {
      path.lineTo(first.x * size.width + .1, first.y * size.height + .1);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

class _TextAnnotationChip extends StatefulWidget {
  const _TextAnnotationChip({
    super.key,
    required this.annotation,
    required this.editable,
    required this.onUpdate,
    required this.onDelete,
  });

  final StudyAnnotation annotation;
  final bool editable;
  final void Function(
    StudyAnnotation annotation, {
    String? content,
    double? x,
    double? y,
  }) onUpdate;
  final VoidCallback onDelete;

  @override
  State<_TextAnnotationChip> createState() => _TextAnnotationChipState();
}

class _TextAnnotationChipState extends State<_TextAnnotationChip> {
  late double _x = widget.annotation.positionX ?? .05;
  late double _y = widget.annotation.positionY ?? .05;

  @override
  void didUpdateWidget(covariant _TextAnnotationChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.annotation.updatedAt != widget.annotation.updatedAt) {
      _x = widget.annotation.positionX ?? .05;
      _y = widget.annotation.positionY ?? .05;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment(_x * 2 - 1, _y * 2 - 1),
          child: GestureDetector(
            onTap: widget.editable
                ? () async {
                    final content = await _textDialog(
                      context,
                      title: '텍스트 필기 수정',
                      initialValue: widget.annotation.content,
                    );
                    if (content != null && content.trim().isNotEmpty) {
                      widget.onUpdate(widget.annotation, content: content.trim());
                    }
                  }
                : null,
            onLongPress: widget.editable ? widget.onDelete : null,
            onPanUpdate: widget.editable
                ? (details) => setState(() {
                    _x = (_x + details.delta.dx / constraints.maxWidth)
                        .clamp(0, 1)
                        .toDouble();
                    _y = (_y + details.delta.dy / constraints.maxHeight)
                        .clamp(0, 1)
                        .toDouble();
                  })
                : null,
            onPanEnd: widget.editable
                ? (_) => widget.onUpdate(widget.annotation, x: _x, y: _y)
                : null,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.noteMemo.withValues(alpha: .94),
                border: Border.all(color: AppColors.coralSoft),
                borderRadius: BorderRadius.circular(7),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 5),
                ],
              ),
              child: Text(
                widget.annotation.content,
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ),
        ),
      );
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: '노트 위에 남길 내용을 입력하세요.',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('저장'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
