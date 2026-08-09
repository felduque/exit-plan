import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/premium_config.dart';
import '../core/theme.dart';
import '../data/entitlement.dart';
import '../l10n/app_localizations.dart';
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
    final AppLocalizations loc = AppLocalizations.of(context);

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
                    Text(loc.premiumTitle, style: ExitText.title),
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
                      ..._offer(loc),
                    ],
                  ],
                ),
              ),
              if (!state.isPremium) _RestoreRow(onRestore: _restore),
              FooterNote(loc.premiumFooter),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _offer(AppLocalizations loc) {
    switch (_billing.phase) {
      case BillingPhase.unavailable:
        return <Widget>[_Notice(loc.premiumBillingUnavailable)];
      case BillingPhase.error:
        return <Widget>[
          _Notice(_billing.error ?? loc.premiumErrorGeneric),
          const SizedBox(height: 12),
          PrimaryButton.neutral(
            label: loc.premiumTryAgain,
            onTap: _billing.loadProducts,
          ),
        ];
      case BillingPhase.loading:
        return <Widget>[_Notice(loc.premiumCheckingPrices)];
      case BillingPhase.pending:
      case BillingPhase.idle:
        final List<ProductDetails> products = _billing.products;
        if (products.isEmpty) {
          return <Widget>[_Notice(loc.premiumNoPlans)];
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
    final AppLocalizations loc = AppLocalizations.of(context);

    return Panel(
      radius: ExitRadius.tile,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(loc.premiumBenefitsCaption, style: ExitText.caption),
          const SizedBox(height: 10),
          _Line(loc.premiumBenefitNoAds),
          _Line(loc.premiumBenefitUnlimitedCalls),
          _Line(loc.premiumBenefitUnlimitedSounds),
          _Line(loc.premiumBenefitUnlimitedCategories),
          const SizedBox(height: 12),
          Text(loc.premiumBenefitsFooter, style: ExitText.bodySmall),
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

  String _label(AppLocalizations loc) => switch (product.id) {
    PremiumProducts.monthly => loc.premiumPlanMonthly,
    PremiumProducts.yearly => loc.premiumPlanYearly,
    PremiumProducts.lifetime => loc.premiumPlanLifetime,
    _ => product.title,
  };

  String _note(AppLocalizations loc) => switch (product.id) {
    PremiumProducts.monthly => loc.premiumNoteMonthly,
    PremiumProducts.yearly => loc.premiumNoteYearly,
    PremiumProducts.lifetime => loc.premiumNoteLifetime,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final String label = _label(loc);

    return Semantics(
      button: true,
      label: loc.premiumPlanSemantics(label, product.price),
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
                    TagChip(
                      loc.premiumBestValue,
                      color: ExitColors.green,
                      borderColor: ExitColors.greenLine,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(label, style: ExitText.row),
                  const SizedBox(height: 3),
                  Text(_note(loc), style: ExitText.bodySmall),
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
    final AppLocalizations loc = AppLocalizations.of(context);
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
                  lifetime
                      ? loc.premiumActiveLifetime
                      : loc.premiumActiveSubscription,
                  style: sans(13, weight: 600, color: ExitColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            lifetime
                ? loc.premiumActiveLifetimeDetail
                : loc.premiumActiveSubscriptionDetail,
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
              AppLocalizations.of(context).premiumRestorePurchase,
              textAlign: TextAlign.center,
              style: sans(12, weight: 500, color: ExitColors.mid),
            ),
          ),
        ),
      ),
    );
  }
}
