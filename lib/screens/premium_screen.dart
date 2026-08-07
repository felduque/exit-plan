import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/premium_config.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';
import '../services/billing_service.dart';
import '../state/app_state.dart';
import '../state/ui_flags.dart';
import '../widgets/tip_banner.dart';

/// The paywall, and the only place in the app that asks for money.
///
/// Deliberately plain. Everything else here is a panic button, and a screen
/// that suddenly shouts would be both off-brand and, in the moment someone is
/// showing the app to a friend, embarrassing. So: what you get, what it costs,
/// and a way out — no countdown, no crossed-out fake price, no "most popular"
/// on a tier that isn't.
///
/// It carries no [AdBannerSlot], obviously, and no upsell of its own: the user
/// is already here.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final BillingService _billing = BillingService.instance;

  @override
  void initState() {
    super.initState();
    _billing.addListener(_onBilling);
  }

  @override
  void dispose() {
    _billing.removeListener(_onBilling);
    super.dispose();
  }

  void _onBilling() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);

    return TipsSuppressor(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                child: Row(
                  children: <Widget>[
                    const BackChevron(),
                    Text('Premium', style: ExitText.title),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  children: <Widget>[
                    if (state.isPremium)
                      _ActiveNote(entitlement: state.entitlement)
                    else ...<Widget>[
                      const _Benefits(),
                      const SizedBox(height: 20),
                      ..._offer(),
                    ],
                  ],
                ),
              ),
              if (!state.isPremium) _RestoreRow(onRestore: _restore),
              const FooterNote('ONE DEVICE · NO ACCOUNT'),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _offer() {
    switch (_billing.phase) {
      case BillingPhase.unavailable:
        return const <Widget>[
          _Notice(
            'Play Billing is not available on this device, so Premium cannot '
            'be bought here. Everything else in the app works as it always has.',
          ),
        ];
      case BillingPhase.error:
        return <Widget>[
          _Notice(_billing.error ?? 'Something went wrong.'),
          const SizedBox(height: 12),
          PrimaryButton.neutral(label: 'Try again', onTap: _billing.loadProducts),
        ];
      case BillingPhase.loading:
        return const <Widget>[_Notice('Checking prices…')];
      case BillingPhase.pending:
      case BillingPhase.idle:
        final List<ProductDetails> products = _billing.products;
        if (products.isEmpty) {
          return const <Widget>[_Notice('No plans available right now.')];
        }
        return <Widget>[
          for (final ProductDetails product in products) ...<Widget>[
            _PlanCard(
              product: product,
              busy: _billing.phase == BillingPhase.pending,
              onTap: () => _billing.buy(product),
            ),
            const SizedBox(height: 9),
          ],
        ];
    }
  }

  /// Wrapped in [withModal] like every other blocking flow, so a tip banner
  /// cannot land on the buttons while Play's sheet is up.
  Future<void> _restore() => withModal(_billing.restore);
}

/// What the money actually buys. Four lines, no adjectives.
class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: ExitRadius.tile,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('PREMIUM', style: ExitText.caption),
          const SizedBox(height: 10),
          const _Line('No ads, anywhere in the app'),
          const _Line('Unlimited fake call templates'),
          const _Line('Unlimited imported sounds'),
          const _Line('Unlimited categories of your own'),
          const SizedBox(height: 12),
          Text(
            'The 47 built-in sounds and the four quick exits are free, and '
            'always will be. Premium only lifts the limits on what you add.',
            style: ExitText.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check, size: 14, color: ExitColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: ExitText.row)),
        ],
      ),
    );
  }
}

/// One purchasable plan. The price string comes from Play, already in the
/// user's currency — never formatted here, which would be wrong somewhere.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.busy,
    required this.onTap,
  });

  final ProductDetails product;
  final bool busy;
  final VoidCallback onTap;

  bool get _isLifetime => product.id == PremiumProducts.lifetime;

  String get _label => switch (product.id) {
    PremiumProducts.monthly => 'Monthly',
    PremiumProducts.yearly => 'Yearly',
    PremiumProducts.lifetime => 'One payment',
    _ => product.title,
  };

  String get _note => switch (product.id) {
    PremiumProducts.monthly => 'Renews every month · cancel anytime',
    PremiumProducts.yearly => 'Renews every year · cancel anytime',
    PremiumProducts.lifetime => 'Yours for good · nothing renews',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$_label, ${product.price}',
      child: Panel(
        onTap: busy ? null : onTap,
        radius: ExitRadius.tile,
        // The one-off is the tier this app can honestly recommend — there is no
        // server behind it, so nothing has to be paid for forever.
        borderColor: _isLifetime ? ExitColors.greenLine : ExitColors.line,
        color: _isLifetime ? ExitColors.greenWash : ExitColors.surf,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // The badge sits on its own line rather than beside the name.
                  // Name + badge + price on one row overflows a 360dp phone by
                  // ~29px, and the alternative — ellipsising the plan name —
                  // hides the thing the user is deciding between.
                  if (_isLifetime) ...<Widget>[
                    const TagChip(
                      'BEST VALUE',
                      color: ExitColors.green,
                      borderColor: ExitColors.greenLine,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(_label, style: ExitText.row),
                  const SizedBox(height: 3),
                  Text(_note, style: ExitText.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              product.price,
              style: sans(15, weight: 600, letterSpacing: -0.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown once the user has paid. Says what they have and, for a subscription,
/// where to cancel — hiding that is the sort of thing this app does not do.
class _ActiveNote extends StatelessWidget {
  const _ActiveNote({required this.entitlement});

  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final bool lifetime = entitlement.isLifetime;
    return Panel(
      radius: ExitRadius.tile,
      padding: const EdgeInsets.all(16),
      color: ExitColors.greenWash,
      borderColor: ExitColors.greenLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle, size: 16, color: ExitColors.green),
              const SizedBox(width: 9),
              // Flexible, not bare: "Premium — one payment" beside the icon
              // overflows a 360dp phone by 14px, and this line is a receipt —
              // it must never be the thing that breaks the screen someone
              // opens to confirm what they bought.
              Flexible(
                child: Text(
                  lifetime ? 'Premium — one payment' : 'Premium — active',
                  style: sans(13, weight: 600, color: ExitColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            lifetime
                ? 'No ads and no limits, for good. Nothing renews and there is '
                      'nothing to cancel.'
                : 'No ads and no limits. Manage or cancel it any time in the '
                      'Play Store, under Subscriptions.',
            style: ExitText.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Panel(
      radius: ExitRadius.tile,
      child: Text(text, style: ExitText.bodySmall),
    );
  }
}

/// Deliberately a quiet text row rather than a button. Someone who already paid
/// needs to find it; nobody else should be invited to press it.
class _RestoreRow extends StatelessWidget {
  const _RestoreRow({required this.onRestore});

  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRestore,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Restore a previous purchase',
              textAlign: TextAlign.center,
              style: sans(12, weight: 500, color: ExitColors.mid),
            ),
          ),
        ),
      ),
    );
  }
}
