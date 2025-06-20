import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';

class RawDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Raw Data'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'NOTAMs'),
              Tab(text: 'Weather'),
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
                _buildWeatherTab(flight),
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
            Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'No NOTAMs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All systems operational',
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
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${notam.id} - ${notam.affectedSystem}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${notam.icao} | ${notam.validFrom.day}/${notam.validFrom.month} ${notam.validFrom.hour.toString().padLeft(2, '0')}:${notam.validFrom.minute.toString().padLeft(2, '0')} - ${notam.validTo.hour.toString().padLeft(2, '0')}:${notam.validTo.minute.toString().padLeft(2, '0')}',
            ),
            leading: Icon(
              notam.isCritical ? Icons.error : Icons.warning,
              color: notam.isCritical ? Color(0xFFEF4444) : Color(0xFFF59E0B),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw NOTAM:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notam.rawText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Decoded:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(notam.decodedText),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherTab(dynamic flight) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: flight.weather.length,
      itemBuilder: (context, index) {
        final weather = flight.weather[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${weather.icao} - ${weather.timestamp.day}/${weather.timestamp.month} ${weather.timestamp.hour.toString().padLeft(2, '0')}:${weather.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Wind ${weather.windDirection}° at ${weather.windSpeed}kt, ${weather.visibility}m visibility'),
            leading: Icon(Icons.cloud, color: Color(0xFF3B82F6)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw METAR:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        weather.rawText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Decoded:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(weather.decodedText),
                    SizedBox(height: 16),
                    _buildWeatherDetails(weather),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetails(dynamic weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildWeatherDetail('Temperature', '${weather.temperature}°C'),
            ),
            Expanded(
              child: _buildWeatherDetail('Dew Point', '${weather.dewPoint}°C'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildWeatherDetail('QNH', '${weather.qnh} hPa'),
            ),
            Expanded(
              child: _buildWeatherDetail('Cloud Cover', weather.cloudCover),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 