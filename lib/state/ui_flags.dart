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

/// How many currently-mounted screens want the tip banner hidden. A counter
/// rather than a bool: screens can stack (an editor pushed from settings, say),
/// and the banner must stay hidden until every one of them is gone, not just
/// the last one to mount.
///
/// The banner is designed for exactly two screens — home and "all exits" — so
/// every other screen wraps itself in [TipsSuppressor] to opt out. That
/// matters most for the fake-call screens: a banner is exactly the kind of
/// thing that would give away a call nobody is really receiving.
final ValueNotifier<int> tipSuppressDepth = ValueNotifier<int>(0);

bool get tipsSuppressedByScreen => tipSuppressDepth.value > 0;
