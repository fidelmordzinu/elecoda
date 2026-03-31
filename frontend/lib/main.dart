import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'database/app_database.dart';
import 'services/api_service.dart';
import 'providers/search_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/circuit_provider.dart';
import 'screens/home_screen.dart';
import 'screens/circuit_generator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ElecodaApp());
}

class ElecodaApp extends StatelessWidget {
  const ElecodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase();
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SearchProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(database: database),
        ),
        ChangeNotifierProvider(
          create: (_) => CircuitProvider(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Elecoda',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [HomeScreen(), CircuitGeneratorScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'Circuits',
          ),
        ],
      ),
    );
  }
}
