import 'package:flutter/material.dart';

/// The whole visual language, in one file. No screen defines its own colour,
/// radius or type size.
///
/// Refined dark, not tactical: a near-black ground, flat surfaces separated by
/// hairlines rather than by glow, sentence-case names in a geometric grotesque,
/// and monospaced uppercase kept for the small machine labels only (FUSE, SLOT
/// 01, 100% OFFLINE). Colour is an accent — a 2px edge, an icon, a dot — never a
/// filled field, so nothing on screen looks playful enough to give the app away
/// over a shoulder.
abstract final class ExitColors {
  /// App ground. Not pure black: the surfaces need something to sit on.
  static const Color bg = Color(0xFF0A0B0D);

  /// The card/row surface. One step up from the ground.
  static const Color surf = Color(0xFF121317);

  /// Sheets and anything that floats over the page.
  static const Color surf2 = Color(0xFF171920);

  /// The selected cell of a segmented control, and icon wells inside a row.
  static const Color raise = Color(0xFF1C1E26);

  /// Hairline between surfaces. White at 7%, so it works on every surface here.
  static const Color line = Color(0x12FFFFFF);

  /// The louder hairline: selected cells, sheet edges, dashed placeholders.
  static const Color line2 = Color(0x1FFFFFFF);

  static const Color hi = Color(0xFFE9EAEE);
  static const Color mid = Color(0xFF868B96);
  static const Color dim = Color(0xFF565B66);

  /// Category accents. Muted on purpose — recognisable, never candy.
  static const Color blue = Color(0xFF5680CF);
  static const Color amber = Color(0xFFD99A3C);
  static const Color violet = Color(0xFF8A72C8);
  static const Color red = Color(0xFFCF4A3C);
  static const Color teal = Color(0xFF3AA79E);
  static const Color yellow = Color(0xFFD9C23A);

  /// Green has one job: things the user made or confirmed. It is the editor's
  /// colour, the toggle colour, and the marker on imported audio.
  static const Color green = Color(0xFF48B585);

  /// Text on a filled green slab.
  static const Color onGreen = Color(0xFF06170F);

  /// The live emergency, and the app's own mark.
  static const Color danger = red;

  /// Faint green fill behind imported content.
  static const Color greenWash = Color(0x1448B585);
  static const Color greenLine = Color(0x4D48B585);

  /// The blackout screen only ever uses this one. Absolute black, no exceptions:
  /// a surface colour there would glow in a dark room.
  static const Color black = Color(0xFF000000);
}

/// Corner radii. The refined look is rounder than the old one: chips 8, controls
/// 11–12, rows 13, tiles 16, sheets 24.
abstract final class ExitRadius {
  static const BorderRadius chip = BorderRadius.all(Radius.circular(8));
  static const BorderRadius control = BorderRadius.all(Radius.circular(11));
  static const BorderRadius field = BorderRadius.all(Radius.circular(12));
  static const BorderRadius card = BorderRadius.all(Radius.circular(13));
  static const BorderRadius tile = BorderRadius.all(Radius.circular(16));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(24),
  );
}

/// The interface face. Space Grotesk ships as one variable file, so the weight
/// is chosen through [FontVariation] rather than by asset — see [sans].
const String kSans = 'SpaceGrotesk';

/// The machine face: small uppercase labels, counts, status lines.
const String kMono = 'JetBrainsMono';

const List<String> kSansFallback = <String>[
  'system-ui',
  'Roboto',
  'sans-serif',
];
const List<String> kMonoFallback = <String>[
  'monospace',
  'Menlo',
  'Courier New',
];

List<FontVariation> _wght(double weight) => <FontVariation>[
  FontVariation('wght', weight),
];

