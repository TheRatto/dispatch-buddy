import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';

class NotamGroupHeader extends StatelessWidget {
  final NotamGroup group;
  final int notamCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isActive;

  const NotamGroupHeader({
    super.key,
    required this.group,
    required this.notamCount,
    required this.isExpanded,
    required this.onToggle,
    this.isActive = false,
  });

  String get _groupTitle {
    switch (group) {
      case NotamGroup.movementAreas:
        return 'Movement Areas';
      case NotamGroup.navigationAids:
        return 'Navigation Aids';
      case NotamGroup.departureApproachProcedures:
        return 'Departure/Approach Procedures';
      case NotamGroup.airportAtcAvailability:
        return 'Airport & ATC Availability';
      case NotamGroup.lighting:
        return 'Lighting';
      case NotamGroup.hazardsObstacles:
        return 'Hazards & Obstacles';
      case NotamGroup.airspace:
        return 'Airspace';
      case NotamGroup.proceduralAdmin:
        return 'Procedural & Admin';
      case NotamGroup.other:
        return 'Other';
    }
  }

  IconData get _groupIcon {
    switch (group) {
      case NotamGroup.movementAreas:
        return Icons.airplanemode_active;
      case NotamGroup.navigationAids:
        return Icons.radar;
      case NotamGroup.departureApproachProcedures:
        return Icons.flight_takeoff;
      case NotamGroup.airportAtcAvailability:
        return Icons.flight;
      case NotamGroup.lighting:
        return Icons.lightbulb;
      case NotamGroup.hazardsObstacles:
        return Icons.warning;
      case NotamGroup.airspace:
        return Icons.space_bar;
      case NotamGroup.proceduralAdmin:
        return Icons.admin_panel_settings;
      case NotamGroup.other:
        return Icons.info;
    }
  }

  Color get _groupColor {
    switch (group) {
      case NotamGroup.movementAreas:
        return Colors.blue;
      case NotamGroup.navigationAids:
        return Colors.purple;
      case NotamGroup.departureApproachProcedures:
        return Colors.green;
      case NotamGroup.airportAtcAvailability:
        return Colors.orange;
      case NotamGroup.lighting:
        return Colors.yellow.shade700;
      case NotamGroup.hazardsObstacles:
        return Colors.red;
      case NotamGroup.airspace:
        return Colors.indigo;
      case NotamGroup.proceduralAdmin:
        return Colors.teal;
      case NotamGroup.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? _groupColor.withOpacity(0.1) : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _groupColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _groupIcon,
            color: _groupColor,
            size: 20,
          ),
        ),
        title: Text(
          _groupTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? _groupColor : Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          '$notamCount NOTAM${notamCount == 1 ? '' : 's'}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _groupColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_getGroupPriority()}',
                style: TextStyle(
                  color: _groupColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade600,
            ),
          ],
        ),
        onTap: onToggle,
      ),
    );
  }

  int _getGroupPriority() {
    switch (group) {
      case NotamGroup.movementAreas:
        return 1;
      case NotamGroup.navigationAids:
        return 2;
      case NotamGroup.departureApproachProcedures:
        return 3;
      case NotamGroup.airportAtcAvailability:
        return 4;
      case NotamGroup.lighting:
        return 5;
      case NotamGroup.hazardsObstacles:
        return 6;
      case NotamGroup.airspace:
        return 7;
      case NotamGroup.proceduralAdmin:
        return 8;
      case NotamGroup.other:
        return 9;
    }
  }
} 