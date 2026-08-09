import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get introSkip;

  /// Chip above each intro step's title.
  ///
  /// In en, this message translates to:
  /// **'STEP 0{step} · {kicker}'**
  String introStepLabel(int step, String kicker);

  /// No description provided for @introLanguageKicker.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get introLanguageKicker;

  /// No description provided for @introLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your\nlanguage.'**
  String get introLanguageTitle;

  /// No description provided for @introLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'English or Spanish, for now. Change it anytime later from Settings.'**
  String get introLanguageBody;

  /// No description provided for @introKicker0.
  ///
  /// In en, this message translates to:
  /// **'THE EXIT'**
  String get introKicker0;

  /// No description provided for @introKicker1.
  ///
  /// In en, this message translates to:
  /// **'DELAY FUSE'**
  String get introKicker1;

  /// No description provided for @introKicker2.
  ///
  /// In en, this message translates to:
  /// **'FOUR SLOTS'**
  String get introKicker2;

  /// No description provided for @introKicker3.
  ///
  /// In en, this message translates to:
  /// **'FAKE CALLS'**
  String get introKicker3;

  /// No description provided for @introTitle0.
  ///
  /// In en, this message translates to:
  /// **'Tap it and\nthe room\nchanges.'**
  String get introTitle0;

  /// No description provided for @introTitle1.
  ///
  /// In en, this message translates to:
  /// **'Arm it, then\npocket the\nphone.'**
  String get introTitle1;

  /// No description provided for @introTitle2.
  ///
  /// In en, this message translates to:
  /// **'Four exits,\nalways one\ntap away.'**
  String get introTitle2;

  /// No description provided for @introTitle3.
  ///
  /// In en, this message translates to:
  /// **'A call\nthat looks\nreal.'**
  String get introTitle3;

  /// No description provided for @introBody0.
  ///
  /// In en, this message translates to:
  /// **'The screen goes completely black and the sound fires in a loop. It looks like the phone is in your pocket and the noise is real.'**
  String get introBody0;

  /// No description provided for @introBody1.
  ///
  /// In en, this message translates to:
  /// **'Set a fuse of 5, 10 or 30 seconds. Fire it, put the phone away, and let the noise go off on its own — completely hands free.'**
  String get introBody1;

  /// No description provided for @introBody2.
  ///
  /// In en, this message translates to:
  /// **'The home grid holds four sounds. Change any slot while browsing: tap the star on a sound and choose which slot it replaces.'**
  String get introBody2;

  /// No description provided for @introBody3.
  ///
  /// In en, this message translates to:
  /// **'Build a caller under Fake calls: a name, a photo from your gallery, and one of six call screens to draw it. Ring it, answer for real, hang up when you are ready to go — or let it ring out as a missed call. The photo never leaves your phone.'**
  String get introBody3;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get introStart;

  /// No description provided for @introDemoCallerName.
  ///
  /// In en, this message translates to:
  /// **'Mom'**
  String get introDemoCallerName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLoopSoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Loop sound'**
  String get settingsLoopSoundLabel;

  /// No description provided for @settingsLoopSoundDetail.
  ///
  /// In en, this message translates to:
  /// **'Default loop = repeat until stopped'**
  String get settingsLoopSoundDetail;

  /// No description provided for @settingsHapticSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Haptic support'**
  String get settingsHapticSupportLabel;

  /// No description provided for @settingsHapticSupportDetail.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on fire, per category'**
  String get settingsHapticSupportDetail;

  /// No description provided for @settingsMaxVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Max volume override'**
  String get settingsMaxVolumeLabel;

  /// No description provided for @settingsMaxVolumeDetail.
  ///
  /// In en, this message translates to:
  /// **'Force player to 100% on fire'**
  String get settingsMaxVolumeDetail;

  /// No description provided for @settingsDarkScreenHintsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark screen hints'**
  String get settingsDarkScreenHintsLabel;

  /// No description provided for @settingsDarkScreenHintsDetail.
  ///
  /// In en, this message translates to:
  /// **'Very faint status on blackout'**
  String get settingsDarkScreenHintsDetail;

  /// No description provided for @settingsLockScreenControlsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen controls'**
  String get settingsLockScreenControlsLabel;

  /// No description provided for @settingsLockScreenControlsDetail.
  ///
  /// In en, this message translates to:
  /// **'Neutral controls · keeps audio alive'**
  String get settingsLockScreenControlsDetail;

  /// No description provided for @settingsInAppTipsLabel.
  ///
  /// In en, this message translates to:
  /// **'In-app tips'**
  String get settingsInAppTipsLabel;

  /// No description provided for @settingsInAppTipsDetail.
  ///
  /// In en, this message translates to:
  /// **'Occasional reminders while open'**
  String get settingsInAppTipsDetail;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageValueEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageValueEnglish;

  /// No description provided for @settingsLanguageValueSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get settingsLanguageValueSpanish;

  /// No description provided for @settingsPremiumRowSemanticsActive.
  ///
  /// In en, this message translates to:
  /// **'Premium, active'**
  String get settingsPremiumRowSemanticsActive;

  /// No description provided for @settingsPremiumRowSemanticsInactive.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get settingsPremiumRowSemanticsInactive;

  /// No description provided for @settingsPremiumRowTitleActive.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsPremiumRowTitleActive;

  /// No description provided for @settingsPremiumRowTitleInactive.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get settingsPremiumRowTitleInactive;

  /// No description provided for @settingsPremiumRowSubtitleActive.
  ///
  /// In en, this message translates to:
  /// **'No ads · no limits'**
  String get settingsPremiumRowSubtitleActive;

  /// No description provided for @settingsPremiumRowSubtitleInactive.
  ///
  /// In en, this message translates to:
  /// **'Remove ads · unlimited calls and imports'**
  String get settingsPremiumRowSubtitleInactive;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyParagraph1.
  ///
  /// In en, this message translates to:
  /// **'Your sounds, imported files and call presets never leave this device. No account, no sync, no recording.'**
  String get settingsPrivacyParagraph1;

  /// No description provided for @settingsPrivacyParagraph2.
  ///
  /// In en, this message translates to:
  /// **'Ads and install measurement use your device advertising ID. The app sends no record of which sounds you play or when. You can reset or delete that ID in Android settings.'**
  String get settingsPrivacyParagraph2;

  /// No description provided for @settingsPrivacyParagraph3.
  ///
  /// In en, this message translates to:
  /// **'Firebase Analytics reports aggregate usage — which screens get opened, how often the app is used — never which sound, excuse or call preset you named. A remote check also reads one number, the lowest version this app still supports, to know if an update is required; it sends nothing back.'**
  String get settingsPrivacyParagraph3;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'YOUR SOUNDS · 100% OFFLINE'**
  String get settingsFooter;

  /// No description provided for @homeQuickExitsLabel.
  ///
  /// In en, this message translates to:
  /// **'QUICK EXITS'**
  String get homeQuickExitsLabel;

  /// No description provided for @homeFakeCallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Fake calls'**
  String get homeFakeCallsLabel;

  /// No description provided for @homeTemplateCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{NO TEMPLATES YET} =1{1 TEMPLATE} other{{count} TEMPLATES}}'**
  String homeTemplateCount(int count);

  /// No description provided for @homeFooter.
  ///
  /// In en, this message translates to:
  /// **'TAP AN EXIT · SCREEN GOES DARK · SOUND FIRES'**
  String get homeFooter;

  /// No description provided for @homeNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'NO NOTIFICATIONS · TAP TO FIX'**
  String get homeNotificationsBlocked;

  /// No description provided for @homeStandby.
  ///
  /// In en, this message translates to:
  /// **'STANDBY · {exits} EXITS READY'**
  String homeStandby(int exits);

  /// No description provided for @homePremiumIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get homePremiumIconLabel;

  /// No description provided for @homeSettingsIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsIconLabel;

  /// No description provided for @browseTitle.
  ///
  /// In en, this message translates to:
  /// **'All exits'**
  String get browseTitle;

  /// No description provided for @browseDeleteSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete sound'**
  String get browseDeleteSoundTitle;

  /// No description provided for @browseDeleteSoundMessage.
  ///
  /// In en, this message translates to:
  /// **'{label} and its audio file will be removed.'**
  String browseDeleteSoundMessage(String label);

  /// No description provided for @browseFilterAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get browseFilterAll;

  /// No description provided for @browseOpenCategory.
  ///
  /// In en, this message translates to:
  /// **'Open {label}'**
  String browseOpenCategory(String label);

  /// No description provided for @browseImportAudio.
  ///
  /// In en, this message translates to:
  /// **'Import audio'**
  String get browseImportAudio;

  /// No description provided for @browseImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get browseImport;

  /// No description provided for @categoryDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get categoryDetailNotFound;

  /// No description provided for @categoryDetailDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoryDetailDeleteCategoryTitle;

  /// No description provided for @categoryDetailDeleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'{label} and every sound in it will be removed, files included.'**
  String categoryDetailDeleteCategoryMessage(String label);

  /// No description provided for @categoryDetailSoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 SOUND} other{{count} SOUNDS}}'**
  String categoryDetailSoundCount(int count);

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// No description provided for @premiumFooter.
  ///
  /// In en, this message translates to:
  /// **'ONE DEVICE · NO ACCOUNT'**
  String get premiumFooter;

  /// No description provided for @premiumBillingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Play Billing is not available on this device, so Premium cannot be bought here. Everything else in the app works as it always has.'**
  String get premiumBillingUnavailable;

  /// No description provided for @premiumErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get premiumErrorGeneric;

  /// No description provided for @premiumTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get premiumTryAgain;

  /// No description provided for @premiumCheckingPrices.
  ///
  /// In en, this message translates to:
  /// **'Checking prices…'**
  String get premiumCheckingPrices;

  /// No description provided for @premiumNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans available right now.'**
  String get premiumNoPlans;

  /// No description provided for @premiumBenefitsCaption.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get premiumBenefitsCaption;

  /// No description provided for @premiumBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads, anywhere in the app'**
  String get premiumBenefitNoAds;

  /// No description provided for @premiumBenefitUnlimitedCalls.
  ///
  /// In en, this message translates to:
  /// **'Unlimited fake call templates'**
  String get premiumBenefitUnlimitedCalls;

  /// No description provided for @premiumBenefitUnlimitedSounds.
  ///
  /// In en, this message translates to:
  /// **'Unlimited imported sounds'**
  String get premiumBenefitUnlimitedSounds;

  /// No description provided for @premiumBenefitUnlimitedCategories.
  ///
  /// In en, this message translates to:
  /// **'Unlimited categories of your own'**
  String get premiumBenefitUnlimitedCategories;

  /// No description provided for @premiumBenefitsFooter.
  ///
  /// In en, this message translates to:
  /// **'The 47 built-in sounds and the four quick exits are free, and always will be. Premium only lifts the limits on what you add.'**
  String get premiumBenefitsFooter;

  /// No description provided for @premiumPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumPlanMonthly;

  /// No description provided for @premiumPlanYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumPlanYearly;

  /// No description provided for @premiumPlanLifetime.
  ///
  /// In en, this message translates to:
  /// **'One payment'**
  String get premiumPlanLifetime;

  /// No description provided for @premiumNoteMonthly.
  ///
  /// In en, this message translates to:
  /// **'Renews every month · cancel anytime'**
  String get premiumNoteMonthly;

  /// No description provided for @premiumNoteYearly.
  ///
  /// In en, this message translates to:
  /// **'Renews every year · cancel anytime'**
  String get premiumNoteYearly;

  /// No description provided for @premiumNoteLifetime.
  ///
  /// In en, this message translates to:
  /// **'Yours for good · nothing renews'**
  String get premiumNoteLifetime;

  /// No description provided for @premiumPlanSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, {price}'**
  String premiumPlanSemantics(String label, String price);

  /// No description provided for @premiumBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get premiumBestValue;

  /// No description provided for @premiumActiveLifetime.
  ///
  /// In en, this message translates to:
  /// **'Premium — one payment'**
  String get premiumActiveLifetime;

  /// No description provided for @premiumActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Premium — active'**
  String get premiumActiveSubscription;

  /// No description provided for @premiumActiveLifetimeDetail.
  ///
  /// In en, this message translates to:
  /// **'No ads and no limits, for good. Nothing renews and there is nothing to cancel.'**
  String get premiumActiveLifetimeDetail;

  /// No description provided for @premiumActiveSubscriptionDetail.
  ///
  /// In en, this message translates to:
  /// **'No ads and no limits. Manage or cancel it any time in the Play Store, under Subscriptions.'**
  String get premiumActiveSubscriptionDetail;

  /// No description provided for @premiumRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore a previous purchase'**
  String get premiumRestorePurchase;

  /// No description provided for @importCouldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read that file.'**
  String get importCouldNotReadFile;

  /// No description provided for @importDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'My audio'**
  String get importDefaultLabel;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'New exit'**
  String get editorTitle;

  /// No description provided for @editorFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read.'**
  String get editorFileUnreadable;

  /// No description provided for @editorFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'LABEL'**
  String get editorFieldLabel;

  /// No description provided for @editorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name it'**
  String get editorNameHint;

  /// No description provided for @editorFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'ICON'**
  String get editorFieldIcon;

  /// No description provided for @editorFieldTargetCategory.
  ///
  /// In en, this message translates to:
  /// **'TARGET CATEGORY'**
  String get editorFieldTargetCategory;

  /// No description provided for @editorSaveExit.
  ///
  /// In en, this message translates to:
  /// **'Save exit'**
  String get editorSaveExit;

  /// No description provided for @editorStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get editorStopPreview;

  /// No description provided for @editorPreviewWindow.
  ///
  /// In en, this message translates to:
  /// **'Preview window'**
  String get editorPreviewWindow;

  /// No description provided for @editorSaveItWhere.
  ///
  /// In en, this message translates to:
  /// **'Save it where?'**
  String get editorSaveItWhere;

  /// No description provided for @editorNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get editorNewCategory;

  /// No description provided for @editorTargetCategory.
  ///
  /// In en, this message translates to:
  /// **'Target category'**
  String get editorTargetCategory;

  /// No description provided for @editorPickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick one'**
  String get editorPickOne;

  /// No description provided for @editorChange.
  ///
  /// In en, this message translates to:
  /// **'CHANGE ▾'**
  String get editorChange;

  /// No description provided for @editorNewCategoryCaption.
  ///
  /// In en, this message translates to:
  /// **'NEW CATEGORY'**
  String get editorNewCategoryCaption;

  /// No description provided for @editorCategoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editorCategoryNameHint;

  /// No description provided for @editorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editorCancel;

  /// No description provided for @editorCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get editorCreate;

  /// No description provided for @editorNewCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Your own category.'**
  String get editorNewCategoryDescription;

  /// No description provided for @callsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Fake calls'**
  String get callsScreenTitle;

  /// No description provided for @callsAddTemplate.
  ///
  /// In en, this message translates to:
  /// **'Add template'**
  String get callsAddTemplate;

  /// No description provided for @callsNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get callsNew;

  /// No description provided for @callsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No call templates yet'**
  String get callsEmptyTitle;

  /// No description provided for @callsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save a name, a photo and a screen style, and ring it whenever you need a way out.'**
  String get callsEmptyBody;

  /// No description provided for @callEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get callEditorTitleEdit;

  /// No description provided for @callEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get callEditorTitleNew;

  /// No description provided for @callEditorDeleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get callEditorDeleteTemplate;

  /// No description provided for @callEditorDeleteTemplateMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed, along with its photo.'**
  String callEditorDeleteTemplateMessage(String name);

  /// No description provided for @callEditorNameCaption.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get callEditorNameCaption;

  /// No description provided for @callEditorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Caller name'**
  String get callEditorNameHint;

  /// No description provided for @callEditorNumberCaption.
  ///
  /// In en, this message translates to:
  /// **'NUMBER'**
  String get callEditorNumberCaption;

  /// No description provided for @callEditorRingtoneCaption.
  ///
  /// In en, this message translates to:
  /// **'RINGTONE'**
  String get callEditorRingtoneCaption;

  /// No description provided for @callEditorRingForCaption.
  ///
  /// In en, this message translates to:
  /// **'RING FOR'**
  String get callEditorRingForCaption;

  /// No description provided for @callEditorHangUpAfterCaption.
  ///
  /// In en, this message translates to:
  /// **'HANG UP AFTER'**
  String get callEditorHangUpAfterCaption;

  /// No description provided for @callEditorSchedulingPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduling further ahead is Premium'**
  String get callEditorSchedulingPremiumTitle;

  /// No description provided for @callEditorSchedulingPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'The free version schedules a call up to {minutes} minutes ahead. Premium removes the limit and adds a set time of day.'**
  String callEditorSchedulingPremiumBody(int minutes);

  /// No description provided for @callEditorSchedulingPremiumFootnote.
  ///
  /// In en, this message translates to:
  /// **'Ringing a call right now stays free, always.'**
  String get callEditorSchedulingPremiumFootnote;

  /// No description provided for @callEditorSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get callEditorSaveTemplate;

  /// No description provided for @callEditorPhotoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read that photo.'**
  String get callEditorPhotoUnreadable;

  /// No description provided for @callEditorScheduledExact.
  ///
  /// In en, this message translates to:
  /// **'Call scheduled for {when}.'**
  String callEditorScheduledExact(String when);

  /// No description provided for @callEditorScheduledApprox.
  ///
  /// In en, this message translates to:
  /// **'Call scheduled for around {when}.'**
  String callEditorScheduledApprox(String when);

  /// No description provided for @callEditorScheduledExactBanner.
  ///
  /// In en, this message translates to:
  /// **'Call scheduled for {when}. It will arrive as a banner.'**
  String callEditorScheduledExactBanner(String when);

  /// No description provided for @callEditorScheduledApproxBanner.
  ///
  /// In en, this message translates to:
  /// **'Call scheduled for around {when}. It will arrive as a banner.'**
  String callEditorScheduledApproxBanner(String when);

  /// No description provided for @callEditorRingOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get callEditorRingOn;

  /// No description provided for @callEditorAutoEndOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get callEditorAutoEndOff;

  /// No description provided for @callEditorVibrateSemantics.
  ///
  /// In en, this message translates to:
  /// **'Vibrate while ringing'**
  String get callEditorVibrateSemantics;

  /// No description provided for @callEditorVibrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get callEditorVibrateLabel;

  /// No description provided for @callEditorVibrateDetail.
  ///
  /// In en, this message translates to:
  /// **'Buzz along with the ringtone'**
  String get callEditorVibrateDetail;

  /// No description provided for @callEditorPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo'**
  String get callEditorPickPhoto;

  /// No description provided for @callEditorRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get callEditorRemovePhoto;

  /// No description provided for @callEditorPickRingtone.
  ///
  /// In en, this message translates to:
  /// **'Pick a ringtone'**
  String get callEditorPickRingtone;

  /// No description provided for @blackoutHoldToAbort.
  ///
  /// In en, this message translates to:
  /// **'HOLD ANYWHERE TO ABORT'**
  String get blackoutHoldToAbort;

  /// No description provided for @blackoutHoldToExit.
  ///
  /// In en, this message translates to:
  /// **'HOLD ANYWHERE TO EXIT'**
  String get blackoutHoldToExit;

  /// No description provided for @blackoutArmed.
  ///
  /// In en, this message translates to:
  /// **'ARMED'**
  String get blackoutArmed;

  /// No description provided for @blackoutFiringIn.
  ///
  /// In en, this message translates to:
  /// **'FIRING IN…'**
  String get blackoutFiringIn;

  /// No description provided for @blackoutStandby.
  ///
  /// In en, this message translates to:
  /// **'STANDBY'**
  String get blackoutStandby;

  /// No description provided for @blackoutLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get blackoutLive;

  /// No description provided for @blackoutPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get blackoutPaused;

  /// No description provided for @blackoutDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get blackoutDone;

  /// No description provided for @blackoutGetOutLine.
  ///
  /// In en, this message translates to:
  /// **'YOUR GET-OUT LINE'**
  String get blackoutGetOutLine;

  /// No description provided for @browseRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'Browse all sounds'**
  String get browseRowSemantics;

  /// No description provided for @browseRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get browseRowTitle;

  /// No description provided for @browseRowCounts.
  ///
  /// In en, this message translates to:
  /// **'{categories} CATEGORIES · {sounds} SOUNDS'**
  String browseRowCounts(int categories, int sounds);

  /// No description provided for @quickSlotFireSemantics.
  ///
  /// In en, this message translates to:
  /// **'Fire {label}'**
  String quickSlotFireSemantics(String label);

  /// No description provided for @quickSlotTapToFire.
  ///
  /// In en, this message translates to:
  /// **'TAP TO FIRE →'**
  String get quickSlotTapToFire;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDelete;

  /// No description provided for @selectorFuseCaption.
  ///
  /// In en, this message translates to:
  /// **'FUSE'**
  String get selectorFuseCaption;

  /// No description provided for @selectorLoopCaption.
  ///
  /// In en, this message translates to:
  /// **'LOOP'**
  String get selectorLoopCaption;

  /// No description provided for @slotPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin to which slot?'**
  String get slotPickerTitle;

  /// No description provided for @slotPickerPinningPrefix.
  ///
  /// In en, this message translates to:
  /// **'Pinning '**
  String get slotPickerPinningPrefix;

  /// No description provided for @slotPickerReplaceSlot.
  ///
  /// In en, this message translates to:
  /// **'Replace slot 0{slot}, {label}'**
  String slotPickerReplaceSlot(int slot, String label);

  /// No description provided for @slotPickerSlotBadge.
  ///
  /// In en, this message translates to:
  /// **'SLOT 0{slot}'**
  String slotPickerSlotBadge(int slot);

  /// No description provided for @soundRowStopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get soundRowStopPreview;

  /// No description provided for @soundRowPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get soundRowPreview;

  /// No description provided for @soundRowPinToSlot.
  ///
  /// In en, this message translates to:
  /// **'Pin to a slot'**
  String get soundRowPinToSlot;

  /// No description provided for @soundRowFullLength.
  ///
  /// In en, this message translates to:
  /// **'Full length'**
  String get soundRowFullLength;

  /// No description provided for @soundRowTrimRange.
  ///
  /// In en, this message translates to:
  /// **'Trim {start}–{end}'**
  String soundRowTrimRange(String start, String end);

  /// No description provided for @soundRowHoldToDelete.
  ///
  /// In en, this message translates to:
  /// **'{window} · hold to delete'**
  String soundRowHoldToDelete(String window);

  /// No description provided for @soundRowAddYourAudio.
  ///
  /// In en, this message translates to:
  /// **'Add your audio'**
  String get soundRowAddYourAudio;

  /// No description provided for @soundRowAddYourAudioCaption.
  ///
  /// In en, this message translates to:
  /// **'ADD YOUR AUDIO'**
  String get soundRowAddYourAudioCaption;

  /// No description provided for @trimTimelineCaption.
  ///
  /// In en, this message translates to:
  /// **'TRIM WINDOW'**
  String get trimTimelineCaption;

  /// No description provided for @permissionNoticeBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get permissionNoticeBlockedTitle;

  /// No description provided for @permissionNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen controls need permission to post one neutral notification. Without it the sound still fires, but you cannot pause it without reopening the app — and Android may stop the audio on its own after a few minutes. Fake calls do not need this: they ring while you have the app open.'**
  String get permissionNoticeBody;

  /// No description provided for @permissionNoticeOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get permissionNoticeOpenAppSettings;

  /// No description provided for @permissionNoticeAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get permissionNoticeAllowNotifications;

  /// No description provided for @permissionNoticeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionNoticeOpenSettings;

  /// No description provided for @permissionNoticeAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionNoticeAllow;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'THERE IS ALWAYS A WAY OUT'**
  String get splashTagline;

  /// No description provided for @scheduleNoticeNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled calls need notifications'**
  String get scheduleNoticeNotificationsTitle;

  /// No description provided for @scheduleNoticeNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'A call that arrives while ExitPlan is closed arrives as a notification. Without permission, nothing will come through — ringing a call from inside the app still works.'**
  String get scheduleNoticeNotificationsBody;

  /// No description provided for @scheduleNoticeExactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'The call may arrive late'**
  String get scheduleNoticeExactAlarmTitle;

  /// No description provided for @scheduleNoticeExactAlarmBody.
  ///
  /// In en, this message translates to:
  /// **'Android needs permission to wake the phone at an exact moment. Without it the call still arrives, but a few minutes after the time you set.'**
  String get scheduleNoticeExactAlarmBody;

  /// No description provided for @scheduleNoticeFullScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'The call will not take over the screen'**
  String get scheduleNoticeFullScreenTitle;

  /// No description provided for @scheduleNoticeFullScreenBody.
  ///
  /// In en, this message translates to:
  /// **'Without this the call arrives as a banner at the top of the screen instead of filling it. It still rings and vibrates, and tapping it opens the call.'**
  String get scheduleNoticeFullScreenBody;

  /// No description provided for @scheduleCaption.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get scheduleCaption;

  /// No description provided for @scheduleInCaption.
  ///
  /// In en, this message translates to:
  /// **'IN'**
  String get scheduleInCaption;

  /// No description provided for @scheduleArrivesWhenClosed.
  ///
  /// In en, this message translates to:
  /// **'The call arrives even if ExitPlan is closed and the phone is locked.'**
  String get scheduleArrivesWhenClosed;

  /// No description provided for @scheduleModeNow.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get scheduleModeNow;

  /// No description provided for @scheduleModeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'IN…'**
  String get scheduleModeInMinutes;

  /// No description provided for @scheduleModeAtTime.
  ///
  /// In en, this message translates to:
  /// **'AT…'**
  String get scheduleModeAtTime;

  /// No description provided for @callThemePickerCaption.
  ///
  /// In en, this message translates to:
  /// **'CALL SCREEN'**
  String get callThemePickerCaption;

  /// No description provided for @callThemePickerLockedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, Premium'**
  String callThemePickerLockedSemantics(String name);

  /// No description provided for @callThemePickerDefaultCaller.
  ///
  /// In en, this message translates to:
  /// **'Caller'**
  String get callThemePickerDefaultCaller;

  /// No description provided for @premiumGateCallPresetsPlural.
  ///
  /// In en, this message translates to:
  /// **'fake call templates'**
  String get premiumGateCallPresetsPlural;

  /// No description provided for @premiumGateCallPresetsSingular.
  ///
  /// In en, this message translates to:
  /// **'template'**
  String get premiumGateCallPresetsSingular;

  /// No description provided for @premiumGateUserSoundsPlural.
  ///
  /// In en, this message translates to:
  /// **'imported sounds'**
  String get premiumGateUserSoundsPlural;

  /// No description provided for @premiumGateUserSoundsSingular.
  ///
  /// In en, this message translates to:
  /// **'sound'**
  String get premiumGateUserSoundsSingular;

  /// No description provided for @premiumGateUserCategoriesPlural.
  ///
  /// In en, this message translates to:
  /// **'categories of your own'**
  String get premiumGateUserCategoriesPlural;

  /// No description provided for @premiumGateUserCategoriesSingular.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get premiumGateUserCategoriesSingular;

  /// No description provided for @premiumGateTitle.
  ///
  /// In en, this message translates to:
  /// **'That is {cap} {unit}'**
  String premiumGateTitle(int cap, String unit);

  /// No description provided for @premiumGateGrandfatheredBody.
  ///
  /// In en, this message translates to:
  /// **'You had {cap} before this version added limits, so you kept them all. Premium removes the ceiling entirely.'**
  String premiumGateGrandfatheredBody(int cap);

  /// No description provided for @premiumGateLimitBody.
  ///
  /// In en, this message translates to:
  /// **'The free version covers {freeLimit}. Premium removes the limit on {plural}, and the ads with it.'**
  String premiumGateLimitBody(int freeLimit, String plural);

  /// No description provided for @premiumGateThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'{themeName} is a Premium theme'**
  String premiumGateThemeTitle(String themeName);

  /// No description provided for @premiumGateThemeBody.
  ///
  /// In en, this message translates to:
  /// **'Premium unlocks every call screen, and removes the ads. The free themes stay exactly where they are.'**
  String get premiumGateThemeBody;

  /// No description provided for @premiumGateThemeFootnote.
  ///
  /// In en, this message translates to:
  /// **'Templates you already saved keep the theme they were saved with.'**
  String get premiumGateThemeFootnote;

  /// No description provided for @premiumGateDefaultFootnote.
  ///
  /// In en, this message translates to:
  /// **'Nothing you already made is affected.'**
  String get premiumGateDefaultFootnote;

  /// No description provided for @premiumGateSeePremium.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get premiumGateSeePremium;

  /// No description provided for @premiumGateNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get premiumGateNotNow;

  /// No description provided for @callPresetCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String callPresetCardEdit(String name);

  /// No description provided for @callPresetCardRing.
  ///
  /// In en, this message translates to:
  /// **'Ring {name}'**
  String callPresetCardRing(String name);

  /// No description provided for @callPresetCardCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the scheduled call to {name}'**
  String callPresetCardCancel(String name);

  /// No description provided for @callPresetCardScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED · {when}'**
  String callPresetCardScheduledFor(String when);

  /// No description provided for @callThemeMissedCall.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get callThemeMissedCall;

  /// No description provided for @callActionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callActionDecline;

  /// No description provided for @callActionDeclineCall.
  ///
  /// In en, this message translates to:
  /// **'Decline call'**
  String get callActionDeclineCall;

  /// No description provided for @callActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callActionAccept;

  /// No description provided for @callActionAcceptCall.
  ///
  /// In en, this message translates to:
  /// **'Accept call'**
  String get callActionAcceptCall;

  /// No description provided for @callActionEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callActionEndCall;

  /// No description provided for @callGridMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callGridMute;

  /// No description provided for @callGridKeypad.
  ///
  /// In en, this message translates to:
  /// **'Keypad'**
  String get callGridKeypad;

  /// No description provided for @callGridSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callGridSpeaker;

  /// No description provided for @callGridMuteLower.
  ///
  /// In en, this message translates to:
  /// **'mute'**
  String get callGridMuteLower;

  /// No description provided for @callGridKeypadLower.
  ///
  /// In en, this message translates to:
  /// **'keypad'**
  String get callGridKeypadLower;

  /// No description provided for @callGridSpeakerLower.
  ///
  /// In en, this message translates to:
  /// **'speaker'**
  String get callGridSpeakerLower;

  /// No description provided for @callBusinessBadge.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get callBusinessBadge;

  /// No description provided for @callBusinessIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callBusinessIncomingCall;

  /// No description provided for @callBusinessAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get callBusinessAnswer;

  /// No description provided for @callMinimalIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get callMinimalIncoming;

  /// No description provided for @callMinimalSlideUp.
  ///
  /// In en, this message translates to:
  /// **'Slide up'**
  String get callMinimalSlideUp;

  /// No description provided for @callChatGreenVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call…'**
  String get callChatGreenVoiceCall;

  /// No description provided for @callChatGreenMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get callChatGreenMoreOptions;

  /// No description provided for @callChatGreenToggleVideo.
  ///
  /// In en, this message translates to:
  /// **'Toggle video'**
  String get callChatGreenToggleVideo;

  /// No description provided for @callChatGreenToggleSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Toggle speaker'**
  String get callChatGreenToggleSpeaker;

  /// No description provided for @callChatGreenToggleMute.
  ///
  /// In en, this message translates to:
  /// **'Toggle mute'**
  String get callChatGreenToggleMute;

  /// No description provided for @callMaterialIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callMaterialIncomingCall;

  /// No description provided for @callMaterialSwipeUpDecline.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to decline'**
  String get callMaterialSwipeUpDecline;

  /// No description provided for @callMaterialSwipeUpAnswer.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to answer'**
  String get callMaterialSwipeUpAnswer;

  /// No description provided for @callChatBlueIncomingVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming voice call'**
  String get callChatBlueIncomingVoiceCall;

  /// No description provided for @callChatBlueVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get callChatBlueVideo;

  /// No description provided for @callClassicIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'incoming call'**
  String get callClassicIncomingCall;

  /// No description provided for @callClassicSlideUpToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Slide up to answer'**
  String get callClassicSlideUpToAnswer;

  /// No description provided for @callClassicAddCall.
  ///
  /// In en, this message translates to:
  /// **'add call'**
  String get callClassicAddCall;

  /// No description provided for @callClassicContacts.
  ///
  /// In en, this message translates to:
  /// **'contacts'**
  String get callClassicContacts;

  /// No description provided for @forceUpdateCaption.
  ///
  /// In en, this message translates to:
  /// **'UPDATE REQUIRED'**
  String get forceUpdateCaption;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'This version is too old to keep using safely.'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'A required update is available. Install it to keep using the app — this screen won\'t go away on its own.'**
  String get forceUpdateBody;

  /// No description provided for @forceUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