/// Interface type. [weight] is the variable axis value (400–700 here); the
/// matching [FontWeight] is set too so a fallback face still comes out right.
TextStyle sans(
  double size, {
  double weight = 400,
  Color color = ExitColors.hi,
  double letterSpacing = 0,
  double? height,
}) {
  return TextStyle(
    fontFamily: kSans,
    fontFamilyFallback: kSansFallback,
    fontVariations: _wght(weight),
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// Machine type. Always uppercase at the call site — this face is only used for
/// labels the app itself owns, never for anything the user typed.
TextStyle mono(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = ExitColors.mid,
  double letterSpacing = 1,
  double? height,
}) {
  return TextStyle(
    fontFamily: kMono,
    fontFamilyFallback: kMonoFallback,
    fontWeight: weight,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// The named roles. Anything not covered here builds its own with [sans] or
/// [mono] — but if a size shows up twice, it belongs in this list.
abstract final class ExitText {
  /// EXITPLAN in the home header.
  static TextStyle get brand => sans(20, weight: 600, letterSpacing: -0.3);

  /// Screen headings: All exits, Settings, New exit.
  static TextStyle get title => sans(18, weight: 600, letterSpacing: -0.3);

  /// The category screen's own name.
  static TextStyle get display => sans(23, weight: 600, letterSpacing: -0.5);

  /// A quick-exit tile's name.
  static TextStyle get tile => sans(16, weight: 600, letterSpacing: -0.2);

  /// A row's name, a settings toggle, a slot.
  static TextStyle get row => sans(13, weight: 500);

  /// Excuses and supporting copy on a tile.
  static TextStyle get body => sans(11, color: ExitColors.mid, height: 1.4);

  /// The same, one step down, inside a dense list row.
  static TextStyle get bodySmall =>
      sans(10, color: ExitColors.mid, height: 1.4);

  /// Captions over a control: FUSE, LOOP, TRIM WINDOW, LABEL.
  static TextStyle get caption =>
      mono(9, color: ExitColors.dim, letterSpacing: 1.5);

  /// Counts and status lines: 6 CATEGORIES · 47 SOUNDS.
  static TextStyle get meta => mono(10, letterSpacing: 1);

  /// The smallest label there is: SLOT 01, a tile's index.
  static TextStyle get badge =>
      mono(8, color: ExitColors.dim, letterSpacing: 1);
}

TextTheme _withVariations(TextTheme t) {
  final List<FontVariation> v = _wght(400);
  TextStyle? f(TextStyle? s) => s?.copyWith(fontVariations: v);
  return TextTheme(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

ThemeData buildExitTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: ExitColors.green,
    secondary: ExitColors.blue,
    surface: ExitColors.bg,
    error: ExitColors.red,
    onPrimary: ExitColors.onGreen,
    onSurface: ExitColors.hi,
  );

  // Space Grotesk is a variable font with a light default instance, so every
  // inherited style has to carry an explicit weight axis or unstyled text comes
  // out noticeably thinner than everything around it.
  final TextTheme text = _withVariations(
    const TextTheme().apply(
      fontFamily: kSans,
      bodyColor: ExitColors.hi,
      displayColor: ExitColors.hi,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ExitColors.bg,
    canvasColor: ExitColors.bg,
    fontFamily: kSans,
    fontFamilyFallback: kSansFallback,
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: ExitColors.line,
    iconTheme: const IconThemeData(color: ExitColors.hi, size: 20),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: ExitColors.surf2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: ExitRadius.card,
        side: BorderSide(color: ExitColors.line2),
      ),
    ),
  );
}

/// The one box shape used everywhere: flat fill, hairline border, rounded.
///
/// [accentTop] is what makes a tile a tile — a 2px edge in the category's colour
/// along the top, which is the only place a category's hue appears at size.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = ExitColors.surf,
    this.borderColor = ExitColors.line,
    this.radius = ExitRadius.card,
    this.accentTop,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final BorderRadius radius;
  final Color? accentTop;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color? accent = accentTop;
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (accent != null) {
      // A rounded box cannot carry a border with one differently coloured side,
      // so the accent is laid over the top edge and clipped back to the corner
      // curve — which is what a 2px top border would have drawn anyway.
      box = ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            box,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2,
              child: ColoredBox(color: accent),
            ),
          ],
        ),
      );
    }

    if (onTap == null && onLongPress == null) return box;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: box,
    );
  }
}

