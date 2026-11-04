// Gene - Nov, 04, 2026: Checks Platform.environment on VM/IO platforms for flutter test runner
import 'dart:io';

bool isFlutterTestRunning() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}
