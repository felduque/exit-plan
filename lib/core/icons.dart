import 'package:flutter/material.dart';

import 'theme.dart';

/// A closed catalog: sounds and categories store an icon *name*, never an
/// IconData. The editor lets the user pick from exactly these, which keeps
/// persisted data valid even if the icon set is reshuffled later.
const Map<String, IconData> kIconCatalog = <String, IconData>{
  'doorbell': Icons.doorbell_outlined,
  'bell': Icons.notifications_active_outlined,
  'chime': Icons.music_note_outlined,
  'knock': Icons.back_hand_outlined,
  'intercom': Icons.dialpad,
  'alarm': Icons.alarm,
  'siren': Icons.campaign_outlined,
  'emergency': Icons.warning_amber_outlined,
  'smoke': Icons.crisis_alert_outlined,
  'exit': Icons.exit_to_app,
  'signal-off': Icons.signal_cellular_nodata,
  'wifi-off': Icons.wifi_off_outlined,
  'tower': Icons.cell_tower,
  'call-end': Icons.phone_disabled_outlined,
  'static': Icons.blur_on,
  'waveform': Icons.graphic_eq,
  'fire': Icons.local_fire_department_outlined,
  'fireplace': Icons.fireplace_outlined,
  'hot': Icons.whatshot_outlined,
  'storm': Icons.thunderstorm_outlined,
  'rain': Icons.water_drop_outlined,
  'wind': Icons.air,
  'cloud': Icons.cloud_outlined,
  'bolt': Icons.bolt,
  'plug': Icons.electrical_services_outlined,
  'power': Icons.power_settings_new,
  'sensors': Icons.sensors,
  'audio': Icons.audiotrack_outlined,
  'volume': Icons.volume_up_outlined,
  'folder': Icons.folder_outlined,
};

/// Falls back instead of throwing: a persisted icon name that no longer exists
/// must not break a screen.
IconData iconFor(String name) =>
    kIconCatalog[name] ?? Icons.audiotrack_outlined;

/// Icon names offered in the editor, in display order.
List<String> get kPickableIcons => kIconCatalog.keys.toList(growable: false);

/// Accent colour per system category, so a tile is recognisable before its label
/// is read. Every hue is muted: it appears as a 2px edge, an icon or a 7px
/// square, never as a filled field.
///
/// Red belongs to fire and to nothing else — it is the one category that really
/// does mean emergency, and reusing it elsewhere would spend that meaning.
/// Anything unlisted — every user category — falls back to the caller's colour,
/// which is green everywhere the app draws imported content.
const Map<String, Color> kCategoryAccent = <String, Color>{
  'doorbell': ExitColors.blue,
  'alarms': ExitColors.amber,
  'bad-signal': ExitColors.violet,
  'fire': ExitColors.red,
  'storm': ExitColors.teal,
  'electric': ExitColors.yellow,
};

Color accentForCategory(
  String categoryId, {
  Color fallback = ExitColors.green,
}) => kCategoryAccent[categoryId] ?? fallback;
