import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_boot.dart';
import 'state/app_state.dart';

/// EXITPLAN — excuse sounds that get you out of a room or off a call.
///
/// 100% offline by design: no backend, no accounts, no analytics, no network of
/// any kind. Everything lives on the device. If something here looks like it
/// needs a server, the approach is wrong.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ),
  );

  // The native splash covers this. Nothing may read a setting before the user's
  // own settings have actually been loaded.
  await initAudio();
  final AppState state = await AppState.bootstrap();

  runApp(ExitApp(state: state));
}
