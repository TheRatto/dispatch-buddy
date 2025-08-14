import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charts_provider.dart';
import '../services/naips_charts_service.dart';
import '../services/naips_service.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        centerTitle: true,
      ),
      body: ChangeNotifierProvider(
        create: (_) => ChartsProvider(
          chartsService: NaipsChartsService(naipsService: NAIPSService()),
        )..refreshCatalog(),
        child: Consumer<ChartsProvider>(
          builder: (context, provider, _) {
            if (provider.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.refreshCatalog(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            }
            if (provider.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.map, size: 48, color: Color(0xFF3B82F6)),
                    SizedBox(height: 12),
                    Text('Charts coming soon', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                final validText = item.validTillUtc != null
                    ? 'Valid ${item.validFromUtc.toUtc()} → ${item.validTillUtc!.toUtc()}'
                    : 'Permanent';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.image),
                    title: Text(item.name),
                    subtitle: Text(validText),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


