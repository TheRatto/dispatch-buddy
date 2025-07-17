import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../services/airport_system_analyzer.dart';
import '../widgets/zulu_time_widget.dart';

class SystemDetailScreen extends StatelessWidget {
  final String airportIcao;
  final String systemName;
  final String systemKey;
  final IconData systemIcon;

  const SystemDetailScreen({
    super.key,
    required this.airportIcao,
    required this.systemName,
    required this.systemKey,
    required this.systemIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
            const SizedBox(height: 2),
            Text(
              '$airportIcao - $systemName',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show system-specific help/info
            },
          ),
        ],
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final flight = flightProvider.currentFlight;
          
          if (flight == null) {
            return const Center(
              child: Text('No flight data available'),
            );
          }

          final airport = flight.airports.firstWhere(
            (a) => a.icao == airportIcao,
            orElse: () => Airport(
              icao: airportIcao,
              name: 'Unknown',
              city: 'Unknown',
              latitude: 0,
              longitude: 0,
              systems: {},
              runways: [],
              navaids: [],
            ),
          );

          final systemAnalyzer = AirportSystemAnalyzer();
          final systemNotams = systemAnalyzer.getSystemNotams(flight.notams, airportIcao);
          final notams = systemNotams[systemKey] ?? [];

          return Column(
            children: [
              // System Status Header
              _buildSystemStatusHeader(airport, systemKey, notams),
              
              // System Details
              Expanded(
                child: _buildSystemDetails(notams, systemName),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemStatusHeader(Airport airport, String systemKey, List<Notam> notams) {
    final status = airport.systems[systemKey] ?? SystemStatus.green;
    Color color;
    String statusText;
    
    switch (status) {
      case SystemStatus.green:
        color = const Color(0xFF10B981);
        statusText = 'Operational';
        break;
      case SystemStatus.yellow:
        color = const Color(0xFFF59E0B);
        statusText = 'Partial';
        break;
      case SystemStatus.red:
        color = const Color(0xFFEF4444);
        statusText = 'Affected';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(systemIcon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  systemName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${notams.length} NOTAMs',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemDetails(List<Notam> notams, String systemName) {
    if (notams.isEmpty) {
      return _buildEmptyState(systemName);
    }

    return Column(
      children: [
        // Key Operational Impacts
        _buildOperationalImpacts(notams),
        
        // NOTAM List
        Expanded(
          child: _buildNotamList(notams),
        ),
        
        // View All NOTAMs Button
        _buildViewAllNotamsButton(),
      ],
    );
  }

  Widget _buildEmptyState(String systemName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            systemIcon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No NOTAMs affecting $systemName',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All systems operational',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalImpacts(List<Notam> notams) {
    // TODO: Implement operational impact analysis
    // This will show human-readable summaries of key impacts
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Key Operational Impacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Detailed impact analysis coming soon...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotamList(List<Notam> notams) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notams.length,
      itemBuilder: (context, index) {
        final notam = notams[index];
        return _buildNotamCard(notam);
      },
    );
  }

  Widget _buildNotamCard(Notam notam) {
    final isCritical = notam.isCritical;
    final backgroundColor = isCritical ? Colors.red[50] : Colors.blue[50];
    final borderColor = isCritical ? Colors.red[200]! : Colors.blue[200]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCritical ? Icons.priority_high : Icons.info_outline,
                color: isCritical ? Colors.red : Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notam.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red[700] : Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
              if (isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CRITICAL',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notam.rawText,
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${notam.validFrom.toString().substring(0, 10)} - ${notam.validTo.toString().substring(0, 10)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllNotamsButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to raw data screen filtered by system
        },
        icon: const Icon(Icons.list),
        label: const Text('View All NOTAMs'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 