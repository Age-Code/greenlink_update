import 'package:flutter/material.dart';

/// Firebase 설정이 없을 때 흰 화면 대신 보여주는 안내 화면입니다.
///
/// `flutterfire configure` 를 실행해서 lib/firebase_options.dart 가
/// 실제 설정으로 바뀌면 이 화면은 더 이상 나오지 않습니다.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key, required this.error});

  /// Firebase 초기화 중에 난 에러 내용
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase 설정이 필요합니다')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 64),
                const SizedBox(height: 16),
                const Text(
                  '앱 코드는 준비되어 있지만,\n아직 Firebase 프로젝트에 연결되지 않았습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  '해야 할 일',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. 터미널에서  firebase login'),
                const Text('2. 프로젝트 폴더에서  flutterfire configure'),
                const Text('3. Firebase 콘솔에서 이메일 / Google 로그인 켜기'),
                const Text('4. 앱 다시 실행'),
                const SizedBox(height: 8),
                const Text('자세한 순서는 프로젝트 폴더의 FIREBASE_SETUP.md 에 있습니다.'),
                const SizedBox(height: 24),
                const Text(
                  '에러 내용',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
