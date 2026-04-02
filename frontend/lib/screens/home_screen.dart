import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/component_model.dart';
import 'component_detail_screen.dart';
import 'inventory_screen.dart';
import 'inventory_item_detail_screen.dart';

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

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.memory;
    final cat = category.toLowerCase();
    if (cat.contains('resistor')) return Icons.electrical_services;
    if (cat.contains('capacitor')) return Icons.memory;
    if (cat.contains('diode') || cat.contains('led')) {
      return Icons.lightbulb_outline;
    }
    if (cat.contains('transistor')) {
      return Icons.settings_input_component;
    }
    if (cat.contains('ic') || cat.contains('integrated')) {
      return Icons.developer_board;
    }
    if (cat.contains('connector')) {
      return Icons.cable;
    }
    if (cat.contains('inductor')) {
      return Icons.transform;
    }
    if (cat.contains('regulator')) {
      return Icons.speed;
    }
    if (cat.contains('switch')) {
      return Icons.toggle_on;
    }
    if (cat.contains('oscillator')) {
      return Icons.graphic_eq;
    }
    if (cat.contains('rf')) {
      return Icons.wifi;
    }
    if (cat.contains('protection') || cat.contains('fuse')) {
      return Icons.security;
    }
    return Icons.memory;
  }

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.blueGrey;
    final cat = category.toLowerCase();
    if (cat.contains('resistor')) return Colors.orange;
    if (cat.contains('capacitor')) return Colors.blue;
    if (cat.contains('diode') || cat.contains('led')) return Colors.red;
    if (cat.contains('transistor')) return Colors.purple;
    if (cat.contains('ic') || cat.contains('integrated')) return Colors.teal;
    if (cat.contains('connector')) return Colors.green;
    if (cat.contains('inductor')) return Colors.amber;
    if (cat.contains('regulator')) return Colors.indigo;
    if (cat.contains('switch')) return Colors.cyan;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Elecoda'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
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
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
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
                      const SizedBox(height: 12),
                      _buildCategoryFilter(colorScheme),
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
                        leading: Icon(
                          _getCategoryIcon(suggestion['category']),
                          size: 20,
                          color: _getCategoryColor(suggestion['category']),
                        ),
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

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
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
              avatar: isSelected
                  ? null
                  : Icon(
                      _getCategoryIcon(cat['name']),
                      size: 16,
                      color: _getCategoryColor(cat['name']),
                    ),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching components...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (searchProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchProvider.error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<SearchProvider>().search(
                _controller.text,
                category: _selectedCategory,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchProvider.results.isEmpty && _controller.text.isEmpty) {
      return _buildInventorySection(context, inventoryProvider);
    }

    if (searchProvider.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
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
    final categoryColor = _getCategoryColor(component.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComponentDetailScreen(component: component),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(component.category),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        component.partNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          component.manufacturer,
                          component.category,
                        ].where((s) => s != null && s.isNotEmpty).join(' • '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isInInventory)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'In Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _addToInventory(context, component),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySection(
    BuildContext context,
    InventoryProvider inventoryProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final components = inventoryProvider.components;

    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for electronic components',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find resistors, capacitors, ICs and more',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.inventory_2, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'My Inventory (${components.length} items)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: components.length,
            itemBuilder: (context, index) {
              final comp = components[index];
              return _buildInventoryCard(context, comp, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    dynamic comp,
    ColorScheme colorScheme,
  ) {
    final categoryColor = _getCategoryColor(comp.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(comp.category),
              color: categoryColor,
              size: 20,
            ),
          ),
          title: Text(
            comp.mpn,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(comp.category ?? ''),
          trailing: Text(
            'x${comp.quantity}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InventoryItemDetailScreen(component: comp),
              ),
            );
          },
        ),
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
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Added to inventory!' : 'Already in inventory!'),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
