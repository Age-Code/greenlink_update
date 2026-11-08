import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/core/router/app_routes.dart';

void main() {
  test('note reader route includes an encoded target block query', () {
    final location = AppRoutes.noteReader(
      'class-1',
      'note-1',
      targetBlockId: 'block / 한글',
    );

    final uri = Uri.parse(location);
    expect(uri.path, '/classes/class-1/notes/note-1');
    expect(uri.queryParameters['targetBlockId'], 'block / 한글');
  });

  test('note reader route stays at note top without a target block', () {
    expect(
      AppRoutes.noteReader('class-1', 'note-1'),
      '/classes/class-1/notes/note-1',
    );
    expect(
      AppRoutes.noteReader('class-1', 'note-1', targetBlockId: ''),
      '/classes/class-1/notes/note-1',
    );
  });
}
