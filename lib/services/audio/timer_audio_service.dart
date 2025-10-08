import 'dart:math';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:life_app/services/audio/sleep_sound_catalog.dart';

/// Minimal contract the timer controller relies on so tests can inject fakes.
abstract class TimerAudioEngine {
  Future<void> init();
  Future<void> configureSleepAmbience({
    required double white,
    required double pink,
    required double brown,
    required String presetId,
  });
  Future<void> setEnabled(bool enabled, {String? profile});
  Future<void> updateProfile(String? profile);
  Future<void> dispose();
}

class TimerAudioService implements TimerAudioEngine {
  TimerAudioService() : _player = AudioPlayer();

  final AudioPlayer _player;
  final Map<String, AudioPlayer> _mixerPlayers = {};
  final Map<double, Uint8List> _toneCache = {};
  final Map<String, Uint8List> _noiseCache = {};
  final Map<String, String> _layerSources = {};
  final Random _random = Random();
  bool _enabled = false;
  String? _currentProfile;
  bool _initialized = false;
  String _currentPresetId = SleepSoundCatalog.defaultPresetId;
  Map<String, double> _activeMixerLevels = {};
  SleepSoundCatalog? _catalog;
  static Future<SleepSoundCatalog>? _catalogFuture;

  static const Set<String> _sleepProfiles = {
    'sleep',
    'sleep_prepare',
    'sleep_relax',
  };

  static const Map<String, double> _profileFrequencies = {
    'focus': 528,
    'rest': 432,
    'breath': 396,
    'calm': 320,
    'workout': 660,
    'sleep': 174,
    'sleep_prepare': 285,
    'sleep_relax': 250,
  };

  @override
  Future<void> init() async {
    if (_initialized) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _initialized = true;
  }

  Future<SleepSoundCatalog> _catalogOnce() async {
    _catalog ??= await (_catalogFuture ??= SleepSoundCatalog.load());
    return _catalog!;
  }

  @override
  Future<void> configureSleepAmbience({
    required double white,
    required double pink,
    required double brown,
    required String presetId,
  }) async {
    final catalog = await _catalogOnce();
    _currentPresetId = presetId.isEmpty
        ? SleepSoundCatalog.defaultPresetId
        : presetId;

    if (_currentPresetId == SleepSoundCatalog.defaultPresetId) {
      _activeMixerLevels = {
        'white_noise': white.clamp(0.0, 1.0),
        'pink_noise': pink.clamp(0.0, 1.0),
        'brown_noise': brown.clamp(0.0, 1.0),
      }..removeWhere((_, value) => value <= 0);
    } else {
      final preset = catalog.presetById(_currentPresetId);
      _activeMixerLevels = Map<String, double>.fromEntries(
        preset.layers.entries.map(
          (entry) => MapEntry(entry.key, entry.value.clamp(0.0, 1.0)),
        ),
      )..removeWhere((_, value) => value <= 0);
    }

    if (_enabled && _shouldUseMixer(_currentProfile)) {
      await _playMixer();
    } else if (_activeMixerLevels.isEmpty) {
      await _stopMixer();
    }
  }

  @override
  Future<void> setEnabled(bool enabled, {String? profile}) async {
    _enabled = enabled;
    if (!_enabled) {
      await _player.stop();
      await _stopMixer();
      _currentProfile = null;
      return;
    }
    await updateProfile(profile);
  }

  @override
  Future<void> updateProfile(String? profile) async {
    if (!_enabled) {
      _currentProfile = profile;
      return;
    }
    final target = profile ?? _currentProfile;
    if (target == null) {
      await _player.stop();
      await _stopMixer();
      return;
    }
    if (_currentProfile == target && _player.playing) {
      return;
    }
    _currentProfile = target;
    if (_shouldUseMixer(target)) {
      await _playMixer();
    } else {
      await _playTone(target);
    }
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    for (final player in _mixerPlayers.values) {
      await player.dispose();
    }
    _mixerPlayers.clear();
    _layerSources.clear();
  }

  bool _shouldUseMixer(String? profile) {
    if (profile == null) return false;
    if (!_sleepProfiles.contains(profile)) return false;
    if (_activeMixerLevels.isEmpty) return false;
    return true;
  }

  Future<void> _playTone(String profile) async {
    await _stopMixer();
    final frequency = _profileFrequencies[profile] ?? 440;
    final toneBytes = await _toneBytes(frequency);
    final source = AudioSource.uri(
      Uri.dataFromBytes(toneBytes, mimeType: 'audio/wav'),
    );
    await _player.setLoopMode(LoopMode.one);
    await _player.setAudioSource(source);
    await _player.setVolume(0.35);
    await _player.play();
  }

