import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Installs the WASM/IndexedDB-backed factory on the web.
void platformConfigureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
