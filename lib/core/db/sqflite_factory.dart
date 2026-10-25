import 'sqflite_factory_platform.dart';

/// Installs the sqflite database factory that matches the current platform.
///
/// The `sqflite` package only registers a native database factory via its
/// platform plugins on Android/iOS. On Linux, macOS, Windows and the web the
/// global factory stays unset, which makes the top-level `openDatabase` and
/// `getDatabasesPath` APIs throw a [StateError] (an [Error], not an
/// [Exception]). Anything that only catches [Exception]/[StorageException]
/// then never clears its loading state and the UI spins forever.
///
/// Calling this at startup (before any database is opened) installs an
/// FFI-backed factory on desktop and web so local storage actually works. On
/// Android/iOS it is a no-op because the native plugin already registered one.
void initializeDatabaseFactory() => configureDatabaseFactory();
