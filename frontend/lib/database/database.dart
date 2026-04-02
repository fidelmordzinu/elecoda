import 'package:drift/drift.dart';

class Components extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mpn => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get datasheetUrl => text().nullable()();
  TextColumn get specs => text().nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get backendId => integer().nullable()();
}
