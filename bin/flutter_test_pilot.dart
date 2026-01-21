#!/usr/bin/env dart

import 'dart:io';
import 'package:flutter_test_pilot/flutter_test_pilot.dart';

Future<void> main(List<String> arguments) async {
  try {
    final runner = TestPilotCommandRunner();
    await runner.run(arguments);
    exit(0);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
