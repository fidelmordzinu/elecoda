import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import '../models/component_model.dart';

class InventoryProvider extends ChangeNotifier {
  final AppDatabase database;
  List<Component> _components = [];
  bool _isLoading = false;

  List<Component> get components => _components;
  bool get isLoading => _isLoading;
  Set<String> get mpnSet => _components.map((c) => c.mpn).toSet();

  InventoryProvider({required this.database}) {
    loadComponents();
  }

  Future<void> loadComponents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _components = await database.getAllComponents();
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComponent(ComponentModel component) async {
    final exists = await database.componentExists(component.partNumber);
    if (exists) return false;

    await database.insertComponent(
      ComponentsCompanion(
        mpn: Value(component.partNumber),
        manufacturer: Value(component.manufacturer),
        description: Value(component.category),
        datasheetUrl: Value(null),
        specs: component.attributes != null
            ? Value(jsonEncode(component.attributes))
            : const Value(null),
        category: Value(component.category),
        quantity: const Value(1),
      ),
    );
    await loadComponents();
    return true;
  }

  Future<void> removeComponent(int id) async {
    await database.deleteComponent(id);
    await loadComponents();
  }

  Future<void> updateQuantity(int id, int quantity) async {
    await database.updateQuantity(id, quantity);
    await loadComponents();
  }

  bool isInInventory(String mpn) {
    return mpnSet.contains(mpn);
  }
}
