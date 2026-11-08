import 'package:flutter/material.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

/// Bottom of the reader (Figma 06): the "다음 장" peek plus the previous /
/// next section links. One row on tablet and desktop; on mobile the two
/// links stack under the peek as full-width 48px rows.
class NoteReaderFooter extends StatelessWidget {
  const NoteReaderFooter({
    super.key,
    required this.previous,
    required this.next,
    required this.onOpen,
  });

  final StudyNote? previous;
  final StudyNote? next;
  final ValueChanged<StudyNote> onOpen;

  static const previousKey = Key('reader-previous');
  static const nextKey = Key('reader-next');

  @override
  Widget build(BuildContext context) {
    final compact = context.screenType == ScreenType.mobile;
    final peek = _NextChapterPeek(next: next);
    final previousButton = _NavButton(
      key: previousKey,
      label: '← 이전 섹션',
      color: AppColors.textSecondary,
      expanded: compact,
      onPressed: previous == null ? null : () => onOpen(previous!),
    );
    final nextButton = _NavButton(
      key: nextKey,
      label: '다음 섹션 읽기 →',
      color: AppColors.coral,
      emphasized: true,
      expanded: compact,
      onPressed: next == null ? null : () => onOpen(next!),
    );
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.only(top: 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.homeDivider)),
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  peek,
                  const SizedBox(height: 16),
                  previousButton,
                  const SizedBox(height: 4),
                  nextButton,
                ],
              )
              : Row(
                children: [
                  Expanded(child: peek),
                  const SizedBox(width: 16),
                  previousButton,
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '·',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  nextButton,
                ],
              ),
    );
  }
}

class _NextChapterPeek extends StatelessWidget {
  const _NextChapterPeek({required this.next});

  final StudyNote? next;

  static const _style = TextStyle(color: AppColors.textSecondary, fontSize: 14);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.menu_book_outlined,
        size: 16,
        color: AppColors.textSecondary,
      ),
      const SizedBox(width: 8),
      Expanded(
        child:
            next == null
                ? const Text('마지막 노트예요', style: _style)
                : Text.rich(
                  TextSpan(
                    style: _style,
                    children: [
                      const TextSpan(text: '다음 장: '),
                      TextSpan(
                        text: next!.title,
                        style: const TextStyle(
                          color: AppColors.homeInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
      ),
    ],
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.emphasized = false,
    this.expanded = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool emphasized;

  /// Mobile: full-width row with the label at the left edge.
  final bool expanded;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: AppColors.textFaint,
      minimumSize: const Size(0, AppLayout.minTouchHeight),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 0 : 8),
      alignment: expanded ? Alignment.centerLeft : Alignment.center,
      textStyle: TextStyle(
        fontSize: 14,
        fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
    child: Text(label),
  );
}
