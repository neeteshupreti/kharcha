import 'sqflite_factory_native.dart'
    if (dart.library.html) 'sqflite_factory_web.dart';

/// Platform entry point selected at compile time via a conditional import.
void configureDatabaseFactory() => platformConfigureDatabaseFactory();
