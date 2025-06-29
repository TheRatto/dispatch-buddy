import 'package:flutter/material.dart';

/// TAF Airport Selector Widget
/// 
/// Displays horizontal scrollable airport bubbles for TAF selection:
/// - Airport ICAO code bubbles
/// - Selected state highlighting
/// - Cache clearing on airport change
/// - Exact styling preserved from original implementation
class TafAirportSelector extends StatelessWidget {
  final List<String> airports;
  final String? selectedAirport;
  final Function(String) onAirportSelected;
  final VoidCallback? onCacheClear;

  const TafAirportSelector({
    Key? key,
    required this.airports,
    required this.selectedAirport,
    required this.onAirportSelected,
    this.onCacheClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: airports.map((icao) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _buildAirportBubble(
            icao,
            selectedAirport == icao,
            () {
              if (selectedAirport != icao) {
                onCacheClear?.call(); // Clear cache when switching airports
              }
              onAirportSelected(icao);
            },
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAirportBubble(String icao, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF97316) : Colors.grey[700]!,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFFF97316) : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          icao,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
} 