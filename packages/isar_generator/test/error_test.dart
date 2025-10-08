import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_generator/isar_generator.dart';
import 'package:test/test.dart';

void main() {
  final readerWriter = TestReaderWriter(rootPackage: 'isar_generator');

  setUpAll(() async {
    await readerWriter.testing.loadIsolateSources();
  });

  group('Error case', () {
    for (final file in Directory('test/errors').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      test(file.path, () async {
        final content = await file.readAsLines();

        final errorMessage = content.first.split('//').last.trim();

        var error = '';
        try {
          await testBuilder(
            getIsarGenerator(BuilderOptions.empty),
            {'a|${file.path}': content.join('\n')},
            readerWriter: readerWriter,
          );
        } catch (e) {
          error = e.toString();
        }

        expect(error.toLowerCase(), contains(errorMessage.toLowerCase()));
      });
    }
  });
}
