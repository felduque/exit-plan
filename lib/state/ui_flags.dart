import 'package:flutter/foundation.dart';

/// True while the black screen is on top.
///
/// Overlays that sit above the whole navigator (the tip banner) watch this so
/// they never draw over the blackout — a banner glowing on a "pocketed" phone
/// would give the excuse away.
final ValueNotifier<bool> blackoutActive = ValueNotifier<bool>(false);

/// True while a sheet or dialog is asking the user something.
///
/// Same reason as [blackoutActive], different failure: the tip banner sits at
/// the bottom of the screen, which is exactly where a bottom sheet puts its
/// CANCEL button. A tip must never land on top of a button.
final ValueNotifier<bool> modalActive = ValueNotifier<bool>(false);

/// Runs [body] with [modalActive] held, restoring it however [body] ends.
Future<T> withModal<T>(Future<T> Function() body) async {
  modalActive.value = true;
  try {
    return await body();
  } finally {
    modalActive.value = false;
  }
}
