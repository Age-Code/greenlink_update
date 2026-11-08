import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/features/classes/data/dtos/study_class_dto.dart';

void main() {
  test('StudyClassDto ignores the legacy progress and recentTopic fields', () {
    final dto = StudyClassDto.fromMap('class-id', {
      'title': 'Python Study',
      'tutorId': 'tutor-id',
      'tutorName': 'Tutor',
      'inviteCode': 'STUDY-ABC123',
      'progress': 0.654,
      'recentTopic': 'Dictionary',
      'memberCount': 3,
    });

    final studyClass = dto.toDomain();
    expect(studyClass.title, 'Python Study');
    expect(studyClass.memberCount, 3);
    expect(dto.toFirestore().containsKey('progress'), isFalse);
    expect(dto.toFirestore().containsKey('recentTopic'), isFalse);
  });
}
