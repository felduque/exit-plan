// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get introSkip => 'SKIP';

  @override
  String introStepLabel(int step, String kicker) {
    return 'STEP 0$step · $kicker';
  }

  @override
  String get introLanguageKicker => 'LANGUAGE';

  @override
  String get introLanguageTitle => 'Pick your\nlanguage.';

  @override
  String get introLanguageBody =>
      'English or Spanish, for now. Change it anytime later from Settings.';

  @override
  String get introKicker0 => 'THE EXIT';

  @override
  String get introKicker1 => 'DELAY FUSE';

  @override
  String get introKicker2 => 'FOUR SLOTS';

  @override
  String get introKicker3 => 'FAKE CALLS';

  @override
  String get introTitle0 => 'Tap it and\nthe room\nchanges.';

  @override
  String get introTitle1 => 'Arm it, then\npocket the\nphone.';

  @override
  String get introTitle2 => 'Four exits,\nalways one\ntap away.';

  @override
  String get introTitle3 => 'A call\nthat looks\nreal.';

  @override
  String get introBody0 =>
      'The screen goes completely black and the sound fires in a loop. It looks like the phone is in your pocket and the noise is real.';

  @override
  String get introBody1 =>
      'Set a fuse of 5, 10 or 30 seconds. Fire it, put the phone away, and let the noise go off on its own — completely hands free.';

  @override
  String get introBody2 =>
      'The home grid holds four sounds. Change any slot while browsing: tap the star on a sound and choose which slot it replaces.';

  @override
  String get introBody3 =>
      'Build a caller under Fake calls: a name, a photo from your gallery, and one of six call screens to draw it. Ring it, answer for real, hang up when you are ready to go — or let it ring out as a missed call. The photo never leaves your phone.';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Start';

  @override
  String get introDemoCallerName => 'Mom';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLoopSoundLabel => 'Loop sound';

  @override
  String get settingsLoopSoundDetail => 'Default loop = repeat until stopped';

  @override
  String get settingsHapticSupportLabel => 'Haptic support';

  @override
  String get settingsHapticSupportDetail => 'Vibrate on fire, per category';

  @override
  String get settingsMaxVolumeLabel => 'Max volume override';

  @override
  String get settingsMaxVolumeDetail => 'Force player to 100% on fire';

  @override
  String get settingsDarkScreenHintsLabel => 'Dark screen hints';

  @override
  String get settingsDarkScreenHintsDetail => 'Very faint status on blackout';

  @override
  String get settingsLockScreenControlsLabel => 'Lock-screen controls';

  @override
  String get settingsLockScreenControlsDetail =>
      'Neutral controls · keeps audio alive';

  @override
  String get settingsInAppTipsLabel => 'In-app tips';

  @override
  String get settingsInAppTipsDetail => 'Occasional reminders while open';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageValueEnglish => 'English';

  @override
  String get settingsLanguageValueSpanish => 'Español';

  @override
  String get settingsPremiumRowSemanticsActive => 'Premium, active';

  @override
  String get settingsPremiumRowSemanticsInactive => 'Get Premium';

  @override
  String get settingsPremiumRowTitleActive => 'Premium';

  @override
  String get settingsPremiumRowTitleInactive => 'Get Premium';

  @override
  String get settingsPremiumRowSubtitleActive => 'No ads · no limits';

  @override
  String get settingsPremiumRowSubtitleInactive =>
      'Remove ads · unlimited calls and imports';

  @override
  String get settingsPrivacyTitle => 'Privacy';

  @override
  String get settingsPrivacyParagraph1 =>
      'Your sounds, imported files and call presets never leave this device. No account, no sync, no recording.';

  @override
  String get settingsPrivacyParagraph2 =>
      'Ads and install measurement use your device advertising ID. The app sends no record of which sounds you play or when. You can reset or delete that ID in Android settings.';

  @override
  String get settingsPrivacyParagraph3 =>
      'Firebase Analytics reports aggregate usage — which screens get opened, how often the app is used — never which sound, excuse or call preset you named. A remote check also reads one number, the lowest version this app still supports, to know if an update is required; it sends nothing back.';

  @override
  String get settingsFooter => 'YOUR SOUNDS · 100% OFFLINE';

  @override
  String get homeQuickExitsLabel => 'QUICK EXITS';

  @override
  String get homeFakeCallsLabel => 'Fake calls';

  @override
  String homeTemplateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count TEMPLATES',
      one: '1 TEMPLATE',
      zero: 'NO TEMPLATES YET',
    );
    return '$_temp0';
  }

  @override
  String get homeFooter => 'TAP AN EXIT · SCREEN GOES DARK · SOUND FIRES';

  @override
  String get homeNotificationsBlocked => 'NO NOTIFICATIONS · TAP TO FIX';

  @override
  String homeStandby(int exits) {
    return 'STANDBY · $exits EXITS READY';
  }

  @override
  String get homePremiumIconLabel => 'Premium';

  @override
  String get homeSettingsIconLabel => 'Settings';

  @override
  String get browseTitle => 'All exits';

  @override
  String get browseDeleteSoundTitle => 'Delete sound';

  @override
  String browseDeleteSoundMessage(String label) {
    return '$label and its audio file will be removed.';
  }

  @override
  String get browseFilterAll => 'ALL';

  @override
  String browseOpenCategory(String label) {
    return 'Open $label';
  }

  @override
  String get browseImportAudio => 'Import audio';

  @override
  String get browseImport => 'IMPORT';

  @override
  String get categoryDetailNotFound => 'Category not found';

  @override
  String get categoryDetailDeleteCategoryTitle => 'Delete category';

  @override
  String categoryDetailDeleteCategoryMessage(String label) {
    return '$label and every sound in it will be removed, files included.';
  }

  @override
  String categoryDetailSoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SOUNDS',
      one: '1 SOUND',
    );
    return '$_temp0';
  }

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumFooter => 'ONE DEVICE · NO ACCOUNT';

  @override
  String get premiumBillingUnavailable =>
      'Play Billing is not available on this device, so Premium cannot be bought here. Everything else in the app works as it always has.';

  @override
  String get premiumErrorGeneric => 'Something went wrong.';

  @override
  String get premiumTryAgain => 'Try again';

  @override
  String get premiumCheckingPrices => 'Checking prices…';

  @override
  String get premiumNoPlans => 'No plans available right now.';

  @override
  String get premiumBenefitsCaption => 'PREMIUM';

  @override
  String get premiumBenefitNoAds => 'No ads, anywhere in the app';

  @override
  String get premiumBenefitUnlimitedCalls => 'Unlimited fake call templates';

  @override
  String get premiumBenefitUnlimitedSounds => 'Unlimited imported sounds';

  @override
  String get premiumBenefitUnlimitedCategories =>
      'Unlimited categories of your own';

  @override
  String get premiumBenefitsFooter =>
      'The 47 built-in sounds and the four quick exits are free, and always will be. Premium only lifts the limits on what you add.';

  @override
  String get premiumPlanMonthly => 'Monthly';

  @override
  String get premiumPlanYearly => 'Yearly';

  @override
  String get premiumPlanLifetime => 'One payment';

  @override
  String get premiumNoteMonthly => 'Renews every month · cancel anytime';

  @override
  String get premiumNoteYearly => 'Renews every year · cancel anytime';

  @override
  String get premiumNoteLifetime => 'Yours for good · nothing renews';

  @override
  String premiumPlanSemantics(String label, String price) {
    return '$label, $price';
  }

  @override
  String get premiumBestValue => 'BEST VALUE';

  @override
  String get premiumActiveLifetime => 'Premium — one payment';

  @override
  String get premiumActiveSubscription => 'Premium — active';

  @override
  String get premiumActiveLifetimeDetail =>
      'No ads and no limits, for good. Nothing renews and there is nothing to cancel.';

  @override
  String get premiumActiveSubscriptionDetail =>
      'No ads and no limits. Manage or cancel it any time in the Play Store, under Subscriptions.';

  @override
  String get premiumRestorePurchase => 'Restore a previous purchase';

  @override
  String get importCouldNotReadFile => 'Could not read that file.';

  @override
  String get importDefaultLabel => 'My audio';

  @override
  String get editorTitle => 'New exit';

  @override
  String get editorFileUnreadable => 'This file could not be read.';

  @override
  String get editorFieldLabel => 'LABEL';

  @override
  String get editorNameHint => 'Name it';

  @override
  String get editorFieldIcon => 'ICON';

  @override
  String get editorFieldTargetCategory => 'TARGET CATEGORY';

  @override
  String get editorSaveExit => 'Save exit';

  @override
  String get editorStopPreview => 'Stop preview';

  @override
  String get editorPreviewWindow => 'Preview window';

  @override
  String get editorSaveItWhere => 'Save it where?';

  @override
  String get editorNewCategory => 'New category';

  @override
  String get editorTargetCategory => 'Target category';

  @override
  String get editorPickOne => 'Pick one';

  @override
  String get editorChange => 'CHANGE ▾';

  @override
  String get editorNewCategoryCaption => 'NEW CATEGORY';

  @override
  String get editorCategoryNameHint => 'Name';

  @override
  String get editorCancel => 'Cancel';

  @override
  String get editorCreate => 'Create';

  @override
  String get editorNewCategoryDescription => 'Your own category.';

  @override
  String get callsScreenTitle => 'Fake calls';

  @override
  String get callsAddTemplate => 'Add template';

  @override
  String get callsNew => 'NEW';

  @override
  String get callsEmptyTitle => 'No call templates yet';

  @override
  String get callsEmptyBody =>
      'Save a name, a photo and a screen style, and ring it whenever you need a way out.';

  @override
  String get callEditorTitleEdit => 'Edit template';

  @override
  String get callEditorTitleNew => 'New template';

  @override
  String get callEditorDeleteTemplate => 'Delete template';

  @override
  String callEditorDeleteTemplateMessage(String name) {
    return '$name will be removed, along with its photo.';
  }

  @override
  String get callEditorNameCaption => 'NAME';

  @override
  String get callEditorNameHint => 'Caller name';

  @override
  String get callEditorNumberCaption => 'NUMBER';

  @override
  String get callEditorRingtoneCaption => 'RINGTONE';

  @override
  String get callEditorRingForCaption => 'RING FOR';

  @override
  String get callEditorHangUpAfterCaption => 'HANG UP AFTER';

  @override
  String get callEditorSchedulingPremiumTitle =>
      'Scheduling further ahead is Premium';

  @override
  String callEditorSchedulingPremiumBody(int minutes) {
    return 'The free version schedules a call up to $minutes minutes ahead. Premium removes the limit and adds a set time of day.';
  }

  @override
  String get callEditorSchedulingPremiumFootnote =>
      'Ringing a call right now stays free, always.';

  @override
  String get callEditorSaveTemplate => 'Save template';

  @override
  String get callEditorSaved => 'Template saved';

  @override
  String get callEditorPhotoUnreadable => 'Could not read that photo.';

  @override
  String callEditorScheduledExactBanner(String when) {
    return 'Call scheduled for $when. It will arrive as a banner.';
  }

  @override
  String callEditorScheduledApproxBanner(String when) {
    return 'Call scheduled for around $when. It will arrive as a banner.';
  }

  @override
  String get callEditorRingOn => 'ON';

  @override
  String get callEditorAutoEndOff => 'OFF';

  @override
  String get callEditorVibrateSemantics => 'Vibrate while ringing';

  @override
  String get callEditorVibrateLabel => 'Vibrate';

  @override
  String get callEditorVibrateDetail => 'Buzz along with the ringtone';

  @override
  String get callEditorRetrySemantics => 'Ring again if missed';

  @override
  String get callEditorRetryLabel => 'Ring again if missed';

  @override
  String get callEditorRetryDetail => 'Calls back once if nobody answers';

  @override
  String get callEditorPickPhoto => 'Pick a photo';

  @override
  String get callEditorRemovePhoto => 'Remove photo';

  @override
  String get callEditorPickRingtone => 'Pick a ringtone';

  @override
  String get blackoutHoldToAbort => 'HOLD ANYWHERE TO ABORT';

  @override
  String get blackoutHoldToExit => 'HOLD ANYWHERE TO EXIT';

  @override
  String get blackoutArmed => 'ARMED';

  @override
  String get blackoutFiringIn => 'FIRING IN…';

  @override
  String get blackoutStandby => 'STANDBY';

  @override
  String get blackoutLive => 'LIVE';

  @override
  String get blackoutPaused => 'PAUSED';

  @override
  String get blackoutDone => 'DONE';

  @override
  String get blackoutGetOutLine => 'YOUR GET-OUT LINE';

  @override
  String get browseRowSemantics => 'Browse all sounds';

  @override
  String get browseRowTitle => 'Browse all';

  @override
  String browseRowCounts(int categories, int sounds) {
    return '$categories CATEGORIES · $sounds SOUNDS';
  }

  @override
  String quickSlotFireSemantics(String label) {
    return 'Fire $label';
  }

  @override
  String get quickSlotTapToFire => 'TAP TO FIRE →';

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get confirmDelete => 'Delete';

  @override
  String get selectorFuseCaption => 'FUSE';

  @override
  String get selectorLoopCaption => 'LOOP';

  @override
  String get slotPickerTitle => 'Pin to which slot?';

  @override
  String get slotPickerPinningPrefix => 'Pinning ';

  @override
  String slotPickerReplaceSlot(int slot, String label) {
    return 'Replace slot 0$slot, $label';
  }

  @override
  String slotPickerSlotBadge(int slot) {
    return 'SLOT 0$slot';
  }

  @override
  String get soundRowStopPreview => 'Stop preview';

  @override
  String get soundRowPreview => 'Preview';

  @override
  String get soundRowPinToSlot => 'Pin to a slot';

  @override
  String get soundRowFullLength => 'Full length';

  @override
  String soundRowTrimRange(String start, String end) {
    return 'Trim $start–$end';
  }

  @override
  String soundRowHoldToDelete(String window) {
    return '$window · hold to delete';
  }

  @override
  String get soundRowAddYourAudio => 'Add your audio';

  @override
  String get soundRowAddYourAudioCaption => 'ADD YOUR AUDIO';

  @override
  String get trimTimelineCaption => 'TRIM WINDOW';

  @override
  String get permissionNoticeBlockedTitle => 'Notifications are blocked';

  @override
  String get permissionNoticeBody =>
      'Lock-screen controls need permission to post one neutral notification. Without it the sound still fires, but you cannot pause it without reopening the app — and Android may stop the audio on its own after a few minutes. Fake calls do not need this: they ring while you have the app open.';

  @override
  String get permissionNoticeOpenAppSettings => 'Open app settings';

  @override
  String get permissionNoticeAllowNotifications => 'Allow notifications';

  @override
  String get permissionNoticeOpenSettings => 'Open settings';

  @override
  String get permissionNoticeAllow => 'Allow';

  @override
  String get splashTagline => 'THERE IS ALWAYS A WAY OUT';

  @override
  String get scheduleNoticeNotificationsTitle =>
      'Scheduled calls need notifications';

  @override
  String get scheduleNoticeNotificationsBody =>
      'A call that arrives while ExitPlan is closed arrives as a notification. Without permission, nothing will come through — ringing a call from inside the app still works.';

  @override
  String get scheduleNoticeExactAlarmTitle => 'The call may arrive late';

  @override
  String get scheduleNoticeExactAlarmBody =>
      'Android needs permission to wake the phone at an exact moment. Without it the call still arrives, but a few minutes after the time you set.';

  @override
  String get scheduleCaption => 'SCHEDULE';

  @override
  String get scheduleInCaption => 'IN';

  @override
  String get scheduleArrivesWhenClosed =>
      'The call rings even if ExitPlan is closed and the phone is locked. It arrives as a notification — tap it to open the call.';

  @override
  String get scheduleModeNow => 'NOW';

  @override
  String get scheduleModeInMinutes => 'IN…';

  @override
  String get scheduleModeAtTime => 'AT…';

  @override
  String get callThemePickerCaption => 'CALL SCREEN';

  @override
  String callThemePickerLockedSemantics(String name) {
    return '$name, Premium';
  }

  @override
  String get callThemePickerDefaultCaller => 'Caller';

  @override
  String get premiumGateCallPresetsPlural => 'fake call templates';

  @override
  String get premiumGateCallPresetsSingular => 'template';

  @override
  String get premiumGateUserSoundsPlural => 'imported sounds';

  @override
  String get premiumGateUserSoundsSingular => 'sound';

  @override
  String get premiumGateUserCategoriesPlural => 'categories of your own';

  @override
  String get premiumGateUserCategoriesSingular => 'category';

  @override
  String premiumGateTitle(int cap, String unit) {
    return 'That is $cap $unit';
  }

  @override
  String premiumGateGrandfatheredBody(int cap) {
    return 'You had $cap before this version added limits, so you kept them all. Premium removes the ceiling entirely.';
  }

  @override
  String premiumGateLimitBody(int freeLimit, String plural) {
    return 'The free version covers $freeLimit. Premium removes the limit on $plural, and the ads with it.';
  }

  @override
  String premiumGateThemeTitle(String themeName) {
    return '$themeName is a Premium theme';
  }

  @override
  String get premiumGateThemeBody =>
      'Premium unlocks every call screen, and removes the ads. The free themes stay exactly where they are.';

  @override
  String get premiumGateThemeFootnote =>
      'Templates you already saved keep the theme they were saved with.';

  @override
  String get premiumGateDefaultFootnote =>
      'Nothing you already made is affected.';

  @override
  String get premiumGateSeePremium => 'See Premium';

  @override
  String get premiumGateNotNow => 'Not now';

  @override
  String callPresetCardEdit(String name) {
    return 'Edit $name';
  }

  @override
  String callPresetCardRing(String name) {
    return 'Ring $name';
  }

  @override
  String callPresetCardCancel(String name) {
    return 'Cancel the scheduled call to $name';
  }

  @override
  String callPresetCardScheduledFor(String when) {
    return 'SCHEDULED · $when';
  }

  @override
  String get callThemeMissedCall => 'Missed call';

  @override
  String get callThemeCallEnded => 'Call ended';

  @override
  String get callThemeCallDeclined => 'Declined';

  @override
  String get callActionDecline => 'Decline';

  @override
  String get callActionDeclineCall => 'Decline call';

  @override
  String get callActionAccept => 'Accept';

  @override
  String get callActionAcceptCall => 'Accept call';

  @override
  String get callActionEndCall => 'End call';

  @override
  String get callGridMute => 'Mute';

  @override
  String get callGridKeypad => 'Keypad';

  @override
  String get callGridSpeaker => 'Speaker';

  @override
  String get callGridMuteLower => 'mute';

  @override
  String get callGridKeypadLower => 'keypad';

  @override
  String get callGridSpeakerLower => 'speaker';

  @override
  String get callBusinessBadge => 'WORK';

  @override
  String get callBusinessIncomingCall => 'Incoming call';

  @override
  String get callBusinessAnswer => 'Answer';

  @override
  String get callMinimalIncoming => 'Incoming';

  @override
  String get callMinimalSlideUp => 'Slide up';

  @override
  String get callChatGreenVoiceCall => 'Voice call…';

  @override
  String get callChatGreenMoreOptions => 'More options';

  @override
  String get callChatGreenToggleVideo => 'Toggle video';

  @override
  String get callChatGreenToggleSpeaker => 'Toggle speaker';

  @override
  String get callChatGreenToggleMute => 'Toggle mute';

  @override
  String get callMaterialIncomingCall => 'Incoming call';

  @override
  String get callMaterialSwipeUpDecline => 'Swipe up to decline';

  @override
  String get callMaterialSwipeUpAnswer => 'Swipe up to answer';

  @override
  String get callChatBlueIncomingVoiceCall => 'Incoming voice call';

  @override
  String get callChatBlueVideo => 'Video';

  @override
  String get callClassicIncomingCall => 'incoming call';

  @override
  String get callClassicSlideUpToAnswer => 'Slide up to answer';

  @override
  String get callClassicAddCall => 'add call';

  @override
  String get callClassicContacts => 'contacts';

  @override
  String get forceUpdateCaption => 'UPDATE REQUIRED';

  @override
  String get forceUpdateTitle =>
      'This version is too old to keep using safely.';

  @override
  String get forceUpdateBody =>
      'A required update is available. Install it to keep using the app — this screen won\'t go away on its own.';

  @override
  String get forceUpdateButton => 'Update now';
}
