import 'dart:ffi';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// Initializes the sqlite3 dynamic library for the FFI database factory.
///
/// `package:sqlite3` looks up the unversioned `libsqlite3.so` on Linux by
/// default, but most distros only ship the SONAME `libsqlite3.so.0`. Redirect
/// the lookup so the FFI factory can actually load sqlite3 on those machines.
///
/// This runs inside the `sqflite_common_ffi` background isolate (the `ffiInit`
/// callback is invoked when the isolate starts, before sqlite3 is loaded), so
/// the override takes effect exactly where it is needed. It must be a
/// top-level function because it is handed across the isolate boundary.
void _initSqlite3ForFfi() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      // Try the versioned SONAME first (what distros ship), then the
      // unversioned name (what some containers / dev setups provide).
      for (final name in ['libsqlite3.so.0', 'libsqlite3.so']) {
        try {
          return DynamicLibrary.open(name);
        } on ArgumentError {
          // Try the next candidate.
        }
      }
      // Re-attempt the default so any remaining error is surfaced verbatim.
      return DynamicLibrary.open('libsqlite3.so');
    });
  }
}

/// Installs the FFI factory on desktop platforms.
///
/// On Android/iOS the native `sqflite` plugin has already registered a factory,
/// so we leave it untouched (the FFI implementation needs the system sqlite3
/// library, which is not guaranteed on every mobile runtime).
void platformConfigureDatabaseFactory() {
  if (Platform.isAndroid || Platform.isIOS) {
    return;
  }
  // Linux / macOS / Windows: use the bundled sqlite3 via dart:ffi.
  databaseFactory = createDatabaseFactoryFfi(ffiInit: _initSqlite3ForFfi);
}
