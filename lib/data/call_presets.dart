import '../models/call_preset.dart';

/// Fresh installs start with no call templates: an empty list plus the "Add
/// template" tile, exactly like the user's own sound library starts empty.
/// There is nothing to curate here — unlike the system sound catalogue, a
/// caller name and photo are inherently the user's own content.
const List<CallPreset> kDefaultCallPresets = <CallPreset>[];

/// Id for a newly created [CallPreset], following the same
/// `prefix-microsecondTimestamp` shape as user sounds and categories.
String newCallPresetId() => 'call-${DateTime.now().microsecondsSinceEpoch}';
