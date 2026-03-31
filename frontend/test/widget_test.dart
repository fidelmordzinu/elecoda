import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/component_model.dart';
import 'package:frontend/models/circuit_model.dart';
import 'package:frontend/providers/search_provider.dart';
import 'package:frontend/providers/inventory_provider.dart';
import 'package:frontend/providers/circuit_provider.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/inventory_screen.dart';
import 'package:frontend/screens/circuit_generator_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/database/app_database.dart';

class MockApiService extends Mock implements ApiService {}

class MockDatabase extends Mock implements AppDatabase {}

class MockSearchProvider extends ChangeNotifier implements SearchProvider {
  @override
  List<ComponentModel> results = [];
  @override
  bool isLoading = false;
  @override
  String? error;
  @override
  final ApiService apiService;
  MockSearchProvider({required this.apiService});
  @override
  Future<void> search(String query) async {}
}

class MockInventoryProvider extends ChangeNotifier
    implements InventoryProvider {
  @override
  List<Component> components = [];
  @override
  bool isLoading = false;
  @override
  final AppDatabase database;
  MockInventoryProvider({required this.database});
  @override
  Future<void> loadComponents() async {}
  @override
  Future<bool> addComponent(ComponentModel component) async => true;
  @override
  Future<void> removeComponent(int id) async {}
  @override
  Future<void> updateQuantity(int id, int quantity) async {}
  @override
  Future<bool> isInInventory(String mpn) async => false;
}

class MockCircuitProvider extends ChangeNotifier implements CircuitProvider {
  @override
  CircuitResponse? response;
  @override
  bool isLoading = false;
  @override
  String? error;
  @override
  final ApiService apiService;
  MockCircuitProvider({required this.apiService});
  @override
  Future<void> generateCircuit({
    required String query,
    required List<String> inventory,
  }) async {}
  @override
  void reset() {}
}

Widget createHomeScreen() {
  final apiService = MockApiService();
  final database = MockDatabase();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SearchProvider>(
        create: (_) => MockSearchProvider(apiService: apiService),
      ),
      ChangeNotifierProvider<InventoryProvider>(
        create: (_) => MockInventoryProvider(database: database),
      ),
      ChangeNotifierProvider<CircuitProvider>(
        create: (_) => MockCircuitProvider(apiService: apiService),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

Widget createInventoryScreen() {
  final database = MockDatabase();
  return ChangeNotifierProvider<InventoryProvider>(
    create: (_) => MockInventoryProvider(database: database),
    child: const MaterialApp(home: InventoryScreen()),
  );
}

Widget createCircuitScreen() {
  final apiService = MockApiService();
  final database = MockDatabase();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CircuitProvider>(
        create: (_) => MockCircuitProvider(apiService: apiService),
      ),
      ChangeNotifierProvider<InventoryProvider>(
        create: (_) => MockInventoryProvider(database: database),
      ),
    ],
    child: const MaterialApp(home: CircuitGeneratorScreen()),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('displays inventory button in app bar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });
  });

  group('InventoryScreen', () {
    testWidgets('displays empty state', (tester) async {
      await tester.pumpWidget(createInventoryScreen());
      expect(find.text('No components in inventory'), findsOneWidget);
    });
  });

  group('CircuitGeneratorScreen', () {
    testWidgets('displays input field and generate button', (tester) async {
      await tester.pumpWidget(createCircuitScreen());
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Generate Circuit'), findsOneWidget);
    });
  });
}
