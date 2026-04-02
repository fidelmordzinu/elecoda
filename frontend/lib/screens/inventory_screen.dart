import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../database/app_database.dart' show Component;
import 'inventory_item_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

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
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventory = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          if (inventory.components.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${inventory.components.length} items',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: inventory.isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : inventory.components.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No components in inventory',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add components from search',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: inventory.components.length,
              itemBuilder: (context, index) {
                final comp = inventory.components[index];
                return _buildCard(context, comp, colorScheme);
              },
            ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Component comp,
    ColorScheme colorScheme,
  ) {
    final categoryColor = _getCategoryColor(comp.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InventoryItemDetailScreen(component: comp),
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
                    _getCategoryIcon(comp.category),
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
                        comp.mpn,
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
                          comp.description,
                          comp.category,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (comp.quantity > 1) {
                            context.read<InventoryProvider>().updateQuantity(
                              comp.id,
                              comp.quantity - 1,
                            );
                          }
                        },
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${comp.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.read<InventoryProvider>().updateQuantity(
                            comp.id,
                            comp.quantity + 1,
                          );
                        },
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => _showDeleteDialog(context, comp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Component comp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Component'),
        content: Text('Remove "${comp.mpn}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<InventoryProvider>().removeComponent(comp.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${comp.mpn}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
