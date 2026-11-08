import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';

/// Tutors write explanations as plain text. Two light conventions give them
/// the Figma look without a schema change: `code` spans become monospace
/// chips and ``` fenced blocks become a code card.

const monoFontFamily = 'monospace';
const monoFontFallback = ['Menlo', 'Courier New'];

sealed class ExplanationSegment {
  const ExplanationSegment();
}

final class ExplanationParagraph extends ExplanationSegment {
  const ExplanationParagraph(this.text);

  final String text;
}

final class ExplanationCode extends ExplanationSegment {
  const ExplanationCode({required this.language, required this.code});

  final String language;
  final String code;
}

final _fence = RegExp(r'```([A-Za-z0-9_+#.-]*)[ \t]*\n?([\s\S]*?)```');
final _inlineCode = RegExp(r'`([^`\n]+)`');
final _wholeInlineCode = RegExp(r'^`([^`\n]+)`$');

List<ExplanationSegment> parseExplanation(String text) {
  final segments = <ExplanationSegment>[];
  var cursor = 0;
  for (final match in _fence.allMatches(text)) {
    final before = text.substring(cursor, match.start).trim();
    if (before.isNotEmpty) segments.add(ExplanationParagraph(before));
    final code = match.group(2)!.replaceFirst(RegExp(r'\s+$'), '');
    if (code.isNotEmpty) {
      segments.add(
        ExplanationCode(language: match.group(1)!.trim(), code: code),
      );
    }
    cursor = match.end;
  }
  final rest = text.substring(cursor).trim();
  if (rest.isNotEmpty) segments.add(ExplanationParagraph(rest));
  return segments;
}

/// [text] as a span in which `code` spans are [CodeChip]s. A text that is a
/// single code span becomes plain monospace instead. Shared by [InlineCodeText]
/// and the note reader's selectable paragraphs.
TextSpan inlineCodeSpan(String text, {required TextStyle style}) {
  final whole = _wholeInlineCode.firstMatch(text);
  if (whole != null) {
    return TextSpan(
      text: whole.group(1),
      style: InlineCodeText.monoStyle(style),
    );
  }
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _inlineCode.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: CodeChip(match.group(1)!, baseStyle: style),
      ),
    );
    cursor = match.end;
  }
  if (spans.isEmpty) return TextSpan(text: text, style: style);
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return TextSpan(style: style, children: spans);
}

/// Text in which `code` spans render as monospace chips. A label that is a
/// single code span renders as plain monospace text instead.
class InlineCodeText extends StatelessWidget {
  const InlineCodeText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text.rich(
    inlineCodeSpan(text, style: style),
    maxLines: maxLines,
    overflow: overflow,
  );

  static TextStyle monoStyle(TextStyle base) => base.copyWith(
    fontFamily: monoFontFamily,
    fontFamilyFallback: monoFontFallback,
    fontSize: (base.fontSize ?? 15) - 2,
    letterSpacing: 0.2,
  );
}

/// Small rounded chip for an inline code span.
class CodeChip extends StatelessWidget {
  const CodeChip(this.code, {super.key, required this.baseStyle});

  final String code;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: AppColors.noteHighlight,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      code,
      style: InlineCodeText.monoStyle(
        baseStyle,
      ).copyWith(color: AppColors.homeBrown, height: 1.3),
    ),
  );
}

/// Explanation paragraphs and code cards, stacked.
class ExplanationBody extends StatelessWidget {
  const ExplanationBody(this.text, {super.key});

  final String text;

  static const _paragraphStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 15,
    height: 1.6,
  );

  @override
  Widget build(BuildContext context) {
    final segments = parseExplanation(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < segments.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          switch (segments[index]) {
            ExplanationParagraph(:final text) => InlineCodeText(
              text,
              style: _paragraphStyle,
            ),
            ExplanationCode(:final language, :final code) =>
              ExplanationCodeCard(language: language, code: code),
          },
        ],
      ],
    );
  }
}

/// Paper-like code card. Long lines scroll sideways instead of wrapping.
class ExplanationCodeCard extends StatelessWidget {
  const ExplanationCodeCard({
    super.key,
    required this.language,
    required this.code,
  });

  final String language;
  final String code;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      color: AppColors.noteMemo,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                language.isEmpty ? 'Code' : _label(language),
                style: const TextStyle(
                  fontFamily: monoFontFamily,
                  fontFamilyFallback: monoFontFallback,
                  color: AppColors.homeMuted,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Text(
              '코드 예시',
              style: TextStyle(
                color: AppColors.homeSageDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Divider(height: 16, color: AppColors.border),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: monoFontFamily,
              fontFamilyFallback: monoFontFallback,
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  static String _label(String language) =>
      '${language[0].toUpperCase()}${language.substring(1)} Example';
}
