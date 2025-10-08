import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class SleepSoundLayer {
  const SleepSoundLayer({
    required this.id,
    required this.type,
    this.asset,
    this.loop = true,
    this.fallbackNoise,
    this.defaultLevel = 0.8,
  });

  final String id;
  final String type;
  final String? asset;
  final bool loop;
  final String? fallbackNoise;
  final double defaultLevel;

  factory SleepSoundLayer.fromJson(Map<String, dynamic> json) {
    return SleepSoundLayer(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'ambience',
      asset: json['asset'] as String?,
      loop: json['loop'] as bool? ?? true,
      fallbackNoise: json['fallback_noise'] as String?,
      defaultLevel: (json['default_level'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

class SleepSoundPreset {
  SleepSoundPreset({
    required this.id,
    required this.layers,
    this.custom = false,
  });

  final String id;
  final Map<String, double> layers;
  final bool custom;

  factory SleepSoundPreset.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['layers'] as List<dynamic>? ?? const [];
    final layers = <String, double>{};
    for (final raw in rawLayers) {
      if (raw is Map<String, dynamic>) {
        final layerId = raw['layer'] as String?;
        final level = (raw['level'] as num?)?.toDouble();
        if (layerId != null && level != null) {
          layers[layerId] = level.clamp(0.0, 1.0);
        }
      }
    }
    return SleepSoundPreset(
      id: json['id'] as String,
      custom: json['custom'] as bool? ?? false,
      layers: layers,
    );
  }
}

class SleepSoundCatalog {
  SleepSoundCatalog({required this.layers, required this.presets});

  final Map<String, SleepSoundLayer> layers;
  final Map<String, SleepSoundPreset> presets;

  static const String defaultPresetId = 'custom_mix';

  SleepSoundLayer? layerById(String id) => layers[id];

  SleepSoundPreset presetById(String id) {
    return presets[id] ??
        presets[defaultPresetId] ??
        SleepSoundPreset(id: defaultPresetId, custom: true, layers: const {});
  }

  static Future<SleepSoundCatalog> load() async {
    final content = await rootBundle.loadString('assets/audio/manifest.json');
    final data = jsonDecode(content) as Map<String, dynamic>;
    final layersJson = data['layers'] as List<dynamic>? ?? const [];
    final presetsJson = data['presets'] as List<dynamic>? ?? const [];

    final layerMap = <String, SleepSoundLayer>{
      for (final raw in layersJson.whereType<Map<String, dynamic>>())
        raw['id'] as String: SleepSoundLayer.fromJson(raw),
    };

    final presetMap = <String, SleepSoundPreset>{
      for (final raw in presetsJson.whereType<Map<String, dynamic>>())
        raw['id'] as String: SleepSoundPreset.fromJson(raw),
    };

    presetMap.putIfAbsent(
      defaultPresetId,
      () =>
          SleepSoundPreset(id: defaultPresetId, custom: true, layers: const {}),
    );

    return SleepSoundCatalog(layers: layerMap, presets: presetMap);
  }
}
