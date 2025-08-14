import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/charts_provider.dart';
import '../services/naips_charts_service.dart';
import '../services/naips_service.dart';
import '../providers/settings_provider.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        centerTitle: true,
      ),
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()..initialize()),
          ChangeNotifierProvider(
            create: (_) => ChartsProvider(
              chartsService: NaipsChartsService(naipsService: NAIPSService()),
            )..refreshCatalog(),
          ),
        ],
        child: Consumer2<SettingsProvider, ChartsProvider>(
          builder: (context, settings, provider, _) {
            final credsMissing = !(settings.naipsEnabled && (settings.naipsUsername?.isNotEmpty == true) && (settings.naipsPassword?.isNotEmpty == true));

            return Column(
              children: [
                if (credsMissing)
                  Container(
                    width: double.infinity,
                    color: Colors.amber[100],
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('NAIPS credentials not set. Charts require login. Update in Settings.')),
                      ],
                    ),
                  ),
                Expanded(
                  child: provider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.error != null
                          ? Center(
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
                            )
                          : provider.items.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.map, size: 48, color: Color(0xFF3B82F6)),
                                      SizedBox(height: 12),
                                      Text('Charts coming soon', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: provider.items.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = provider.items[index];
                                    final validText = item.validTillUtc != null
                                        ? 'Valid ${_fmt(item.validFromUtc)} → ${_fmt(item.validTillUtc!)}'
                                        : 'Permanent';
                                    final rem = item.timeRemaining;
                                    final countdown = rem == null
                                        ? ''
                                        : rem.inSeconds <= 0
                                            ? 'Expired'
                                            : '${rem.inHours.toString().padLeft(2, '0')}:${(rem.inMinutes % 60).toString().padLeft(2, '0')} remaining';

                                    return Card(
                                      child: ListTile(
                                        leading: const Icon(Icons.image),
                                        title: Text(item.name),
                                        subtitle: Text('$validText${countdown.isNotEmpty ? ' · $countdown' : ''}'),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () {},
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    return '$dd $hh:00 Z';
  }
}


