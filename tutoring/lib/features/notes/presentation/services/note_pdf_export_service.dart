import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tutoring/features/notes/domain/entities/note_block.dart';
import 'package:tutoring/features/notes/domain/entities/study_annotation.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

class NotePdfExportService {
  const NotePdfExportService();

  Future<void> export({
    required StudyNote note,
    required String classTitle,
    required List<NoteBlock> blocks,
    required List<StudyAnnotation> annotations,
    required bool includePersonalAnnotations,
  }) async {
    final regular = await PdfGoogleFonts.notoSansKRRegular();
    final bold = await PdfGoogleFonts.notoSansKRBold();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            '$classTitle · Tugether',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            'Week ${note.week.toString().padLeft(2, '0')}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            note.title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          if (note.summary.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              note.summary,
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 5,
                color: PdfColors.grey700,
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          for (final block in blocks)
            _buildBlock(
              block,
              includePersonalAnnotations
                  ? annotations
                      .where((annotation) => annotation.blockId == block.id)
                      .toList(growable: false)
                  : const <StudyAnnotation>[],
            ),
          if (includePersonalAnnotations) ...[
            ...annotations
                .where(
                  (annotation) =>
                      annotation.type == AnnotationType.memo &&
                      annotation.blockId == null,
                )
                .map(
                  (memo) => pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FFF6F1'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text('내 메모 · ${memo.content}'),
                  ),
                ),
          ],
        ],
      ),
    );
    final safeTitle = note.title.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_-]'), '_');
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: '${safeTitle.isEmpty ? 'Tugether_note' : safeTitle}.pdf',
    );
  }

  pw.Widget _buildBlock(
    NoteBlock block,
    List<StudyAnnotation> annotations,
  ) {
    final lineCount = (block.content.length / 48).ceil().clamp(1, 12);
    final height = switch (block.type) {
      NoteBlockType.heading || NoteBlockType.heading2 || NoteBlockType.heading3 =>
        48.0,
      NoteBlockType.quiz => 72.0,
      _ => (lineCount * 18 + 30).toDouble(),
    };
    final blockMemos = annotations
        .where((annotation) => annotation.type == AnnotationType.memo)
        .toList(growable: false);
    final hasTextHighlight = annotations.any(
      (annotation) => annotation.type == AnnotationType.highlight,
    );
    final drawingAnnotations = annotations
        .where(
          (annotation) => annotation.type == AnnotationType.drawing ||
              annotation.type == AnnotationType.freehandHighlight,
        )
        .toList(growable: false);
    final textAnnotations = annotations
        .where((annotation) => annotation.type == AnnotationType.text)
        .toList(growable: false);

    if (drawingAnnotations.isEmpty && textAnnotations.isEmpty) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _blockContent(block, highlighted: hasTextHighlight),
            for (final memo in blockMemos)
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 5),
                padding: const pw.EdgeInsets.all(7),
                color: PdfColor.fromHex('#FFF6F1'),
                child: pw.Text(
                  '내 메모 · ${memo.content}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: height,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: _blockContent(block, highlighted: hasTextHighlight),
                ),
                if (drawingAnnotations.isNotEmpty)
                  pw.Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: pw.CustomPaint(
                      painter: (canvas, size) {
                        for (final annotation in drawingAnnotations) {
                          for (final stroke in annotation.strokes) {
                            if (stroke.points.isEmpty) continue;
                            canvas
                              ..setStrokeColor(PdfColor.fromInt(stroke.colorValue))
                              ..setLineWidth(stroke.width)
                              ..moveTo(
                                stroke.points.first.x * size.x,
                                (1 - stroke.points.first.y) * size.y,
                              );
                            for (final point in stroke.points.skip(1)) {
                              canvas.lineTo(
                                point.x * size.x,
                                (1 - point.y) * size.y,
                              );
                            }
                            canvas.strokePath();
                          }
                        }
                      },
                    ),
                  ),
                for (final annotation in textAnnotations)
                  pw.Positioned(
                    left: (annotation.positionX ?? .05) * 420,
                    top: (annotation.positionY ?? .05) * (height - 20),
                    child: pw.Container(
                      constraints: const pw.BoxConstraints(maxWidth: 150),
                      padding: const pw.EdgeInsets.all(4),
                      color: PdfColor.fromHex('#FFF6F1'),
                      child: pw.Text(
                        annotation.content,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final memo in blockMemos)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 5),
              padding: const pw.EdgeInsets.all(7),
              color: PdfColor.fromHex('#FFF6F1'),
              child: pw.Text(
                '내 메모 · ${memo.content}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _blockContent(NoteBlock block, {bool highlighted = false}) {
    if (block.type == NoteBlockType.paragraph && highlighted) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(7),
        color: PdfColor.fromHex('#FFF1E9'),
        child: pw.Text(
          block.content,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 5),
        ),
      );
    }
    return switch (block.type) {
        NoteBlockType.heading => pw.Text(
            block.content,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        NoteBlockType.heading2 => pw.Text(
            block.content,
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
          ),
        NoteBlockType.heading3 => pw.Text(
            block.content,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        NoteBlockType.code => pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#211C1A'),
            child: pw.Text(
              block.content,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
            ),
          ),
        NoteBlockType.quote => pw.Container(
            padding: const pw.EdgeInsets.only(left: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: PdfColors.deepOrange)),
            ),
            child: pw.Text(block.content),
          ),
        NoteBlockType.callout => pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#FFF6F1'),
            child: pw.Text(block.content),
          ),
        NoteBlockType.quiz => pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#FFF6F1'),
            child: pw.Text('Quick Check · 앱에서 문제를 풀어보세요.'),
          ),
        _ => pw.Text(
            block.content,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 5),
          ),
      };
  }
}
