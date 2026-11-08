import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/core/router/app_router.dart';
import 'package:tutoring/core/theme/app_scroll_behavior.dart';
import 'package:tutoring/core/theme/app_theme.dart';

class StudyTogetherApp extends ConsumerWidget {
  const StudyTogetherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tugether',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
