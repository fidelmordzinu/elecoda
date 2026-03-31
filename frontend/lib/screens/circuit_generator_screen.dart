import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/circuit_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/circuit_model.dart';
import '../widgets/schematic_painter.dart';

class CircuitGeneratorScreen extends StatefulWidget {
  const CircuitGeneratorScreen({super.key});

  @override
  State<CircuitGeneratorScreen> createState() => _CircuitGeneratorScreenState();
}

class _CircuitGeneratorScreenState extends State<CircuitGeneratorScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circuit = context.watch<CircuitProvider>();
    final inventory = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Circuit Generator')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Describe the circuit you want to build...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: circuit.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Generate Circuit'),
                    onPressed: circuit.isLoading || _controller.text.isEmpty
                        ? null
                        : () {
                            final invMpnList = inventory.components
                                .map((c) => c.mpn)
                                .toList();
                            context.read<CircuitProvider>().generateCircuit(
                              query: _controller.text,
                              inventory: invMpnList,
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResult(circuit)),
        ],
      ),
    );
  }

  Widget _buildResult(CircuitProvider circuit) {
    if (circuit.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating circuit...'),
          ],
        ),
      );
    }

    if (circuit.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${circuit.error}'),
          ],
        ),
      );
    }

    if (circuit.response == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.electrical_services, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Enter a circuit description to get started'),
          ],
        ),
      );
    }

    final response = circuit.response!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Components (${response.components.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...response.components.map((c) => _buildComponentCard(c)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.draw),
            label: const Text('Draw Circuit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchematicViewScreen(response: response),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(CircuitComponent comp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getIconForType(comp.type),
          color: comp.inInventory ? Colors.green : Colors.blue,
        ),
        title: Text('${comp.ref} - ${comp.value}'),
        subtitle: Text(
          '${comp.type}${comp.mpn != null ? ' (${comp.mpn})' : ''}',
        ),
        trailing: comp.inInventory
            ? const Chip(
                label: Text('In Inventory'),
                backgroundColor: Colors.green,
              )
            : const Chip(
                label: Text('Missing'),
                backgroundColor: Colors.orange,
              ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'resistor':
        return Icons.show_chart;
      case 'capacitor':
        return Icons.battery_full;
      case 'inductor':
        return Icons.cable;
      case 'ic':
        return Icons.memory;
      case 'transistor':
        return Icons.electrical_services;
      case 'led':
        return Icons.lightbulb;
      case 'diode':
        return Icons.arrow_forward;
      default:
        return Icons.electrical_services;
    }
  }
}

class SchematicViewScreen extends StatelessWidget {
  final CircuitResponse response;

  const SchematicViewScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circuit Schematic')),
      body: CustomPaint(
        painter: SchematicPainter(
          components: response.components,
          connections: response.connections,
        ),
        size: Size.infinite,
      ),
    );
  }
}
