import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutoring/app/study_together_app.dart';
import 'package:tutoring/firebase_options.dart';
import 'package:tutoring/setup_required_screen.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On the web Flutter leaves text selection menus to the browser and never
  // shows its own toolbar; the note reader's 강조 · 메모 · 북마크 toolbar
  // needs Flutter's, so the browser menu is turned off.
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(SetupRequiredApp(error: error.toString()));
    return;
  }
  FirebaseUIAuth.configureProviders([EmailAuthProvider()]);
  runApp(const ProviderScope(child: StudyTogetherApp()));
}
