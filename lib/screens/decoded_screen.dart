import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/weather.dart';
import '../models/notam.dart';
import '../widgets/zulu_time_widget.dart';

class DecodedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Decoded Info'),
          actions: const [
            ZuluTimeWidget(),
            SizedBox(width: 8),
          ],
          bottom: TabBar(
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
        body: Consumer<FlightProvider>(
          builder: (context, flightProvider, child) {
            final flight = flightProvider.currentFlight;
            
            if (flight == null) {
              return Center(
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
            SizedBox(height: 16),
            Text(
              'No NOTAMs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No current notices to airmen',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: flight.notams.length,
      itemBuilder: (context, index) {
        final notam = flight.notams[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NOTAM ${notam.id}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoRow('Subject', notam.subject),
                _buildInfoRow('Condition', notam.condition),
                _buildInfoRow('Effective From', _formatDateTime(notam.effectiveFrom)),
                _buildInfoRow('Effective To', _formatDateTime(notam.effectiveTo)),
                if (notam.rawText.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(notam.rawText),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetarsTab(dynamic flight) {
    if (flight.metars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No METARs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No current weather observations',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: flight.metars.length,
      itemBuilder: (context, index) {
        final metar = flight.metars[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'METAR ${metar.icao}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(metar.timestamp),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 12),
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
                      conditionsData = metar.decodedWeather!.conditionsDescription != 'No significant weather' 
                          ? metar.decodedWeather!.conditionsDescription 
                          : 'N/A';
                    } else {
                      windData = '${metar.windDirection}° at ${metar.windSpeed}kt';
                      visibilityData = '${metar.visibility}m';
                      cloudData = metar.cloudCover;
                      conditionsData = metar.conditions.isNotEmpty ? metar.conditions : 'N/A';
                    }
                    
                    return Column(
                      children: [
                        _buildDecodedInfo('Wind', windData),
                        _buildDecodedInfo('Visibility', visibilityData),
                        _buildDecodedInfo('Clouds', cloudData),
                        _buildDecodedInfo('Conditions', conditionsData),
                        // Additional fields for METARs
                        if (metar.decodedWeather != null) ...[
                          _buildDecodedInfo('Temperature', metar.decodedWeather!.temperatureDescription),
                          _buildDecodedInfo('Pressure', metar.decodedWeather!.pressureDescription),
                          if (metar.decodedWeather!.rvrDescription.isNotEmpty)
                            _buildDecodedInfo('RVR', metar.decodedWeather!.rvrDescription),
                        ] else ...[
                          _buildInfoRow('Temperature', '${metar.temperature}°C'),
                          _buildInfoRow('Dew Point', '${metar.dewPoint}°C'),
                          _buildInfoRow('QNH', '${metar.qnh}hPa'),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: 12),
                Text(
                  'Raw: ${metar.rawText}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTafsTab(dynamic flight) {
    if (flight.tafs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No terminal aerodrome forecasts',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: flight.tafs.length,
      itemBuilder: (context, index) {
        final taf = flight.tafs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TAF ${taf.icao}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateTime(taf.timestamp),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 12),
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
                        _buildDecodedInfo('Wind', windData),
                        _buildDecodedInfo('Visibility', visibilityData),
                        _buildDecodedInfo('Clouds', cloudData),
                        _buildDecodedInfo('Conditions', conditionsData),
                      ],
                    );
                  },
                ),
                SizedBox(height: 12),
                Text(
                  'Raw: ${taf.rawText}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'N/A' : value),
          ),
        ],
      ),
    );
  }

  Widget _buildDecodedInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }
} 