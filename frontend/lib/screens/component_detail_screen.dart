import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component_model.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';

class ComponentDetailScreen extends StatefulWidget {
  final ComponentModel component;

  const ComponentDetailScreen({super.key, required this.component});

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  bool _isLoading = false;
  bool _fetching = true;
  ComponentModel? _fullComponent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFullComponent();
  }

  Future<void> _fetchFullComponent() async {
    if (widget.component.id == null) {
      setState(() {
        _fullComponent = widget.component;
        _fetching = false;
      });
      return;
    }

    try {
      final apiService = context.read<ApiService>();
      final component = await apiService.getComponent(widget.component.id!);
      if (mounted) {
        setState(() {
          _fullComponent = component;
          _fetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullComponent = widget.component;
          _fetching = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final component = _fullComponent ?? widget.component;

    return Scaffold(
      appBar: AppBar(title: Text(component.partNumber)),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Part Number', component.partNumber),
                  _buildInfoRow('Manufacturer', component.manufacturer),
                  if (component.category != null)
                    _buildInfoRow('Category', component.category!),
                  if (component.attributes != null &&
                      component.attributes!.isNotEmpty)
                    ..._buildAttributeRows(component.attributes!),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Note: Could not load full details ($_error)',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add to Inventory'),
                              onPressed: _addToInventory,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildAttributeRows(Map<String, dynamic> attrs) {
    final skipKeys = {'description'};
    final displayOrder = [
      'resistance',
      'capacitance',
      'inductance',
      'voltage',
      'current',
      'power',
      'tolerance',
      'material',
      'color',
      'frequency',
      'pins',
      'form',
      'symbol',
      'footprint',
      'datasheet',
      'sim_library',
      'sim_name',
      'sim_device',
      'sim_pins',
    ];

    final orderedKeys = displayOrder.where(attrs.containsKey).toList();
    final remainingKeys = attrs.keys
        .where((k) => !orderedKeys.contains(k) && !skipKeys.contains(k))
        .toList();
    final allKeys = [...orderedKeys, ...remainingKeys];

    return allKeys.map((key) {
      final value = attrs[key];
      if (value == null || value.toString().isEmpty)
        return const SizedBox.shrink();

      final label = key.replaceAll('_', ' ').replaceAll('-', ' ');
      final displayValue = value.toString();

      return _buildInfoRow(label, displayValue);
    }).toList();
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
      _fullComponent ?? widget.component,
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
