import 'dart:io';

const _mastersDir = 'assets/audio/master';
const _outputDir = 'assets/audio/app';
const _defaultBitrateKbps = 128;

Future<void> main(List<String> args) async {
  var dryRun = false;
  var preferredEncoder = 'auto';
  var bitrateKbps = _defaultBitrateKbps;
  var outputFormat = 'wav';

  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg.startsWith('--encoder=')) {
      preferredEncoder = arg.substring('--encoder='.length);
    } else if (arg.startsWith('--bitrate=')) {
      final value = int.tryParse(arg.substring('--bitrate='.length));
      if (value != null && value > 0) {
        bitrateKbps = value;
      }
    } else if (arg.startsWith('--format=')) {
      final value = arg.substring('--format='.length).toLowerCase();
      if (value == 'wav' || value == 'm4a') {
        outputFormat = value;
      } else {
        stderr.writeln("Unsupported format '$value'. Use 'wav' or 'm4a'.");
        exitCode = 64;
        return;
      }
    } else {
      stderr.writeln('Unknown argument: $arg');
      exitCode = 64;
      return;
    }
  }

  final masters =
      Directory(_mastersDir)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.wav'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (masters.isEmpty) {
    stderr.writeln('No WAV masters found under $_mastersDir.');
    exitCode = 2;
    return;
  }

  _Encoder? encoder;
  if (outputFormat == 'm4a') {
    encoder = await _Encoder.resolve(preferredEncoder);
    if (encoder == null) {
      stderr.writeln(
        'No audio encoder found. Install ffmpeg or use macOS afconvert.',
      );
      exitCode = 3;
      return;
    }
    stdout.writeln('Using encoder: ${encoder.name}');
  }
  await Directory(_outputDir).create(recursive: true);

  for (final master in masters) {
    final outputName = master.uri.pathSegments.last.replaceAll(
      '.wav',
      outputFormat == 'm4a' ? '.m4a' : '.wav',
    );
    final outputPath = '$_outputDir/$outputName';
    if (outputFormat == 'wav') {
      if (dryRun) {
        stdout.writeln('[dry-run] copy ${master.path} -> $outputPath');
        continue;
      }
      await File(master.path).copy(outputPath);
      stdout.writeln('Copied ${master.path} -> $outputPath');
      continue;
    }

    final args = encoder!.buildArgs(master.path, outputPath, bitrateKbps);

    if (dryRun) {
      stdout.writeln('[dry-run] ${encoder.executable} ${args.join(' ')}');
      continue;
    }

    final result = await Process.run(encoder.executable, args);
    if (result.exitCode != 0) {
      stderr.writeln('Failed to encode ${master.path} -> $outputPath');
      stderr.writeln(result.stderr);
      exitCode = result.exitCode;
      return;
    }
    stdout.writeln('Encoded ${master.path} -> $outputPath');
  }
}

class _Encoder {
  const _Encoder(this.name, this.executable, this._argsBuilder);

  final String name;
  final String executable;
  final List<String> Function(String input, String output, int bitrateKbps)
  _argsBuilder;

  List<String> buildArgs(String input, String output, int bitrateKbps) {
    return _argsBuilder(input, output, bitrateKbps);
  }

  static Future<_Encoder?> resolve(String preference) async {
    final order = <String>[
      if (preference == 'ffmpeg') 'ffmpeg',
      if (preference == 'afconvert') 'afconvert',
      if (preference != 'ffmpeg' && preference != 'afconvert') ...[
        'ffmpeg',
        'afconvert',
      ],
    ];

    for (final candidate in order) {
      final path = await _which(candidate);
      if (path != null) {
        switch (candidate) {
          case 'ffmpeg':
            return _Encoder(
              'ffmpeg',
              path,
              (input, output, bitrateKbps) => [
                '-y',
                '-i',
                input,
                '-ac',
                '1',
                '-c:a',
                'aac',
                '-b:a',
                '${bitrateKbps}k',
                output,
              ],
            );
          case 'afconvert':
            return _Encoder(
              'afconvert',
              path,
              (input, output, bitrateKbps) => [
                '-f',
                'm4af',
                '-d',
                'aac',
                '-b',
                '${bitrateKbps * 1000}',
                '-q',
                '127',
                input,
                output,
              ],
            );
        }
      }
    }

    return null;
  }
}

Future<String?> _which(String command) async {
  try {
    final result = await Process.run('which', [command]);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty) {
        return path;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
