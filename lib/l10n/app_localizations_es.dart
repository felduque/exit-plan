// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get introSkip => 'OMITIR';

  @override
  String introStepLabel(int step, String kicker) {
    return 'PASO 0$step · $kicker';
  }

  @override
  String get introLanguageKicker => 'IDIOMA';

  @override
  String get introLanguageTitle => 'Elige tu\nidioma.';

  @override
  String get introLanguageBody =>
      'Por ahora, inglés o español. Puedes cambiarlo cuando quieras desde Ajustes.';

  @override
  String get introKicker0 => 'LA SALIDA';

  @override
  String get introKicker1 => 'MECHA CON RETARDO';

  @override
  String get introKicker2 => 'CUATRO RANURAS';

  @override
  String get introKicker3 => 'LLAMADAS FALSAS';

  @override
  String get introTitle0 => 'Tócalo y\nla sala\ncambia.';

  @override
  String get introTitle1 => 'Actívala y\nguarda el\nteléfono.';

  @override
  String get introTitle2 => 'Cuatro salidas,\nsiempre a un\ntoque.';

  @override
  String get introTitle3 => 'Una llamada\nque parece\nreal.';

  @override
  String get introBody0 =>
      'La pantalla se apaga por completo y el sonido suena en bucle. Parece que el teléfono está en tu bolsillo y el ruido es real.';

  @override
  String get introBody1 =>
      'Fija un retardo de 5, 10 o 30 segundos. Actívalo, guarda el teléfono y deja que el sonido se dispare solo — sin usar las manos.';

  @override
  String get introBody2 =>
      'La cuadrícula de inicio guarda cuatro sonidos. Cambia cualquier ranura mientras exploras: toca la estrella de un sonido y elige qué ranura reemplaza.';

  @override
  String get introBody3 =>
      'Crea un contacto en Llamadas falsas: un nombre, una foto de tu galería y una de seis pantallas de llamada para mostrarla. Contesta de verdad, cuelga cuando quieras irte, o déjala sonar hasta que quede como llamada perdida. La foto nunca sale de tu teléfono.';

  @override
  String get introNext => 'Siguiente';

  @override
  String get introStart => 'Empezar';

  @override
  String get introDemoCallerName => 'Mamá';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLoopSoundLabel => 'Repetir sonido';

  @override
  String get settingsLoopSoundDetail =>
      'Repetición por defecto = hasta detenerlo';

  @override
  String get settingsHapticSupportLabel => 'Vibración';

  @override
  String get settingsHapticSupportDetail => 'Vibra al activar, según categoría';

  @override
  String get settingsMaxVolumeLabel => 'Forzar volumen máximo';

  @override
  String get settingsMaxVolumeDetail =>
      'Sube el reproductor al 100% al activar';

  @override
  String get settingsDarkScreenHintsLabel => 'Pistas en pantalla oscura';

  @override
  String get settingsDarkScreenHintsDetail =>
      'Estado muy tenue durante el apagón';

  @override
  String get settingsLockScreenControlsLabel =>
      'Controles en pantalla de bloqueo';

  @override
  String get settingsLockScreenControlsDetail =>
      'Controles neutros · mantiene el audio activo';

  @override
  String get settingsInAppTipsLabel => 'Consejos en la app';

  @override
  String get settingsInAppTipsDetail =>
      'Recordatorios ocasionales mientras la usas';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageValueEnglish => 'Inglés';

  @override
  String get settingsLanguageValueSpanish => 'Español';

  @override
  String get settingsPremiumRowSemanticsActive => 'Premium, activo';

  @override
  String get settingsPremiumRowSemanticsInactive => 'Obtener Premium';

  @override
  String get settingsPremiumRowTitleActive => 'Premium';

  @override
  String get settingsPremiumRowTitleInactive => 'Obtener Premium';

  @override
  String get settingsPremiumRowSubtitleActive => 'Sin anuncios · sin límites';

  @override
  String get settingsPremiumRowSubtitleInactive =>
      'Elimina anuncios · llamadas e importaciones ilimitadas';

  @override
  String get settingsPrivacyTitle => 'Privacidad';

  @override
  String get settingsPrivacyParagraph1 =>
      'Tus sonidos, archivos importados y contactos falsos nunca salen de este dispositivo. Sin cuenta, sin sincronización, sin grabación.';

  @override
  String get settingsPrivacyParagraph2 =>
      'Los anuncios y la medición de instalaciones usan el ID de publicidad de tu dispositivo. La app no envía ningún registro de qué sonidos reproduces ni cuándo. Puedes restablecer o eliminar ese ID en los ajustes de Android.';

  @override
  String get settingsPrivacyParagraph3 =>
      'Firebase Analytics reporta uso agregado — qué pantallas se abren, con qué frecuencia se usa la app — nunca qué sonido, excusa o contacto falso nombraste. Una comprobación remota también lee un número, la versión mínima que esta app sigue soportando, para saber si hace falta actualizar; no envía nada de vuelta.';

  @override
  String get settingsFooter => 'TUS SONIDOS · 100% SIN CONEXIÓN';

  @override
  String get homeQuickExitsLabel => 'SALIDAS RÁPIDAS';

  @override
  String get homeFakeCallsLabel => 'Llamadas falsas';

  @override
  String homeTemplateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count CONTACTOS',
      one: '1 CONTACTO',
      zero: 'SIN CONTACTOS AÚN',
    );
    return '$_temp0';
  }

  @override
  String get homeFooter =>
      'TOCA UNA SALIDA · LA PANTALLA SE APAGA · SUENA EL AUDIO';

  @override
  String get homeNotificationsBlocked =>
      'SIN NOTIFICACIONES · TOCA PARA CORREGIR';

  @override
  String homeStandby(int exits) {
    return 'LISTO · $exits SALIDAS DISPONIBLES';
  }

  @override
  String get homePremiumIconLabel => 'Premium';

  @override
  String get homeSettingsIconLabel => 'Ajustes';

  @override
  String get browseTitle => 'Todas las salidas';

  @override
  String get browseDeleteSoundTitle => 'Eliminar sonido';

  @override
  String browseDeleteSoundMessage(String label) {
    return 'Se eliminará $label y su archivo de audio.';
  }

  @override
  String get browseFilterAll => 'TODOS';

  @override
  String browseOpenCategory(String label) {
    return 'Abrir $label';
  }

  @override
  String get browseImportAudio => 'Importar audio';

  @override
  String get browseImport => 'IMPORTAR';

  @override
  String get categoryDetailNotFound => 'Categoría no encontrada';

  @override
  String get categoryDetailDeleteCategoryTitle => 'Eliminar categoría';

  @override
  String categoryDetailDeleteCategoryMessage(String label) {
    return 'Se eliminará $label y todos sus sonidos, incluidos los archivos.';
  }

  @override
  String categoryDetailSoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SONIDOS',
      one: '1 SONIDO',
    );
    return '$_temp0';
  }

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumFooter => 'UN DISPOSITIVO · SIN CUENTA';

  @override
  String get premiumBillingUnavailable =>
      'Play Billing no está disponible en este dispositivo, así que Premium no se puede comprar aquí. Todo lo demás en la app funciona como siempre.';

  @override
  String get premiumErrorGeneric => 'Algo salió mal.';

  @override
  String get premiumTryAgain => 'Intentar de nuevo';

  @override
  String get premiumCheckingPrices => 'Consultando precios…';

  @override
  String get premiumNoPlans => 'No hay planes disponibles ahora mismo.';

  @override
  String get premiumBenefitsCaption => 'PREMIUM';

  @override
  String get premiumBenefitNoAds => 'Sin anuncios, en ninguna parte de la app';

  @override
  String get premiumBenefitUnlimitedCalls =>
      'Contactos de llamadas falsas ilimitados';

  @override
  String get premiumBenefitUnlimitedSounds => 'Sonidos importados ilimitados';

  @override
  String get premiumBenefitUnlimitedCategories =>
      'Categorías propias ilimitadas';

  @override
  String get premiumBenefitsFooter =>
      'Los 47 sonidos incluidos y las cuatro salidas rápidas son gratis y siempre lo serán. Premium solo elimina los límites de lo que agregas.';

  @override
  String get premiumPlanMonthly => 'Mensual';

  @override
  String get premiumPlanYearly => 'Anual';

  @override
  String get premiumPlanLifetime => 'Pago único';

  @override
  String get premiumNoteMonthly =>
      'Se renueva cada mes · cancela cuando quieras';

  @override
  String get premiumNoteYearly =>
      'Se renueva cada año · cancela cuando quieras';

  @override
  String get premiumNoteLifetime => 'Es tuyo para siempre · nada se renueva';

  @override
  String premiumPlanSemantics(String label, String price) {
    return '$label, $price';
  }

  @override
  String get premiumBestValue => 'MEJOR VALOR';

  @override
  String get premiumActiveLifetime => 'Premium — pago único';

  @override
  String get premiumActiveSubscription => 'Premium — activo';

  @override
  String get premiumActiveLifetimeDetail =>
      'Sin anuncios y sin límites, para siempre. Nada se renueva y no hay nada que cancelar.';

  @override
  String get premiumActiveSubscriptionDetail =>
      'Sin anuncios y sin límites. Gestiónalo o cancélalo cuando quieras en Play Store, en Suscripciones.';

  @override
  String get premiumRestorePurchase => 'Restaurar una compra anterior';

  @override
  String get importCouldNotReadFile => 'No se pudo leer ese archivo.';

  @override
  String get importDefaultLabel => 'Mi audio';

  @override
  String get editorTitle => 'Nueva salida';

  @override
  String get editorFileUnreadable => 'No se pudo leer este archivo.';

  @override
  String get editorFieldLabel => 'NOMBRE';

  @override
  String get editorNameHint => 'Ponle un nombre';

  @override
  String get editorFieldIcon => 'ÍCONO';

  @override
  String get editorFieldTargetCategory => 'CATEGORÍA DE DESTINO';

  @override
  String get editorSaveExit => 'Guardar salida';

  @override
  String get editorStopPreview => 'Detener vista previa';

  @override
  String get editorPreviewWindow => 'Vista previa del tramo';

  @override
  String get editorSaveItWhere => '¿Dónde lo guardamos?';

  @override
  String get editorNewCategory => 'Nueva categoría';

  @override
  String get editorTargetCategory => 'Categoría de destino';

  @override
  String get editorPickOne => 'Elige una';

  @override
  String get editorChange => 'CAMBIAR ▾';

  @override
  String get editorNewCategoryCaption => 'NUEVA CATEGORÍA';

  @override
  String get editorCategoryNameHint => 'Nombre';

  @override
  String get editorCancel => 'Cancelar';

  @override
  String get editorCreate => 'Crear';

  @override
  String get editorNewCategoryDescription => 'Tu propia categoría.';

  @override
  String get callsScreenTitle => 'Llamadas falsas';

  @override
  String get callsAddTemplate => 'Agregar contacto';

  @override
  String get callsNew => 'NUEVO';

  @override
  String get callsEmptyTitle => 'Aún no hay contactos';

  @override
  String get callsEmptyBody =>
      'Guarda un nombre, una foto y un estilo de pantalla, y llama cuando necesites una salida.';

  @override
  String get callEditorTitleEdit => 'Editar contacto';

  @override
  String get callEditorTitleNew => 'Nuevo contacto';

  @override
  String get callEditorDeleteTemplate => 'Eliminar contacto';

  @override
  String callEditorDeleteTemplateMessage(String name) {
    return 'Se eliminará $name, junto con su foto.';
  }

  @override
  String get callEditorNameCaption => 'NOMBRE';

  @override
  String get callEditorNameHint => 'Nombre de quien llama';

  @override
  String get callEditorNumberCaption => 'NÚMERO';

  @override
  String get callEditorRingtoneCaption => 'TONO';

  @override
  String get callEditorRingForCaption => 'SONAR DURANTE';

  @override
  String get callEditorHangUpAfterCaption => 'COLGAR DESPUÉS DE';

  @override
  String get callEditorSchedulingPremiumTitle =>
      'Programar con más anticipación es Premium';

  @override
  String callEditorSchedulingPremiumBody(int minutes) {
    return 'La versión gratuita programa una llamada hasta $minutes minutos antes. Premium elimina el límite y agrega una hora fija del día.';
  }

  @override
  String get callEditorSchedulingPremiumFootnote =>
      'Llamar ahora mismo siempre es gratis.';

  @override
  String get callEditorSaveTemplate => 'Guardar contacto';

  @override
  String get callEditorPhotoUnreadable => 'No se pudo leer esa foto.';

  @override
  String callEditorScheduledExact(String when) {
    return 'Llamada programada para las $when.';
  }

  @override
  String callEditorScheduledApprox(String when) {
    return 'Llamada programada para alrededor de las $when.';
  }

  @override
  String callEditorScheduledExactBanner(String when) {
    return 'Llamada programada para las $when. Llegará como notificación.';
  }

  @override
  String callEditorScheduledApproxBanner(String when) {
    return 'Llamada programada para alrededor de las $when. Llegará como notificación.';
  }

  @override
  String get callEditorRingOn => 'SÍ';

  @override
  String get callEditorAutoEndOff => 'NO';

  @override
  String get callEditorVibrateSemantics => 'Vibrar mientras suena';

  @override
  String get callEditorVibrateLabel => 'Vibración';

  @override
  String get callEditorVibrateDetail => 'Vibra junto con el tono';

  @override
  String get callEditorPickPhoto => 'Elegir una foto';

  @override
  String get callEditorRemovePhoto => 'Quitar foto';

  @override
  String get callEditorPickRingtone => 'Elegir un tono';

  @override
  String get blackoutHoldToAbort => 'MANTÉN PULSADO PARA CANCELAR';

  @override
  String get blackoutHoldToExit => 'MANTÉN PULSADO PARA SALIR';

  @override
  String get blackoutArmed => 'ARMADO';

  @override
  String get blackoutFiringIn => 'SUENA EN…';

  @override
  String get blackoutStandby => 'EN ESPERA';

  @override
  String get blackoutLive => 'ACTIVO';

  @override
  String get blackoutPaused => 'PAUSADO';

  @override
  String get blackoutDone => 'LISTO';

  @override
  String get blackoutGetOutLine => 'TU FRASE DE SALIDA';

  @override
  String get browseRowSemantics => 'Explorar todos los sonidos';

  @override
  String get browseRowTitle => 'Explorar todo';

  @override
  String browseRowCounts(int categories, int sounds) {
    return '$categories CATEGORÍAS · $sounds SONIDOS';
  }

  @override
  String quickSlotFireSemantics(String label) {
    return 'Activar $label';
  }

  @override
  String get quickSlotTapToFire => 'TOCA PARA ACTIVAR →';

  @override
  String get confirmCancel => 'Cancelar';

  @override
  String get confirmDelete => 'Eliminar';

  @override
  String get selectorFuseCaption => 'MECHA';

  @override
  String get selectorLoopCaption => 'BUCLE';

  @override
  String get slotPickerTitle => '¿En qué ranura lo fijamos?';

  @override
  String get slotPickerPinningPrefix => 'Fijando ';

  @override
  String slotPickerReplaceSlot(int slot, String label) {
    return 'Reemplazar ranura 0$slot, $label';
  }

  @override
  String slotPickerSlotBadge(int slot) {
    return 'RANURA 0$slot';
  }

  @override
  String get soundRowStopPreview => 'Detener vista previa';

  @override
  String get soundRowPreview => 'Vista previa';

  @override
  String get soundRowPinToSlot => 'Fijar a una ranura';

  @override
  String get soundRowFullLength => 'Duración completa';

  @override
  String soundRowTrimRange(String start, String end) {
    return 'Recorte $start–$end';
  }

  @override
  String soundRowHoldToDelete(String window) {
    return '$window · mantén pulsado para eliminar';
  }

  @override
  String get soundRowAddYourAudio => 'Agrega tu audio';

  @override
  String get soundRowAddYourAudioCaption => 'AGREGA TU AUDIO';

  @override
  String get trimTimelineCaption => 'TRAMO A RECORTAR';

  @override
  String get permissionNoticeBlockedTitle =>
      'Las notificaciones están bloqueadas';

  @override
  String get permissionNoticeBody =>
      'Los controles en pantalla de bloqueo necesitan permiso para mostrar una notificación neutra. Sin él, el sonido igual se activa, pero no puedes pausarlo sin volver a abrir la app — y Android puede detener el audio por su cuenta después de unos minutos. Las llamadas falsas no necesitan esto: suenan mientras tienes la app abierta.';

  @override
  String get permissionNoticeOpenAppSettings => 'Abrir ajustes de la app';

  @override
  String get permissionNoticeAllowNotifications => 'Permitir notificaciones';

  @override
  String get permissionNoticeOpenSettings => 'Abrir ajustes';

  @override
  String get permissionNoticeAllow => 'Permitir';

  @override
  String get splashTagline => 'SIEMPRE HAY UNA SALIDA';

  @override
  String get scheduleNoticeNotificationsTitle =>
      'Las llamadas programadas necesitan notificaciones';

  @override
  String get scheduleNoticeNotificationsBody =>
      'Una llamada que llega con ExitPlan cerrado llega como notificación. Sin permiso, no llegará nada — llamar desde dentro de la app sigue funcionando.';

  @override
  String get scheduleNoticeExactAlarmTitle => 'La llamada puede llegar tarde';

  @override
  String get scheduleNoticeExactAlarmBody =>
      'Android necesita permiso para despertar el teléfono en un momento exacto. Sin él, la llamada igual llega, pero unos minutos después de la hora fijada.';

  @override
  String get scheduleNoticeFullScreenTitle =>
      'La llamada no ocupará toda la pantalla';

  @override
  String get scheduleNoticeFullScreenBody =>
      'Sin esto, la llamada llega como una notificación en la parte superior en vez de ocupar toda la pantalla. Igual suena y vibra, y al tocarla se abre la llamada.';

  @override
  String get scheduleCaption => 'PROGRAMAR';

  @override
  String get scheduleInCaption => 'EN';

  @override
  String get scheduleArrivesWhenClosed =>
      'La llamada llega aunque ExitPlan esté cerrado y el teléfono bloqueado.';

  @override
  String get scheduleModeNow => 'AHORA';

  @override
  String get scheduleModeInMinutes => 'EN…';

  @override
  String get scheduleModeAtTime => 'A LAS…';

  @override
  String get callThemePickerCaption => 'PANTALLA DE LLAMADA';

  @override
  String callThemePickerLockedSemantics(String name) {
    return '$name, Premium';
  }

  @override
  String get callThemePickerDefaultCaller => 'Quien llama';

  @override
  String get premiumGateCallPresetsPlural => 'contactos de llamadas falsas';

  @override
  String get premiumGateCallPresetsSingular => 'contacto';

  @override
  String get premiumGateUserSoundsPlural => 'sonidos importados';

  @override
  String get premiumGateUserSoundsSingular => 'sonido';

  @override
  String get premiumGateUserCategoriesPlural => 'categorías propias';

  @override
  String get premiumGateUserCategoriesSingular => 'categoría';

  @override
  String premiumGateTitle(int cap, String unit) {
    return 'Eso son $cap $unit';
  }

  @override
  String premiumGateGrandfatheredBody(int cap) {
    return 'Tenías $cap antes de que esta versión agregara límites, así que los conservaste todos. Premium elimina el límite por completo.';
  }

  @override
  String premiumGateLimitBody(int freeLimit, String plural) {
    return 'La versión gratuita cubre $freeLimit. Premium elimina el límite de $plural, y los anuncios con él.';
  }

  @override
  String premiumGateThemeTitle(String themeName) {
    return '$themeName es un tema Premium';
  }

  @override
  String get premiumGateThemeBody =>
      'Premium desbloquea todas las pantallas de llamada y elimina los anuncios. Los temas gratuitos se quedan exactamente donde están.';

  @override
  String get premiumGateThemeFootnote =>
      'Los contactos que ya guardaste conservan el tema con el que se guardaron.';

  @override
  String get premiumGateDefaultFootnote =>
      'Nada de lo que ya creaste se ve afectado.';

  @override
  String get premiumGateSeePremium => 'Ver Premium';

  @override
  String get premiumGateNotNow => 'Ahora no';

  @override
  String callPresetCardEdit(String name) {
    return 'Editar $name';
  }

  @override
  String callPresetCardRing(String name) {
    return 'Llamar a $name';
  }

  @override
  String callPresetCardCancel(String name) {
    return 'Cancelar la llamada programada a $name';
  }

  @override
  String callPresetCardScheduledFor(String when) {
    return 'PROGRAMADA · $when';
  }

  @override
  String get callThemeMissedCall => 'Llamada perdida';

  @override
  String get callActionDecline => 'Rechazar';

  @override
  String get callActionDeclineCall => 'Rechazar llamada';

  @override
  String get callActionAccept => 'Aceptar';

  @override
  String get callActionAcceptCall => 'Aceptar llamada';

  @override
  String get callActionEndCall => 'Colgar';

  @override
  String get callGridMute => 'Silenciar';

  @override
  String get callGridKeypad => 'Teclado';

  @override
  String get callGridSpeaker => 'Altavoz';

  @override
  String get callGridMuteLower => 'silenciar';

  @override
  String get callGridKeypadLower => 'teclado';

  @override
  String get callGridSpeakerLower => 'altavoz';

  @override
  String get callBusinessBadge => 'TRABAJO';

  @override
  String get callBusinessIncomingCall => 'Llamada entrante';

  @override
  String get callBusinessAnswer => 'Contestar';

  @override
  String get callMinimalIncoming => 'Entrante';

  @override
  String get callMinimalSlideUp => 'Desliza hacia arriba';

  @override
  String get callChatGreenVoiceCall => 'Llamada de voz…';

  @override
  String get callChatGreenMoreOptions => 'Más opciones';

  @override
  String get callChatGreenToggleVideo => 'Alternar video';

  @override
  String get callChatGreenToggleSpeaker => 'Alternar altavoz';

  @override
  String get callChatGreenToggleMute => 'Alternar silencio';

  @override
  String get callMaterialIncomingCall => 'Llamada entrante';

  @override
  String get callMaterialSwipeUpDecline => 'Desliza hacia arriba para rechazar';

  @override
  String get callMaterialSwipeUpAnswer => 'Desliza hacia arriba para contestar';

  @override
  String get callChatBlueIncomingVoiceCall => 'Llamada de voz entrante';

  @override
  String get callChatBlueVideo => 'Video';

  @override
  String get callClassicIncomingCall => 'llamada entrante';

  @override
  String get callClassicSlideUpToAnswer =>
      'Desliza hacia arriba para contestar';

  @override
  String get callClassicAddCall => 'añadir llamada';

  @override
  String get callClassicContacts => 'contactos';

  @override
  String get forceUpdateCaption => 'ACTUALIZACIÓN REQUERIDA';

  @override
  String get forceUpdateTitle =>
      'Esta versión es demasiado antigua para seguir usándola con seguridad.';

  @override
  String get forceUpdateBody =>
      'Hay una actualización obligatoria disponible. Instálala para seguir usando la app — esta pantalla no desaparecerá sola.';

  @override
  String get forceUpdateButton => 'Actualizar ahora';
}
