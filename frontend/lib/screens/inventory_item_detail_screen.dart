import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart' show Component;
import '../providers/inventory_provider.dart';

class InventoryItemDetailScreen extends StatelessWidget {
  final Component component;

  const InventoryItemDetailScreen({super.key, required this.component});

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

  Map<String, dynamic>? _parseSpecs(String? specsJson) {
    if (specsJson == null || specsJson.isEmpty) return null;
    try {
      String normalized = specsJson
          .trim()
          .replaceAll(r'\"', '"')
          .replaceAll('""', '"');
      return Map<String, dynamic>.from(jsonDecode(normalized) as Map);
    } catch (_) {
      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryIcon = _getCategoryIcon(component.category);
    final categoryColor = _getCategoryColor(component.category, colorScheme);
    final specs = _parseSpecs(component.specs);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                component.mpn,
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
                      _buildInfoRow('Part Number', component.mpn),
                      _buildInfoRow(
                        'Manufacturer',
                        component.manufacturer ?? 'N/A',
                      ),
                      if (component.category != null)
                        _buildInfoRow('Category', component.category!),
                    ],
                  ),
                  if (specs != null && specs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSpecificationsCard(context, specs),
                  ],
                  const SizedBox(height: 24),
                  _buildQuantitySection(context, colorScheme),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
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

  Widget _buildSpecificationsCard(
    BuildContext context,
    Map<String, dynamic> specs,
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

    final orderedKeys = displayOrder.where(specs.containsKey).toList();
    final remainingKeys = specs.keys
        .where((k) => !orderedKeys.contains(k) && !skipKeys.contains(k))
        .toList();
    final allKeys = [...orderedKeys, ...remainingKeys];

    final filteredSpecs = <String, dynamic>{};
    for (final key in allKeys) {
      final value = specs[key];
      if (value != null) {
        final strValue = value is String ? value : value.toString();
        if (strValue.isNotEmpty && strValue != 'null') {
          filteredSpecs[key] = value;
        }
      }
    }

    if (filteredSpecs.isEmpty) return const SizedBox.shrink();

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
            ...filteredSpecs.entries.map((entry) {
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
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: component.quantity > 1
                      ? () => context.read<InventoryProvider>().updateQuantity(
                          component.id,
                          component.quantity - 1,
                        )
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '${component.quantity}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: () => context
                      .read<InventoryProvider>()
                      .updateQuantity(component.id, component.quantity + 1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edit feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Component'),
        content: Text('Remove "${component.mpn}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<InventoryProvider>().removeComponent(component.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${component.mpn}'),
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
