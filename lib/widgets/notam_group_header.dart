import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';

class NotamGroupHeader extends StatelessWidget {
  final NotamGroup group;
  final int notamCount;
  final int hiddenCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isActive;
  final VoidCallback? onHiddenTap;

  const NotamGroupHeader({
    super.key,
    required this.group,
    required this.notamCount,
    this.hiddenCount = 0,
    required this.isExpanded,
    required this.onToggle,
    this.isActive = false,
    this.onHiddenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildGroupIcon(),
        title: _buildGroupTitle(),
        subtitle: _buildGroupSubtitle(),
        trailing: _buildGroupTrailing(),
        onTap: onToggle,
      ),
    );
  }

  Widget _buildGroupIcon() {
    IconData iconData;
    Color iconColor;

    switch (group) {
      case NotamGroup.movementAreas:
        iconData = Icons.airplanemode_active;
        iconColor = Colors.blue;
        break;
      case NotamGroup.navigationAids:
        iconData = Icons.radar;
        iconColor = Colors.purple;
        break;
      case NotamGroup.departureApproachProcedures:
        iconData = Icons.flight_takeoff;
        iconColor = Colors.green;
        break;
      case NotamGroup.airportAtcAvailability:
        iconData = Icons.flight;
        iconColor = Colors.orange;
        break;
      case NotamGroup.lighting:
        iconData = Icons.lightbulb;
        iconColor = Colors.yellow.shade700;
        break;
      case NotamGroup.hazardsObstacles:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotamGroup.airspace:
        iconData = Icons.space_bar;
        iconColor = Colors.indigo;
        break;
      case NotamGroup.proceduralAdmin:
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.teal;
        break;
      case NotamGroup.other:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 16,
      ),
    );
  }

  Widget _buildGroupTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _getGroupTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupSubtitle() {
    return Row(
      children: [
        Text(
          '$notamCount NOTAM${notamCount == 1 ? '' : 's'}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        if (hiddenCount > 0) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onHiddenTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off,
                    color: Colors.orange,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$hiddenCount hidden',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_getGroupPriority()}',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey.shade600,
          size: 20,
        ),
      ],
    );
  }

  String _getGroupTitle() {
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