import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart' as p;

Future<Database> getDatabase(String dbName) async {
  if (kIsWeb) {
    return databaseFactoryWeb.openDatabase(dbName);
  }

  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDocumentsDir.path, "Brass", '$dbName.db');
  await Directory(p.dirname(dbPath)).create(recursive: true);
  return databaseFactoryIo.openDatabase(dbPath);
}
