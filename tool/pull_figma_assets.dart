import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Pulls raster/vector exports from Figma using the REST API.
///
/// Usage:
/// ```bash
/// FIGMA_PERSONAL_TOKEN=xxx dart run tool/pull_figma_assets.dart \
///   --manifest=tool/figma_assets.json \
///   --out=assets/figma_exports
/// ```
///
/// The manifest file should look like:
/// ```json
/// {
///   "fileKey": "YOUR_FILE_KEY",
///   "assets": [
///     {
///       "nodeId": "123:456",
///       "name": "journal_calendar_cell",
///       "format": "png",
///       "scale": 2,
///       "output": "journal"
///     }
///   ]
/// }
/// ```
Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final manifestPath = options['manifest'] ?? 'tool/figma_assets.json';
  final outputDir = options['out'] ?? 'assets/figma_exports';

  final figmaToken = Platform.environment['FIGMA_PERSONAL_TOKEN'];
  if (figmaToken == null || figmaToken.isEmpty) {
    _exitWithError(
      'Missing FIGMA_PERSONAL_TOKEN.\n'
      'Create one in https://www.figma.com/developers/api and re-run with '
      '`FIGMA_PERSONAL_TOKEN=... dart run tool/pull_figma_assets.dart`.',
    );
    return; // Unreachable, but helps type inference
  }

  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    _exitWithError('Manifest file not found: $manifestPath');
  }

  final manifestJson =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final fileKey = manifestJson['fileKey'] as String? ?? '';
  if (fileKey.isEmpty) {
    _exitWithError('`fileKey` missing in $manifestPath');
  }

  final assets =
      (manifestJson['assets'] as List<dynamic>? ?? const []).cast<Map<dynamic, dynamic>>();
  if (assets.isEmpty) {
    stdout.writeln('No assets defined in $manifestPath. Nothing to download.');
    return;
  }

  final outDir = Directory(outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  stdout.writeln(
    'Pulling ${assets.length} asset(s) from Figma file $fileKey '
    'into ${outDir.path}',
  );

  var failures = 0;
  for (final raw in assets) {
    final asset = _FigmaAsset.fromJson(raw.cast<String, dynamic>());
    try {
      // figmaToken is guaranteed non-null after the check above
      await _downloadAsset(asset, fileKey, figmaToken, outDir.path);
      stdout.writeln('✓ ${asset.name}.${asset.format}');
    } catch (err) {
      failures++;
      stderr.writeln('✗ ${asset.name}: $err');
    }
  }

  if (failures > 0) {
    _exitWithError('$failures asset(s) failed to download.');
  }

  stdout.writeln('Done ✅');
}

Future<void> _downloadAsset(
  _FigmaAsset asset,
  String fileKey,
  String token,
  String outputDir,
) async {
  final imageUrl = await _requestImageUrl(asset, fileKey, token);
  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode != 200) {
    throw 'Failed to download bytes (${response.statusCode})';
  }

  final destinationDir = Directory(
    p.normalize(p.join(outputDir, asset.output ?? '')),
  );
  if (!destinationDir.existsSync()) {
    destinationDir.createSync(recursive: true);
  }

  final filePath =
      p.join(destinationDir.path, '${asset.name}.${asset.format}');
  await File(filePath).writeAsBytes(response.bodyBytes);
}

Future<String> _requestImageUrl(
  _FigmaAsset asset,
  String fileKey,
  String token,
) async {
  final queryParameters = <String, String>{
    'ids': asset.nodeId,
    'format': asset.format,
  };
  if (asset.scale != null && asset.format != 'svg') {
    queryParameters['scale'] = asset.scale.toString();
  }

  final uri = Uri.https(
    'api.figma.com',
    '/v1/images/$fileKey',
    queryParameters,
  );

  final response = await http.get(
    uri,
    headers: {'X-Figma-Token': token},
  );

  if (response.statusCode != 200) {
    throw 'Figma API failed (${response.statusCode}): ${response.body}';
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final images = body['images'] as Map<String, dynamic>? ?? const {};
  final imageUrl = images[asset.nodeId] as String?;
  if (imageUrl == null || imageUrl.isEmpty) {
    throw 'Image URL missing for node ${asset.nodeId}';
  }
  return imageUrl;
}

void _exitWithError(String message) {
  stderr.writeln(message);
  exitCode = 1;
  throw Exception(message);
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final parts = arg.substring(2).split('=');
    if (parts.length == 2) {
      result[parts.first] = parts.last;
    }
  }
  return result;
}

class _FigmaAsset {
  _FigmaAsset({
    required this.nodeId,
    required this.name,
    required this.format,
    this.scale,
    this.output,
  });

  factory _FigmaAsset.fromJson(Map<String, dynamic> json) {
    final format = (json['format'] as String? ?? 'png').toLowerCase();
    final scale = json['scale'];
    return _FigmaAsset(
      nodeId: json['nodeId'] as String? ??
          (throw ArgumentError('`nodeId` missing in asset config')),
      name: json['name'] as String? ??
          (throw ArgumentError('`name` missing in asset config')),
      format: format,
      scale: scale is num ? scale.toDouble() : null,
      output: json['output'] as String?,
    );
  }

  final String nodeId;
  final String name;
  final String format;
  final double? scale;
  final String? output;
}
