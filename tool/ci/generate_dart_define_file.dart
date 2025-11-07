import 'dart:convert';
import 'dart:io';

/// Generates a Flutter `--dart-define-from-file` payload for CI or local builds.
///
/// Usage:
/// ```
/// dart run tool/ci/generate_dart_define_file.dart --flavor=prod
/// ```
///
/// Options (all passed as `--key=value`):
/// - `flavor` (default `dev`): which flavor to target. Controls defaults and the
///   injected `FLAVOR` entry.
/// - `env-var`: environment variable containing a base64-encoded `.env` payload.
///   Defaults to `DART_DEFINE_<FLAVOR>`.
/// - `env-file`: fallback file to read when the environment variable is absent.
///   Defaults to `.env.<flavor>`.
/// - `output`: where to write the generated file. Defaults to
///   `build/ci/dart-defines/<flavor>.env`.
/// - `include-flavor`: set to `false` to skip injecting the `FLAVOR` entry.
///
/// The output file is compatible with `flutter build ... --dart-define-from-file`.
void main(List<String> args) {
  final options = _parseOptions(args);
  final flavor = options['flavor'] ?? 'dev';
  final envVarName =
      options['env-var'] ?? 'DART_DEFINE_${flavor.toUpperCase()}';
  final envFilePath = options['env-file'] ?? '.env.$flavor';
  final outputPath = options['output'] ?? 'build/ci/dart-defines/$flavor.env';
  final includeFlavor =
      (options['include-flavor'] ?? 'true').toLowerCase() != 'false';

  try {
    final payload = _loadPayload(envVarName, envFilePath);

    final entries = _parseEnvEntries(payload);
    if (includeFlavor) {
      entries.removeWhere((entry) => entry.key == 'FLAVOR');
      entries.insert(0, MapEntry('FLAVOR', flavor));
    }

    final outputFile = File(outputPath);
    outputFile.parent.createSync(recursive: true);

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    outputFile.writeAsStringSync(buffer.toString());

    final reportedCount = entries.length;
    stdout
      ..writeln(
        'Generated $reportedCount dart-define entr${reportedCount == 1 ? 'y' : 'ies'} at ${outputFile.path}',
      )
      ..writeln('--dart-define-from-file=${outputFile.path}');
  } on _SilentExit {
    // `_loadPayload` already reported the error and set `exitCode`.
    if (exitCode == 0) {
      exitCode = 1;
    }
  }
}

Map<String, String> _parseOptions(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) {
      stderr.writeln('Ignoring unsupported argument format: $arg');
      continue;
    }
    final eqIndex = arg.indexOf('=');
    if (eqIndex == -1) {
      result[arg.substring(2)] = 'true';
      continue;
    }
    final key = arg.substring(2, eqIndex);
    final value = arg.substring(eqIndex + 1);
    result[key] = value;
  }
  return result;
}

String _loadPayload(String envVarName, String envFilePath) {
  final rawEnvValue = Platform.environment[envVarName];
  if (rawEnvValue != null && rawEnvValue.trim().isNotEmpty) {
    try {
      return utf8.decode(base64.decode(rawEnvValue));
    } catch (error) {
      stderr.writeln(
        'Failed to decode base64 secret from environment variable '
        '$envVarName: $error',
      );
      exitCode = 1;
      throw _SilentExit();
    }
  }

  final file = File(envFilePath);
  if (!file.existsSync()) {
    stderr.writeln(
      'No secrets found. Provide base64 data via $envVarName or create '
      '$envFilePath.',
    );
    exitCode = 1;
    throw _SilentExit();
  }
  return file.readAsStringSync();
}

List<MapEntry<String, String>> _parseEnvEntries(String payload) {
  final entries = <MapEntry<String, String>>[];

  for (final rawLine in payload.split(RegExp(r'\r?\n'))) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    final separatorIndex = rawLine.indexOf('=');
    if (separatorIndex <= 0) {
      stderr.writeln('Skipping malformed line: $rawLine');
      continue;
    }

    final key = rawLine.substring(0, separatorIndex).trim();
    final value = rawLine.substring(separatorIndex + 1).trimLeft();

    entries.removeWhere((entry) => entry.key == key);
    entries.add(MapEntry(key, value));
  }

  return entries;
}

class _SilentExit implements Exception {}
