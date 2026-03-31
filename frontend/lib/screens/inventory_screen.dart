import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../database/app_database.dart' show Component;

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Inventory')),
      body: inventory.isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventory.components.isEmpty
          ? const Center(child: Text('No components in inventory'))
          : ListView.builder(
              itemCount: inventory.components.length,
              itemBuilder: (context, index) {
                final comp = inventory.components[index];
                return _buildCard(context, comp);
              },
            ),
    );
  }

  Widget _buildCard(BuildContext context, Component comp) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.memory),
        title: Text(comp.mpn),
        subtitle: Text(
          [
            comp.description,
            comp.category,
          ].where((s) => s != null && s.isNotEmpty).join(' • '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('x${comp.quantity}'),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () =>
                  context.read<InventoryProvider>().removeComponent(comp.id),
            ),
          ],
        ),
      ),
    );
  }
}
