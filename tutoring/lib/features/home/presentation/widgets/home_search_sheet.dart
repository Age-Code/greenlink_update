import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutoring/core/router/app_routes.dart';
import 'package:tutoring/core/theme/app_colors.dart';
import 'package:tutoring/core/theme/app_tokens.dart';
import 'package:tutoring/core/widgets/app_adaptive_sheet.dart';
import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/classes/presentation/controllers/class_providers.dart';
import 'package:tutoring/features/home/presentation/controllers/home_search.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';
import 'package:tutoring/features/notes/presentation/controllers/note_providers.dart';

/// Home search: my classes by name plus their published notes by title.
/// Opens the class home or the note reader from the tapped row.
Future<void> showHomeSearchSheet(
  BuildContext context, {
  required String userId,
}) {
  final router = GoRouter.of(context);
  return showAppSheet<void>(
    context: context,
    builder:
        (_) => HomeSearchSheet(
          userId: userId,
          onOpen: (location) => router.push(location),
        ),
  );
}

class HomeSearchSheet extends ConsumerStatefulWidget {
  const HomeSearchSheet({
    super.key,
    required this.userId,
    required this.onOpen,
  });

  final String userId;

  /// Called with the route location after the sheet has closed.
  final ValueChanged<String> onOpen;

  static Key resultKey(HomeSearchResult result) =>
      Key('search-${result.isNote ? result.note!.id : result.studyClass.id}');

  @override
  ConsumerState<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends ConsumerState<HomeSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(HomeSearchResult result) {
    final note = result.note;
    final location =
        note == null
            ? AppRoutes.classDetail(result.studyClass.id)
            : AppRoutes.noteReader(result.studyClass.id, note.id);
    Navigator.of(context).pop();
    widget.onOpen(location);
  }

  @override
  Widget build(BuildContext context) {
    final classes =
        ref.watch(myClassesProvider(widget.userId)).asData?.value ??
        const <StudyClass>[];
    final notesByClass = <String, List<StudyNote>>{
      for (final studyClass in classes)
        studyClass.id:
            ref.watch(publishedNotesProvider(studyClass.id)).asData?.value ??
            const <StudyNote>[],
    };
    final query = _controller.text;
    final results = searchHome(query, classes, notesByClass);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + keyboard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '검색',
            style: TextStyle(
              color: AppColors.homeInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '클래스 이름이나 노트 제목을 입력하세요',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon:
                  query.isEmpty
                      ? null
                      : IconButton(
                        tooltip: '검색 지우기',
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (query.trim().isEmpty)
            const _SearchHint('내 클래스 이름과 게시된 노트 제목에서 찾아요.')
          else if (results.isEmpty)
            const _SearchHint('검색 결과가 없어요.')
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder:
                    (_, _) =>
                        const Divider(height: 1, color: AppColors.homeDivider),
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _ResultRow(
                    key: HomeSearchSheet.resultKey(result),
                    result: result,
                    onTap: () => _open(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({super.key, required this.result, required this.onTap});

  final HomeSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: result.isNote ? AppColors.homeCream : AppColors.homeSage,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              result.isNote
                  ? Icons.description_outlined
                  : Icons.auto_stories_outlined,
              size: 18,
              color:
                  result.isNote ? AppColors.homeBrown : AppColors.homeSageDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.homeInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
        ],
      ),
    ),
  );
}
