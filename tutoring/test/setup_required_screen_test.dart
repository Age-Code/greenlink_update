import 'package:flutter_test/flutter_test.dart';
import 'package:tutoring/setup_required_screen.dart';

void main() {
  testWidgets('Firebase 설정이 없을 때 안내 화면이 보인다', (tester) async {
    await tester.pumpWidget(const SetupRequiredApp(error: '테스트 에러'));

    expect(find.text('Firebase 설정이 필요합니다'), findsOneWidget);
    expect(find.text('테스트 에러'), findsOneWidget);
  });
}
