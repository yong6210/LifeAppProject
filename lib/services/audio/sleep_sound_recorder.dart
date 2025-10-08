import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Provides a thin wrapper around the Record plugin so the app can
/// experiment with sleep sound recordings without committing to a fully
/// fledged implementation. The class exposes a simple amplitude stream that
/// higher level widgets can use to build visual feedback while recording.
class SleepSoundRecorder {
  SleepSoundRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final _amplitudeController = StreamController<double>.broadcast();
  Timer? _amplitudeTimer;

  /// Public stream of the latest normalized amplitudes (0-1).
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Returns `true` when microphone permissions are granted.
  Future<bool> ensurePermissions() async {
    if (await _recorder.hasPermission()) {
      return true;
    }
    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  /// Starts a recording session and returns the output file path.
  Future<String?> startRecording() async {
    if (await _recorder.isRecording()) {
      return null;
    }

    final allowed = await ensurePermissions();
    if (!allowed) {
      return null;
    }

    final dir = await _temporaryDirectory();
    final fileName =
        'sleep_sound_${DateTime.now().toIso8601String().replaceAll(':', '-')}.m4a';
    final path = p.join(dir.path, fileName);

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _startAmplitudeTimer();
    return path;
  }

  /// Stops the recording session and returns the final path if any.
  Future<String?> stopRecording() async {
    _stopAmplitudeTimer();
    if (!await _recorder.isRecording()) {
      return null;
    }
    return _recorder.stop();
  }

  Future<void> dispose() async {
    _stopAmplitudeTimer();
    await _amplitudeController.close();
  }

  void _startAmplitudeTimer() {
    _stopAmplitudeTimer();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) async {
      final amplitude = await _recorder.getAmplitude();
      final normalized = _normalizeDecibel(amplitude.current);
      _amplitudeController.add(normalized);
    });
  }

  void _stopAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  double _normalizeDecibel(double db) {
    final clamped = db.clamp(-60, 0);
    return math.pow(10, clamped / 20).toDouble();
  }

  Future<Directory> _temporaryDirectory() async {
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    return getTemporaryDirectory();
  }
}

/// Convenience singleton for quick experiments.
final sleepSoundRecorder = SleepSoundRecorder();
