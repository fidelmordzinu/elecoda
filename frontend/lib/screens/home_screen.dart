import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/component_model.dart';
import 'component_detail_screen.dart';
import 'inventory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  String? _selectedCategory;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<SearchProvider>().search(value, category: _selectedCategory);
    context.read<SearchProvider>().fetchSuggestions(value);
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    _controller.text = suggestion['part_number'] ?? '';
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() => _showSuggestions = false);
    context.read<SearchProvider>().search(
      _controller.text,
      category: _selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elecoda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Search components...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _showSuggestions = false);
                                    context.read<SearchProvider>().search('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (value) {
                          setState(() => _showSuggestions = false);
                          context.read<SearchProvider>().search(
                            value,
                            category: _selectedCategory,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCategoryFilter(),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildBody(context)),
            ],
          ),
          if (_showSuggestions)
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(16, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    minWidth: 300,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.memory, size: 20),
                        title: Text(suggestion['part_number'] ?? ''),
                        subtitle: Text(suggestion['manufacturer'] ?? ''),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'name': null, 'label': 'All'},
      {'name': 'Resistor', 'label': 'Resistors'},
      {'name': 'Capacitor', 'label': 'Capacitors'},
      {'name': 'Diode', 'label': 'Diodes'},
      {'name': 'Integrated Circuit', 'label': 'ICs'},
      {'name': 'Connector', 'label': 'Connectors'},
      {'name': 'Inductor', 'label': 'Inductors'},
      {'name': 'Transistor', 'label': 'Transistors'},
      {'name': 'Circuit Protection', 'label': 'Protection'},
      {'name': 'Regulator', 'label': 'Regulators'},
      {'name': 'Oscillator', 'label': 'Oscillators'},
      {'name': 'Optoelectronics', 'label': 'Opto'},
      {'name': 'RF Module', 'label': 'RF'},
      {'name': 'Switch', 'label': 'Switches'},
      {'name': 'Power', 'label': 'Power'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat['label'] as String),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat['name'];
                });
                if (_controller.text.isNotEmpty) {
                  context.read<SearchProvider>().search(
                    _controller.text,
                    category: _selectedCategory,
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();
    final inventoryMpnSet = inventoryProvider.mpnSet;

    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${searchProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<SearchProvider>().search(
                _controller.text,
                category: _selectedCategory,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchProvider.results.isEmpty && _controller.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for electronic components'),
          ],
        ),
      );
    }

    if (searchProvider.results.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      itemCount: searchProvider.results.length,
      itemBuilder: (context, index) {
        final component = searchProvider.results[index];
        return _buildCard(context, component, inventoryMpnSet);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ComponentModel component,
    Set<String> inventoryMpnSet,
  ) {
    final isInInventory = inventoryMpnSet.contains(component.partNumber);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.memory),
        title: Text(component.partNumber),
        subtitle: Text(
          [
            component.manufacturer,
            component.category,
          ].where((s) => s != null && s.isNotEmpty).join(' \u2022 '),
        ),
        trailing: isInInventory
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addToInventory(context, component),
              ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComponentDetailScreen(component: component),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToInventory(
    BuildContext context,
    ComponentModel component,
  ) async {
    final success = await context.read<InventoryProvider>().addComponent(
      component,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to inventory!' : 'Already in inventory!',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
