import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ads_config.dart';
import '../core/theme.dart';
import '../services/ads_service.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';

/// The anchored banner, and the only place in this app an ad may appear.
///
/// ## Placement contract — not negotiable
///
/// This must be the **last child of a screen's outermost `Column`, inside its
/// `SafeArea`**, below any [FooterNote]. Never inside a `ListView`, never
/// inside the `Expanded`, never near a control that fires something.
///
/// That is the entire safety argument for putting ads in a panic-button app.
/// On home the quick-exit tiles live inside the `SingleChildScrollView` at the
/// top; between them and this banner sit the browse row, the calls row and the
/// footer note. A thumb reaching for an exit is nowhere near an ad.
///
/// It appears on six screens: home, settings, browse, category detail, calls
/// and the audio editor. The first five end in a footer or a list, which is the
/// shape this was designed for. The editor ends in a primary button instead and
/// is the deliberate exception — see the comment at its insertion point for the
/// two mitigations that buy the risk down.
///
/// `call_preset_editor_screen` has the same shape and does **not** carry one;
/// the reason is written there.
///
/// It must **never** appear on the blackout, fake-call or incoming-call
/// screens — those are the screens showing while an excuse is running.
///
/// ## The four rules
///
/// 1. **Reserve before loading.** The anchored-adaptive height is a step
///    function of screen height, knowable before any network call, so the space
///    is claimed on the first frame this widget exists. Nothing can move under
///    a thumb because an ad arrived late.
/// 2. **Collapse once, and only before the first fill.** No network means no
///    ad, and the app is used in basements and lifts — so a failed first load
///    collapses the reservation to nothing and the screen looks exactly as it
///    did before ads existed. But once an ad *has* rendered, the reservation is
///    permanent for the rest of the screen's life: a later failure leaves an
///    empty band rather than shifting buttons a thumb has already learned.
/// 3. **Never block a firing.** Everything here is asynchronous and nothing on
///    a fire path awaits it.
/// 4. **Die during a blackout.** [blackoutActive] is a route-lifetime flag and
///    home stays mounted underneath, so without this the banner would keep
///    running behind a black screen. That is an unviewable impression, which is
///    an AdMob policy violation, and it holds a WebView alive at the one moment
///    nothing matters except audio.
class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot>
    with WidgetsBindingObserver {
  BannerAd? _ad;

  /// True once an ad has actually rendered. Latches the reservation on.
  bool _everLoaded = false;

  bool _showing = false;
  bool _collapsed = false;
  double _reserved = 0;

  @override
  void initState() {
    super.initState();
    AdsService.initialized.addListener(_sync);
    blackoutActive.addListener(_sync);
    // The keyboard opening is a metrics change, not a MediaQuery change this
    // widget can see from inside a Scaffold body. Without this, rule 5 would
    // read a stale inset and never fire.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Both the reservation and whether we want an ad at all can change here:
    // MediaQuery for the first, the AppScope entitlement for the second.
    _reserved =
        AdsService.debugForcedHeight ??
        _anchoredHeightFor(MediaQuery.sizeOf(context).height);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    AdsService.initialized.removeListener(_sync);
    blackoutActive.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    // Not [_disposeAd]: that one calls setState to drop the ad out of the
    // tree, and setState during dispose asserts. Here the tree is going away
    // regardless, so the native ad just has to be released.
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  /// Google's anchored adaptive banner heights, which depend on the screen and
  /// not on the ad — which is exactly why the space can be reserved up front.
  static double _anchoredHeightFor(double screenHeight) {
    if (screenHeight <= 400) return 32;
    if (screenHeight <= 720) return 50;
    return 90;
  }

  bool get _wanted {
    if (_collapsed) return false;
    if (!AdsService.initialized.value) return false;
    if (blackoutActive.value) return false;
    return !AppScope.read(context).isPremium;
  }

  void _sync() {
    if (!mounted) return;
    if (!_wanted) {
      _disposeAd();
      return;
    }
    _load();
  }

  Future<void> _load() async {
    if (_ad != null) return;
    // The test seam stands in for the SDK: reserve the height, draw nothing,
    // touch no platform channel.
    if (AdsService.debugForcedHeight != null) return;

    // The real anchored adaptive size, matching the height reserved in
    // [didChangeDependencies]. Asking for a fixed AdSize.banner instead would
    // fill 50dp of a 90dp reservation on any phone taller than 720dp — which is
    // most of them — leaving a permanent dead band under the ad. Adaptive also
    // uses the full width, which is what Google prioritises in the auction.
    //
    // The deprecation on this call is accepted deliberately. Its replacement,
    // getLargeAnchoredAdaptiveBannerAdSize, returns a height documented only as
    // "no more than 15% of the screen" — a value this widget cannot predict
    // before asking, and predicting it is the whole basis of rule 1. Classic
    // anchored adaptive is a published step function, which is what
    // [_anchoredHeightFor] mirrors. Migrating means first solving how to
    // reserve a height nobody can compute synchronously.
    //
    // This is the only await on the path, and it resolves against the native
    // display metrics rather than the network. Nothing waits on it: the space
    // was claimed synchronously, frames ago.
    final int width = MediaQuery.sizeOf(context).width.truncate();
    final AdSize? size = await AdSize
        // ignore: deprecated_member_use
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || _ad != null) return;

    // Safety net for the paragraph above: if the platform disagrees with
    // [_anchoredHeightFor], correct the reservation rather than trust the
    // table. This is the one moment movement is harmless — no ad has rendered
    // yet, so nothing has taught a thumb where anything is.
    if (size.height.toDouble() != _reserved) {
      setState(() => _reserved = size.height.toDouble());
    }

    final BannerAd ad = BannerAd(
      adUnitId: AdsConfig.bannerUnitId,
      size: size,
      request: AdsService.request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _everLoaded = true;
            _showing = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _showing = false;
            // Rule 2: only a failure before the first successful fill is
            // allowed to reclaim the space. No retry is scheduled either —
            // one quiet collapse beats a banner that blinks in and out.
            if (!_everLoaded) _collapsed = true;
          });
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  void _disposeAd() {
    if (_ad == null) return;
    _ad!.dispose();
    _ad = null;
    if (mounted) setState(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Subscribes to entitlement changes, so buying premium removes the banner
    // without a restart. Also renders nothing at all — no reservation, no
    // divider — so a paying user's layout is byte-for-byte the pre-ads one.
    if (AppScope.of(context).isPremium) return const SizedBox.shrink();

    // Rule 5: never share the screen with an open keyboard.
    //
    // On a screen with a text field, the default resizeToAvoidBottomInset
    // shrinks the viewport and a bottom-anchored banner rides up with it —
    // landing directly between the keyboard and whatever button sits above,
    // which is the adjacency this whole widget exists to avoid. Yielding is
    // free: someone typing is not reading ads, and the layout is already
    // moving because of the keyboard, so this is not a surprise shift.
    //
    // Read from the View, not from MediaQuery. A Scaffold with
    // resizeToAvoidBottomInset consumes the bottom inset and hands its body a
    // MediaQuery where it is always zero — so the obvious
    // MediaQuery.viewInsetsOf(context) here silently never fires. The rebuild
    // comes from [didChangeMetrics].
    if (View.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdsService.initialized,
      builder: (BuildContext context, bool ready, _) {
        if (!ready || _collapsed) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: blackoutActive,
          builder: (BuildContext context, bool dark, _) {
            final bool visible = _showing && !dark && _ad != null;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: _reserved,
              // A hairline, the same one that separates every other surface in
              // this app. It reads as chrome rather than as content, which is
              // both the design rule and AdMob's requirement that an ad not be
              // confusable with the app around it.
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ExitColors.line)),
              ),
              child: visible
                  ? AdWidget(ad: _ad!)
                  : const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}
