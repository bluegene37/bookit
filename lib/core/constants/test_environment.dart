// Gene - Nov, 04, 2026: Conditional export detecting test environment across IO and Web
export 'test_environment_stub.dart'
    if (dart.library.io) 'test_environment_io.dart';
