import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component_model.dart';
import '../providers/inventory_provider.dart';

class ComponentDetailScreen extends StatefulWidget {
  final ComponentModel component;

  const ComponentDetailScreen({super.key, required this.component});

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.component.partNumber)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Part Number', widget.component.partNumber),
            _buildInfoRow('Manufacturer', widget.component.manufacturer),
            if (widget.component.category != null)
              _buildInfoRow('Category', widget.component.category!),
            if (widget.component.attributes != null)
              _buildInfoRow(
                'Attributes',
                _formatAttributes(widget.component.attributes!),
              ),
            const SizedBox(height: 24),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Inventory'),
                      onPressed: _addToInventory,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAttributes(Map<String, dynamic> attrs) {
    return attrs.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(value),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _addToInventory() async {
    setState(() => _isLoading = true);
    final success = await context.read<InventoryProvider>().addComponent(
      widget.component,
    );
    if (mounted) {
      setState(() => _isLoading = false);
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
