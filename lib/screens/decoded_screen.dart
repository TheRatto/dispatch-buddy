import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/global_drawer.dart';
import '../widgets/zulu_time_widget.dart';

class DecodedScreen extends StatelessWidget {
  const DecodedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
              SizedBox(height: 2),
              Text(
                'Decoded',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  debugPrint('DEBUG: Hamburger menu pressed - opening end drawer');
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ],
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            indicatorColor: Color(0xFFF97316), // Accent Orange
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'NOTAMs'),
              Tab(text: 'METARs'),
              Tab(text: 'TAFs'),
            ],
          ),
        ),
        endDrawer: const GlobalDrawer(currentScreen: '/decoded'),
        body: Consumer<FlightProvider>(
          builder: (context, flightProvider, child) {
            final flight = flightProvider.currentFlight;
            
            if (flight == null) {
              return const Center(
                child: Text('No flight data available'),
              );
            }

            return TabBarView(
              children: [
                _buildNotamsTab(flight),
                _buildMetarsTab(flight),
                _buildTafsTab(flight),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotamsTab(dynamic flight) {
    if (flight.notams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No NOTAMs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No current notices to airmen',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
            await flightProvider.refreshCurrentData(
              naipsEnabled: settingsProvider.naipsEnabled,
              naipsUsername: settingsProvider.naipsUsername,
              naipsPassword: settingsProvider.naipsPassword,
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flight.notams.length,
            itemBuilder: (context, index) {
              final notam = flight.notams[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    '${notam.id} - ${notam.affectedSystem}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${notam.icao} | ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}',
                      ),

                    ],
                  ),
                  leading: Icon(
                    notam.isCritical ? Icons.error : Icons.warning,
                    color: notam.isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic NOTAM Information
                          Text(
                            'NOTAM Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('NOTAM ID', notam.id),
                          _buildInfoRow('ICAO', notam.icao),
                          _buildInfoRow('Type', notam.type.toString().split('.').last),
                          if (notam.qCode != null) _buildInfoRow('Q Code', notam.qCode!),
                          _buildInfoRow('Affected System', notam.affectedSystem),
                          _buildInfoRow('Critical', notam.isCritical ? 'Yes' : 'No'),
                          _buildInfoRow('Effective From', _formatDateTime(notam.validFrom)),
                          _buildInfoRow('Effective To', _formatDateTime(notam.validTo)),
                          
                          const SizedBox(height: 20),
                          
                          // Raw NOTAM Data
                          Text(
                            'Raw NOTAM Data:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRawInfoRow('NOTAM ID', notam.id),
                                _buildRawInfoRow('ICAO', notam.icao),
                                _buildRawInfoRow('Type', notam.type.toString().split('.').last),
                                if (notam.qCode != null) _buildRawInfoRow('Q Code', notam.qCode!),
                                _buildRawInfoRow('Affected System', notam.affectedSystem),
                                _buildRawInfoRow('Critical', notam.isCritical ? 'Yes' : 'No'),
                                _buildRawInfoRow('Valid From', notam.validFrom.toIso8601String()),
                                _buildRawInfoRow('Valid To', notam.validTo.toIso8601String()),
                                const SizedBox(height: 12),
                                Text(
                                  'Raw Text:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  notam.displayRawText,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.3,
                                    color: Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Decoded Text (if available)
                          if (notam.decodedText.isNotEmpty) ...[
                            Text(
                              'Decoded Summary:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                notam.displayDecodedText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Decoded Summary:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                'No decoded summary available yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Additional Debug Information
                          Text(
                            'Debug Information:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Raw Text Length: ${notam.rawText.length} characters',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                                Text(
                                  'Contains "RWY": ${notam.rawText.toLowerCase().contains('rwy')}',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                                Text(
                                  'Contains "NAVAID": ${notam.rawText.toLowerCase().contains('navaid')}',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                                Text(
                                  'Contains "AIRSPACE": ${notam.rawText.toLowerCase().contains('airspace')}',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                                Text(
                                  'First 100 chars: "${notam.rawText.length > 100 ? notam.rawText.substring(0, 100) + '...' : notam.rawText}"',
                                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetarsTab(dynamic flight) {
    if (flight.weather.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No METARs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No current weather observations',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final metars = flight.weather.where((w) => w.type == 'METAR').toList();
    
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
            await flightProvider.refreshCurrentData(
              naipsEnabled: settingsProvider.naipsEnabled,
              naipsUsername: settingsProvider.naipsUsername,
              naipsPassword: settingsProvider.naipsPassword,
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metars.length,
            itemBuilder: (context, index) {
              final metar = metars[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _buildMetarHeaderText(metar),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Text(
                            _formatDateTime(metar.timestamp),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Always show the four main headings regardless of data availability
                      Builder(
                        builder: (context) {
                          String windData = 'N/A';
                          String visibilityData = 'N/A';
                          String cloudData = 'N/A';
                          String conditionsData = 'N/A';
                          
                          if (metar.decodedWeather != null) {
                            windData = metar.decodedWeather!.windDescription;
                            visibilityData = metar.decodedWeather!.visibilityDescription;
                            cloudData = metar.decodedWeather!.cloudDescription;
                            conditionsData = metar.decodedWeather!.conditionsDescription;
                          } else {
                            windData = '${metar.windDirection}° at ${metar.windSpeed}kt';
                            visibilityData = '${metar.visibility}m';
                            cloudData = metar.cloudCover;
                            conditionsData = metar.conditions.isNotEmpty ? metar.conditions : 'N/A';
                          }
                          
                          return Column(
                            children: [
                              _buildInfoRow('Wind', windData),
                              _buildInfoRow('Visibility', visibilityData),
                              _buildInfoRow('Cloud', cloudData),
                              _buildInfoRow('Conditions', conditionsData),
                              if (metar.decodedWeather?.remarks != null && metar.decodedWeather!.remarks!.isNotEmpty)
                                _buildInfoRow('Remarks', metar.decodedWeather!.remarks!),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Raw METAR:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          metar.rawText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTafsTab(dynamic flight) {
    if (flight.weather.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No terminal aerodrome forecasts',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final tafs = flight.weather.where((w) => w.type == 'TAF').toList();
    
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
            await flightProvider.refreshCurrentData(
              naipsEnabled: settingsProvider.naipsEnabled,
              naipsUsername: settingsProvider.naipsUsername,
              naipsPassword: settingsProvider.naipsPassword,
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tafs.length,
            itemBuilder: (context, index) {
              final taf = tafs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TAF ${taf.icao}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          Text(
                            _formatDateTime(taf.timestamp),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Always show the four main headings regardless of data availability
                      Builder(
                        builder: (context) {
                          String windData = 'N/A';
                          String visibilityData = 'N/A';
                          String cloudData = 'N/A';
                          String conditionsData = 'N/A';
                          
                          if (taf.decodedWeather != null) {
                            if (taf.decodedWeather!.forecastPeriods != null && taf.decodedWeather!.forecastPeriods!.isNotEmpty) {
                              final initialPeriod = taf.decodedWeather!.forecastPeriods!.firstWhere(
                                (p) => p.type == 'INITIAL',
                                orElse: () => taf.decodedWeather!.forecastPeriods!.first,
                              );
                              
                              final weather = initialPeriod.weather;
                              windData = weather['Wind'] ?? 'N/A';
                              visibilityData = weather['Visibility'] ?? 'N/A';
                              cloudData = weather['Cloud'] ?? 'N/A';
                              conditionsData = weather['Weather'] ?? 'N/A';
                            } else {
                              windData = taf.decodedWeather!.windDescription;
                              visibilityData = taf.decodedWeather!.visibilityDescription;
                              cloudData = taf.decodedWeather!.cloudDescription;
                              conditionsData = taf.decodedWeather!.conditionsDescription;
                            }
                          } else {
                            windData = '${taf.windDirection}° at ${taf.windSpeed}kt';
                            visibilityData = '${taf.visibility}m';
                            cloudData = taf.cloudCover;
                            conditionsData = taf.conditions.isNotEmpty ? taf.conditions : 'N/A';
                          }
                          
                          return Column(
                            children: [
                              _buildInfoRow('Wind', windData),
                              _buildInfoRow('Visibility', visibilityData),
                              _buildInfoRow('Cloud', cloudData),
                              _buildInfoRow('Conditions', conditionsData),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Raw TAF:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          taf.rawText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'N/A' : value),
          ),
        ],
      ),
    );
  }

  Widget _buildRawInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[900],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }

  String _buildMetarHeaderText(dynamic metar) {
    return 'METAR ${metar.icao} - ${_formatDateTime(metar.timestamp)}';
  }
} 