/// The mark: a rounded surface square holding one red dot. Drawn rather than
/// shipped as an image so it stays crisp at any size and costs nothing.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.color = ExitColors.red});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ExitColors.surf,
        borderRadius: BorderRadius.all(Radius.circular(size * 0.29)),
        border: Border.all(color: ExitColors.line2),
      ),
      child: Center(
        child: Container(
          width: size * 0.32,
          height: size * 0.32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// A small square of colour: the category marker in front of a group heading or
/// beside a picked category.
class CategoryDot extends StatelessWidget {
  const CategoryDot(this.color, {super.key, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}

/// The small mono pill on a row.
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    super.key,
    this.color = ExitColors.dim,
    this.borderColor = ExitColors.line,
    this.fontSize = 8,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(label, style: mono(fontSize, color: color)),
      ),
    );
  }
}

/// The marker on imported content: green, the one colour that never belongs to a
/// category, so user audio is separable at a glance.
class UserBadge extends StatelessWidget {
  const UserBadge({super.key, this.fontSize = 7});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TagChip(
      'USER',
      color: ExitColors.green,
      borderColor: ExitColors.greenLine,
      fontSize: fontSize,
    );
  }
}

/// A dot that pulses slowly. Used for LIVE on the black screen.
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    required this.color,
    this.size = 6,
    this.period = const Duration(milliseconds: 1600),
  });

  final Color color;
  final double size;
  final Duration period;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A blinking dot is exactly the sort of thing reduce-motion is for.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        // A soft breath rather than a blink: the refined look has no flashing
        // indicator lights, and on the black screen a hard blink is a beacon.
        return Opacity(
          opacity: 0.35 + 0.55 * (1 - _c.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// The primary action: one filled slab per screen, and the only filled surface
/// on a page of outlines. Green for anything that commits the user's own work
/// (Save exit), [ExitColors.hi] for the neutral one (Next).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.color = ExitColors.green,
    this.onColor = ExitColors.onGreen,
  });

  const PrimaryButton.neutral({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  }) : color = ExitColors.hi,
       onColor = ExitColors.bg;

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final bool live = enabled && onTap != null;
    return Semantics(
      button: true,
      enabled: live,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: live ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: live ? color : ExitColors.surf,
            borderRadius: ExitRadius.card,
            border: Border.all(color: live ? color : ExitColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(
                label,
                style: sans(
                  14,
                  weight: 600,
                  color: live ? onColor : ExitColors.dim,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The square icon buttons in a screen header.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color = ExitColors.mid,
    this.borderColor = ExitColors.line,
    this.size = 40,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color color;
  final Color borderColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: ExitColors.surf,
            borderRadius: BorderRadius.all(Radius.circular(size * 0.3)),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}

/// Back chevron / close cross in a screen header.
class BackChevron extends StatelessWidget {
  const BackChevron({
    super.key,
    this.icon = Icons.chevron_left,
    this.onTap,
    this.color = ExitColors.mid,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}

/// The pill switch used by every settings toggle.
class ExitSwitch extends StatelessWidget {
  const ExitSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value ? ExitColors.green : ExitColors.raise,
          borderRadius: const BorderRadius.all(Radius.circular(13)),
          border: Border.all(color: value ? ExitColors.green : ExitColors.line),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: value ? ExitColors.onGreen : ExitColors.dim,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// The last line above the safe area: TAP AN EXIT…, 100% OFFLINE…
class FooterNote extends StatelessWidget {
  const FooterNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: mono(9, color: ExitColors.dim, letterSpacing: 2),
      ),
    );
  }
}
