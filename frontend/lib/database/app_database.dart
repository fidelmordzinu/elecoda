import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'database.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Components])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(components, components.backendId);
      }
    },
  );

  Future<List<Component>> getAllComponents() => select(components).get();

  Future<Component?> getComponentByMpn(String mpn) {
    return (select(
      components,
    )..where((t) => t.mpn.equals(mpn))).getSingleOrNull();
  }

  Future<int?> getBackendIdByMpn(String mpn) {
    return (select(components)..where((t) => t.mpn.equals(mpn)))
        .getSingleOrNull()
        .then((row) => row?.backendId);
  }

  Future<int> insertComponent(ComponentsCompanion entry) {
    return into(components).insert(entry);
  }

  Future<bool> deleteComponent(int id) {
    return (delete(
      components,
    )..where((t) => t.id.equals(id))).go().then((count) => count > 0);
  }

  Future<bool> componentExists(String mpn) {
    return (select(components)..where((t) => t.mpn.equals(mpn)))
        .getSingleOrNull()
        .then((row) => row != null);
  }

  Future<int> updateQuantity(int id, int quantity) {
    return (update(components)..where((t) => t.id.equals(id))).write(
      ComponentsCompanion(quantity: Value(quantity)),
    );
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'elecoda.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