  Future<AudioPlayer> _ensureLayerPlayer(
    String layerId,
    SleepSoundLayer layer,
  ) async {
    final player = _mixerPlayers.putIfAbsent(layerId, () => AudioPlayer());
    final expectedSource =
        layer.asset ?? 'generated:${layer.fallbackNoise ?? layerId}';
    if (_layerSources[layerId] == expectedSource &&
        player.audioSource != null) {
      return player;
    }

    try {
      if (layer.asset != null) {
        await player.setAudioSource(AudioSource.asset(layer.asset!));
        await player.setLoopMode(LoopMode.one);
        _layerSources[layerId] = expectedSource;
        return player;
      }
    } catch (error) {
      debugPrint(
        'TimerAudioService: failed to load asset for $layerId (${layer.asset}). '
        'Falling back to generated noise. Error: $error',
      );
    }

    final fallbackType = layer.fallbackNoise ?? layerId;
    final data = await _noiseBytes(fallbackType);
    await player.setAudioSource(
      AudioSource.uri(Uri.dataFromBytes(data, mimeType: 'audio/wav')),
    );
    await player.setLoopMode(LoopMode.one);
    _layerSources[layerId] = 'generated:$fallbackType';
    return player;
  }

  Future<void> _playMixer() async {
    await _player.stop();
    if (_activeMixerLevels.values.every((level) => level <= 0)) {
      await _stopMixer();
      return;
    }

    final catalog = await _catalogOnce();
    final retained = <String>{};

    for (final entry in _activeMixerLevels.entries) {
      final level = entry.value.clamp(0.0, 1.0);
      if (level <= 0) continue;
      final layer = catalog.layerById(entry.key);
      if (layer == null) continue;
      final player = await _ensureLayerPlayer(entry.key, layer);
      await player.setVolume(level);
      if (!player.playing) {
        await player.play();
      }
      retained.add(entry.key);
    }

    for (final layerId in _mixerPlayers.keys.toList()) {
      if (!retained.contains(layerId)) {
        await _mixerPlayers[layerId]?.pause();
      }
    }
  }

  Future<void> _stopMixer() async {
    for (final player in _mixerPlayers.values) {
      await player.pause();
    }
  }

  Future<Uint8List> _toneBytes(double frequency) async {
    if (_toneCache.containsKey(frequency)) {
      return _toneCache[frequency]!;
    }
    const sampleRate = 44100;
    const durationSeconds = 1;
    final totalSamples = sampleRate * durationSeconds;
    final bytes = BytesBuilder();

    void writeString(String value) => bytes.add(value.codeUnits);
    void writeUint32(int value) {
      final buffer = ByteData(4)..setUint32(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    void writeUint16(int value) {
      final buffer = ByteData(2)..setUint16(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    void writeInt16(int value) {
      final buffer = ByteData(2)..setInt16(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    writeString('RIFF');
    writeUint32(36 + totalSamples * 2);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16); // Subchunk1 size
    writeUint16(1); // PCM
    writeUint16(1); // channels
    writeUint32(sampleRate);
    writeUint32(sampleRate * 2); // byte rate
    writeUint16(2); // block align
    writeUint16(16); // bits per sample
    writeString('data');
    writeUint32(totalSamples * 2);

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final sampleValue = (sin(2 * pi * frequency * t) * 32767 * 0.3).round();
      writeInt16(sampleValue);
    }

    final data = bytes.toBytes();
    _toneCache[frequency] = data;
    return data;
  }

  Future<Uint8List> _noiseBytes(String type) async {
    final cacheKey = 'noise_$type';
    if (_noiseCache.containsKey(cacheKey)) {
      return _noiseCache[cacheKey]!;
    }

    const sampleRate = 44100;
    const durationSeconds = 4;
    final totalSamples = sampleRate * durationSeconds;
    final bytes = BytesBuilder();

    void writeString(String value) => bytes.add(value.codeUnits);
    void writeUint32(int value) {
      final buffer = ByteData(4)..setUint32(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    void writeUint16(int value) {
      final buffer = ByteData(2)..setUint16(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    void writeInt16(int value) {
      final buffer = ByteData(2)..setInt16(0, value, Endian.little);
      bytes.add(buffer.buffer.asUint8List());
    }

    writeString('RIFF');
    writeUint32(36 + totalSamples * 2);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(1);
    writeUint32(sampleRate);
    writeUint32(sampleRate * 2);
    writeUint16(2);
    writeUint16(16);
    writeString('data');
    writeUint32(totalSamples * 2);

    var pinkState = 0.0;
    var brownState = 0.0;

    for (var i = 0; i < totalSamples; i++) {
      final white = _random.nextDouble() * 2 - 1;
      double sample;
      switch (type) {
        case 'pink':
        case 'pink_noise':
          pinkState = 0.94 * pinkState + 0.06 * white;
          sample = (pinkState + white) / 2;
          break;
        case 'brown':
        case 'brown_noise':
          brownState = (brownState + white * 0.02).clamp(-1.0, 1.0);
          sample = brownState;
          break;
        case 'white_noise':
        case 'white':
        default:
          sample = white;
          break;
      }
      final value = (sample * 32767 * 0.6).round();
      writeInt16(value);
    }

    final data = bytes.toBytes();
    _noiseCache[cacheKey] = data;
    return data;
  }
}
