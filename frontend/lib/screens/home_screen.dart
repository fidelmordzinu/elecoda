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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search components...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          context.read<SearchProvider>().search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  context.read<SearchProvider>().search(value),
              onSubmitted: (value) =>
                  context.read<SearchProvider>().search(value),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

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
              onPressed: () =>
                  context.read<SearchProvider>().search(_controller.text),
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
        return _buildCard(context, component);
      },
    );
  }

  Widget _buildCard(BuildContext context, ComponentModel component) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.memory),
        title: Text(component.mpn),
        subtitle: Text(
          [
            component.description,
            component.category,
          ].where((s) => s != null && s.isNotEmpty).join(' • '),
        ),
        trailing: FutureBuilder<bool>(
          future: context.read<InventoryProvider>().isInInventory(
            component.mpn,
          ),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return const Icon(Icons.check_circle, color: Colors.green);
            }
            return IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addToInventory(context, component),
            );
          },
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
