import 'dart:convert';

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

  Color _getCategoryColor(String? category, ColorScheme colorScheme) {
    if (category == null) return colorScheme.primary;
    final cat = category.toLowerCase();
    if (cat.contains('resistor')) return Colors.orange;
    if (cat.contains('capacitor')) return Colors.blue;
    if (cat.contains('diode') || cat.contains('led')) return Colors.red;
    if (cat.contains('transistor')) return Colors.purple;
    if (cat.contains('ic') || cat.contains('integrated')) return Colors.teal;
    if (cat.contains('connector')) return Colors.green;
    if (cat.contains('inductor')) return Colors.amber;
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final component = _fullComponent ?? widget.component;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryIcon = _getCategoryIcon(component.category);
    final categoryColor = _getCategoryColor(component.category, colorScheme);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                component.partNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      categoryColor.withValues(alpha: 0.8),
                      categoryColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    categoryIcon,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_fetching)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(
                      context,
                      title: 'Basic Info',
                      icon: Icons.info_outline,
                      children: [
                        _buildInfoRow('Part Number', component.partNumber),
                        _buildInfoRow('Manufacturer', component.manufacturer),
                        if (component.category != null)
                          _buildInfoRow('Category', component.category!),
                      ],
                    ),
                    if (component.attributes != null &&
                        component.attributes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAttributesCard(context, component.attributes!),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Could not load full details',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildAddToInventoryButton(colorScheme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesCard(
    BuildContext context,
    Map<String, dynamic> attrs,
  ) {
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

    final filteredAttrs = <String, dynamic>{};
    for (final key in allKeys) {
      final value = attrs[key];
      if (value != null) {
        final strValue = value is String ? value : value.toString();
        if (strValue.isNotEmpty && strValue != 'null') {
          filteredAttrs[key] = value;
        }
      }
    }

    if (filteredAttrs.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Specifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ...filteredAttrs.entries.map((entry) {
              final label = _formatLabel(entry.key);
              final displayValue = _formatValue(entry.key, entry.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSpecValueWidget(entry.key, displayValue),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final formattedEntries = <String>[];
      for (final entry in value.entries) {
        final formattedValue = _formatValue(entry.key.toString(), entry.value);
        if (formattedValue.isNotEmpty) {
          formattedEntries.add(formattedValue);
        }
      }
      return formattedEntries.join('\n');
    }
    if (value is List) {
      if (value.isEmpty) return '';
      if (value.isNotEmpty && value.first is Map) {
        if (key == 'pads') {
          return _formatPadsTable(value.cast<dynamic>());
        }
        return value
            .map((item) {
              if (item is Map) {
                return item.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', ');
              }
              return item.toString();
            })
            .join('\n');
      }
      return value.join(', ');
    }
    String str;
    if (value is String) {
      str = _normalizeJsonString(value);
    } else {
      str = value.toString();
    }
    if (str == 'null' || str.isEmpty) return '';
    if (key == 'datasheet' &&
        (str.startsWith('http') || str.startsWith('www'))) {
      return str;
    }
    return str;
  }

  String _formatPadsTable(List pads) {
    if (pads.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('| Pad # | Pin Name | Electrical Type |');
    buffer.writeln('|-------|----------|-----------------|');
    for (final pad in pads) {
      if (pad is Map) {
        final ref = pad['reference']?.toString() ?? '';
        final pinName = pad['pin_name']?.toString() ?? '';
        final elecType = pad['electrical_type']?.toString() ?? '';
        buffer.writeln('| $ref | **$pinName** | $elecType |');
      }
    }
    return buffer.toString();
  }

  String _normalizeJsonString(String str) {
    str = str.trim();
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        String normalized = str.replaceAll(r'\"', '"').replaceAll('""', '"');
        if (normalized.startsWith('{') && normalized.endsWith('}')) {
          final parsed = jsonDecode(normalized);
          if (parsed is Map && parsed.isNotEmpty) {
            return parsed.entries
                .map(
                  (e) =>
                      '${_formatLabel(e.key.toString())}: ${_formatValue(e.key.toString(), e.value)}',
                )
                .join('\n');
          }
        }
      } catch (_) {}
    }
    if (str.startsWith('[') && str.endsWith(']')) {
      try {
        String normalized = str.replaceAll(r'\"', '"').replaceAll('""', '"');
        if (normalized.startsWith('[') && normalized.endsWith(']')) {
          final parsed = jsonDecode(normalized);
          if (parsed is List && parsed.isNotEmpty) {
            if (parsed.first is Map) {
              return parsed
                  .map((item) {
                    if (item is Map) {
                      return item.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', ');
                    }
                    return item.toString();
                  })
                  .join('\n');
            }
            return parsed.join(', ');
          }
        }
      } catch (_) {}
    }
    return str;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecValueWidget(String key, String displayValue) {
    if (displayValue.isEmpty) return const SizedBox.shrink();

    if (key == 'datasheet' &&
        (displayValue.startsWith('http') || displayValue.startsWith('www'))) {
      return SelectableText.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Link: '),
            TextSpan(
              text: displayValue,
              style: TextStyle(
                color: Colors.blue.shade700,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 14),
      );
    }

    if (displayValue.contains('| Pad # |')) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SelectableText(
          displayValue,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }

    return Text(displayValue, style: const TextStyle(fontSize: 14));
  }

  Widget _buildAddToInventoryButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_shopping_cart),
        label: Text(_isLoading ? 'Adding...' : 'Add to Inventory'),
        onPressed: _isLoading ? null : _addToInventory,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
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
