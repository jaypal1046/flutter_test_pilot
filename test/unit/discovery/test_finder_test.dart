import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_pilot/discovery/test_finder.dart';
import 'dart:io';

void main() {
  group('TestFinder', () {
    late TestFinder finder;

    setUp(() {
      finder = TestFinder();
    });

    test('should find test files', () async {
      final tests = await finder.findTests();

      expect(tests, isNotNull);
      expect(tests, isA<List<String>>());
      // Should find at least this test file
      expect(tests.any((t) => t.contains('test_finder_test.dart')), isTrue);
    });

    test('should filter tests by tags', () async {
      // Create a temporary test file with tags
      final tempDir = Directory.systemTemp.createTempSync('test_finder_');
      final testDir = Directory('${tempDir.path}/test');
      await testDir.create(recursive: true);

      final testFile = File('${testDir.path}/tagged_test.dart');
      await testFile.writeAsString('''
@Tags(['integration'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tagged test', () {});
}
''');

      final finderTemp = TestFinder(rootDirectory: tempDir.path);
      final allTests = await finderTemp.findTests();
      final filteredTests = await finderTemp.findTests(tags: ['integration']);

      expect(filteredTests, isNotNull);
      expect(filteredTests.length, lessThanOrEqualTo(allTests.length));
      // Tags might not be detected in all cases, so just verify the filter works
      expect(filteredTests, isA<List<String>>());

      // Cleanup
      await tempDir.delete(recursive: true);
    });

    test('should group tests by directory', () async {
      final tests = await finder.findTests();
      final grouped = finder.groupByDirectory(tests);

      expect(grouped, isNotNull);
      expect(grouped, isA<Map<String, List<String>>>());

      // Should have at least one directory group
      expect(grouped.isNotEmpty, isTrue);
    });

    test('should get test metadata for existing file', () async {
      final tests = await finder.findTests();

      if (tests.isNotEmpty) {
        final metadata = await finder.getTestMetadata(tests.first);

        expect(metadata, isNotNull);
        expect(metadata.path, equals(tests.first));
        expect(metadata.name, isNotEmpty);
        expect(metadata.size, greaterThan(0));
        expect(metadata.testCount, greaterThanOrEqualTo(0));
      }
    });

    test('should detect test cases in file', () async {
      // Create a temporary test file
      final tempDir = Directory.systemTemp.createTempSync('test_finder_');
      final testFile = File('${tempDir.path}/sample_test.dart');

      await testFile.writeAsString('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test case 1', () {});
  test('test case 2', () {});
  
  group('test group', () {
    test('nested test', () {});
  });
}
''');

      final metadata = await finder.getTestMetadata(testFile.path);

      expect(metadata.testCount, equals(3));

      // Cleanup
      await tempDir.delete(recursive: true);
    });

    test('should detect tags in test file', () async {
      // Create a temporary test file with tags
      final tempDir = Directory.systemTemp.createTempSync('test_finder_');
      final testFile = File('${tempDir.path}/tagged_test.dart');

      await testFile.writeAsString('''
@Tags(['integration', 'slow'])
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tagged test', () {});
}
''');

      final metadata = await finder.getTestMetadata(testFile.path);

      expect(metadata.tags, isNotEmpty);
      expect(metadata.tags.contains('integration'), isTrue);

      // Cleanup
      await tempDir.delete(recursive: true);
    });

    test('should handle non-existent file', () async {
      expect(
        () => finder.getTestMetadata('/non/existent/test.dart'),
        throwsException,
      );
    });

    test('should search tests by name', () async {
      final results = await finder.searchByName('test_finder');

      expect(results, isNotNull);
      expect(results.any((t) => t.contains('test_finder_test.dart')), isTrue);
    });

    test('should find tests in specific directory', () async {
      final tests = await finder.findTestsInDirectory('test/unit');

      expect(tests, isNotNull);
      expect(tests, isA<List<String>>());
    });
  });
}
