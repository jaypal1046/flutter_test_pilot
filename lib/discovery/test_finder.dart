import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

/// Discovers and filters test files
class TestFinder {
  final String rootDirectory;
  final List<String> defaultPatterns;

  TestFinder({String? rootDirectory, List<String>? defaultPatterns})
    : rootDirectory = rootDirectory ?? Directory.current.path,
      defaultPatterns =
          defaultPatterns ??
          ['integration_test/**/*_test.dart', 'test/**/*_test.dart'];

  /// Find all test files matching patterns
  Future<List<String>> findTests({
    List<String>? patterns,
    List<String>? tags,
    List<String>? exclude,
  }) async {
    final searchPatterns = patterns ?? defaultPatterns;
    final allTests = <String>{};

    for (final pattern in searchPatterns) {
      final glob = Glob(pattern);

      await for (final entity in glob.list(root: rootDirectory)) {
        if (entity is File) {
          allTests.add(entity.path);
        }
      }
    }

    // Filter by tags if provided
    List<String> filteredTests = allTests.toList();
    if (tags != null && tags.isNotEmpty) {
      filteredTests = await _filterByTags(filteredTests, tags);
    }

    // Exclude patterns
    if (exclude != null && exclude.isNotEmpty) {
      filteredTests = _filterByExclude(filteredTests, exclude);
    }

    return filteredTests..sort();
  }

  /// Find tests in a specific directory
  Future<List<String>> findTestsInDirectory(String directory) async {
    final dir = Directory(path.join(rootDirectory, directory));

    if (!await dir.exists()) {
      return [];
    }

    final tests = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('_test.dart')) {
        tests.add(entity.path);
      }
    }

    return tests..sort();
  }

  /// Filter tests by tags
  Future<List<String>> _filterByTags(
    List<String> testFiles,
    List<String> tags,
  ) async {
    final filtered = <String>[];

    for (final testFile in testFiles) {
      final testTags = await _extractTags(testFile);

      // Check if any required tag is present
      if (tags.any((tag) => testTags.contains(tag))) {
        filtered.add(testFile);
      }
    }

    return filtered;
  }

  /// Extract tags from test file
  Future<Set<String>> _extractTags(String testFile) async {
    final tags = <String>{};

    try {
      final file = File(testFile);
      final content = await file.readAsString();

      // Look for @Tags(['tag1', 'tag2'])
      final tagPattern = RegExp(r"@Tags\(\['([^']+)'(?:,\s*'([^']+)')*\]\)");
      final matches = tagPattern.allMatches(content);

      for (final match in matches) {
        for (var i = 1; i < match.groupCount + 1; i++) {
          final tag = match.group(i);
          if (tag != null && tag.isNotEmpty) {
            tags.add(tag);
          }
        }
      }

      // Also look for single line tags
      final singleTagPattern = RegExp(r"@Tags\(\['([^']+)'\]\)");
      final singleMatches = singleTagPattern.allMatches(content);

      for (final match in singleMatches) {
        final tag = match.group(1);
        if (tag != null) {
          tags.add(tag);
        }
      }
    } catch (e) {
      // Ignore errors reading file
    }

    return tags;
  }

  /// Filter tests by exclude patterns
  List<String> _filterByExclude(
    List<String> testFiles,
    List<String> excludePatterns,
  ) {
    return testFiles.where((testFile) {
      for (final pattern in excludePatterns) {
        if (testFile.contains(pattern)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Group tests by directory
  Map<String, List<String>> groupByDirectory(List<String> testFiles) {
    final groups = <String, List<String>>{};

    for (final testFile in testFiles) {
      final dir = path.dirname(testFile);
      groups.putIfAbsent(dir, () => []).add(testFile);
    }

    return groups;
  }

  /// Get test metadata
  Future<TestMetadata> getTestMetadata(String testFile) async {
    final file = File(testFile);

    if (!await file.exists()) {
      throw Exception('Test file not found: $testFile');
    }

    final content = await file.readAsString();
    final tags = await _extractTags(testFile);
    final testCount = _countTests(content);

    return TestMetadata(
      path: testFile,
      name: path.basenameWithoutExtension(testFile),
      tags: tags.toList(),
      testCount: testCount,
      size: await file.length(),
    );
  }

  /// Count number of tests in file
  int _countTests(String content) {
    // Count testWidgets, test, and group calls
    final testPattern = RegExp(r'\b(testWidgets|test)\s*\(');
    return testPattern.allMatches(content).length;
  }

  /// Find recently modified tests
  Future<List<String>> findRecentlyModified({
    Duration age = const Duration(days: 1),
  }) async {
    final allTests = await findTests();
    final recentTests = <String>[];
    final cutoffTime = DateTime.now().subtract(age);

    for (final testFile in allTests) {
      final file = File(testFile);
      final stat = await file.stat();

      if (stat.modified.isAfter(cutoffTime)) {
        recentTests.add(testFile);
      }
    }

    return recentTests..sort((a, b) {
      final statA = File(a).statSync();
      final statB = File(b).statSync();
      return statB.modified.compareTo(statA.modified);
    });
  }

  /// Search tests by name pattern
  Future<List<String>> searchByName(String pattern) async {
    final allTests = await findTests();
    final regex = RegExp(pattern, caseSensitive: false);

    return allTests.where((test) {
      final baseName = path.basename(test);
      return regex.hasMatch(baseName);
    }).toList();
  }

  /// Get all unique tags across all tests
  Future<Set<String>> getAllTags() async {
    final allTests = await findTests();
    final allTags = <String>{};

    for (final testFile in allTests) {
      final tags = await _extractTags(testFile);
      allTags.addAll(tags);
    }

    return allTags;
  }
}

/// Test file metadata
class TestMetadata {
  final String path;
  final String name;
  final List<String> tags;
  final int testCount;
  final int size;

  TestMetadata({
    required this.path,
    required this.name,
    required this.tags,
    required this.testCount,
    required this.size,
  });

  @override
  String toString() {
    return 'TestMetadata($name: $testCount tests, tags: ${tags.join(", ")})';
  }
}
