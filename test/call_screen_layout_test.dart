import 'package:exitplan/widgets/call_themes/android_call_widgets.dart';
import 'package:exitplan/widgets/call_themes/call_visuals.dart';
import 'package:exitplan/widgets/call_themes/ios_call_widgets.dart';
import 'package:exitplan/widgets/call_themes/whatsapp_call_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pieces every fake-call screen is assembled from, tested directly since
/// the full screens reach into live audio/haptics/wakelock engines that need
/// a real device. What matters here is the contract every platform relies
/// on: a tap always fires, and a drag only confirms once it clears the real
/// gesture's threshold — a short drag must spring back, not answer the call.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

  group('CallAvatar', () {
    testWidgets('falls back to the caller\'s initial without a photo', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const CallAvatar(avatarPath: null, name: 'Priya', diameter: 80),
      );
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('shows "?" for a blank name rather than nothing', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const CallAvatar(avatarPath: null, name: '  ', diameter: 80),
      );
      expect(find.text('?'), findsOneWidget);
    });
  });

  group('CallActionButton', () {
    testWidgets('a plain tap fires immediately', (WidgetTester tester) async {
      int taps = 0;
      await pump(
        tester,
        CallActionButton(
          icon: Icons.call_rounded,
          background: Colors.green,
          iconColor: Colors.white,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.byIcon(Icons.call_rounded));
      expect(taps, 1);
    });
  });

  group('iOS incoming gestures', () {
    testWidgets('tapping decline fires, dragging accept short springs back', (
      WidgetTester tester,
    ) async {
      int declines = 0;
      int accepts = 0;
      await pump(
        tester,
        IosIncomingActions(
          onDecline: () => declines++,
          onAccept: () => accepts++,
        ),
      );

      await tester.tap(find.byIcon(Icons.call_end_rounded));
      expect(declines, 1);

      // Well short of the 64px threshold: must not answer. The accept
      // button pulses forever once it exists, so settle with a couple of
      // fixed pumps instead of pumpAndSettle, which would never return.
      await tester.drag(find.byIcon(Icons.call_rounded), const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 250));
      expect(accepts, 0);
    });

    testWidgets('dragging accept past the threshold answers', (
      WidgetTester tester,
    ) async {
      int accepts = 0;
      await pump(
        tester,
        IosIncomingActions(onDecline: () {}, onAccept: () => accepts++),
      );

      await tester.drag(find.byIcon(Icons.call_rounded), const Offset(0, -90));
      expect(accepts, 1);
    });
  });

  group('Android incoming gestures', () {
    testWidgets('both circles require a drag past the threshold', (
      WidgetTester tester,
    ) async {
      int declines = 0;
      int accepts = 0;
      await pump(
        tester,
        AndroidIncomingActions(
          onDecline: () => declines++,
          onAccept: () => accepts++,
        ),
      );

      // A tap alone must not end the call either way — Android's real
      // gesture is drag-only.
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.tap(find.byIcon(Icons.call_rounded));
      expect(declines, 0);
      expect(accepts, 0);

      await tester.drag(
        find.byIcon(Icons.call_end_rounded),
        const Offset(0, -90),
      );
      expect(declines, 1);

      await tester.drag(find.byIcon(Icons.call_rounded), const Offset(0, -90));
      expect(accepts, 1);
    });
  });

  group('WhatsApp incoming gestures', () {
    testWidgets('a plain tap on either circle is enough', (
      WidgetTester tester,
    ) async {
      int declines = 0;
      int accepts = 0;
      await pump(
        tester,
        WhatsAppIncomingActions(
          onDecline: () => declines++,
          onAccept: () => accepts++,
        ),
      );

      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.tap(find.byIcon(Icons.call_rounded));
      expect(declines, 1);
      expect(accepts, 1);
    });
  });
}
