import 'package:tutoring/features/classes/domain/entities/study_class.dart';
import 'package:tutoring/features/notes/domain/entities/study_note.dart';

/// One row of the home search: a class, or a published note of a class.
class HomeSearchResult {
  const HomeSearchResult.studyClass(this.studyClass) : note = null;

  const HomeSearchResult.note(this.studyClass, StudyNote this.note);

  final StudyClass studyClass;
  final StudyNote? note;

  bool get isNote => note != null;

  String get title => note?.title ?? studyClass.title;

  String get subtitle =>
      note == null
          ? 'Tutor · ${studyClass.tutorName}'
          : '${studyClass.title} · Week ${note!.week.toString().padLeft(2, '0')}';
}

/// Case-insensitive match on class titles, then on published note titles
/// of each class in [notesByClass]. An empty query has no results.
List<HomeSearchResult> searchHome(
  String query,
  List<StudyClass> classes,
  Map<String, List<StudyNote>> notesByClass,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final results = <HomeSearchResult>[];
  for (final studyClass in classes) {
    if (studyClass.title.toLowerCase().contains(needle)) {
      results.add(HomeSearchResult.studyClass(studyClass));
    }
  }
  for (final studyClass in classes) {
    for (final note in notesByClass[studyClass.id] ?? const <StudyNote>[]) {
      if (note.title.toLowerCase().contains(needle)) {
        results.add(HomeSearchResult.note(studyClass, note));
      }
    }
  }
  return results;
}
