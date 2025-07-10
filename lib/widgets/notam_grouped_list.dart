import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';
import 'package:dispatch_buddy/widgets/notam_group_header.dart';
import 'package:dispatch_buddy/widgets/notam_group_content.dart';

class NotamGroupedList extends StatefulWidget {
  final List<Notam> notams;
  final Function(Notam)? onNotamTap;
  final bool showGroupHeaders;
  final bool initiallyExpanded;

  const NotamGroupedList({
    super.key,
    required this.notams,
    this.onNotamTap,
    this.showGroupHeaders = true,
    this.initiallyExpanded = false,
  });

  @override
  State<NotamGroupedList> createState() => _NotamGroupedListState();
}

class _NotamGroupedListState extends State<NotamGroupedList> {
  final Map<NotamGroup, bool> _expandedGroups = {};
  final NotamGroupingService _groupingService = NotamGroupingService();

  @override
  void initState() {
    super.initState();
    // Initialize all groups as collapsed or expanded based on initiallyExpanded
    for (final group in NotamGroup.values) {
      _expandedGroups[group] = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotams = _groupNotamsByGroup();
    final sortedGroups = _sortGroupsByPriority(groupedNotams.keys.toList());

    return ListView.builder(
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        final group = sortedGroups[index];
        final groupNotams = groupedNotams[group] ?? [];
        final isExpanded = _expandedGroups[group] ?? false;

        if (groupNotams.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            if (widget.showGroupHeaders)
              NotamGroupHeader(
                group: group,
                notamCount: groupNotams.length,
                isExpanded: isExpanded,
                onToggle: () => _toggleGroup(group),
                isActive: _hasActiveNotams(groupNotams),
              ),
            if (isExpanded)
              NotamGroupContent(
                notams: _sortNotamsInGroup(groupNotams),
                group: group,
                onNotamTap: widget.onNotamTap,
              ),
          ],
        );
      },
    );
  }

  Map<NotamGroup, List<Notam>> _groupNotamsByGroup() {
    final grouped = <NotamGroup, List<Notam>>{};
    
    for (final notam in widget.notams) {
      final group = notam.group;
      grouped.putIfAbsent(group, () => []).add(notam);
    }
    
    return grouped;
  }

  List<NotamGroup> _sortGroupsByPriority(List<NotamGroup> groups) {
    groups.sort((a, b) {
      final priorityA = _getGroupPriority(a);
      final priorityB = _getGroupPriority(b);
      return priorityA.compareTo(priorityB);
    });
    return groups;
  }

  List<Notam> _sortNotamsInGroup(List<Notam> notams) {
    // Sort by criticality first, then by validity time
    notams.sort((a, b) {
      // Critical NOTAMs first
      if (a.isCritical != b.isCritical) {
        return b.isCritical ? 1 : -1;
      }
      
      // Then by validity start time (earliest first)
      return a.validFrom.compareTo(b.validFrom);
    });
    
    return notams;
  }

  void _toggleGroup(NotamGroup group) {
    setState(() {
      _expandedGroups[group] = !(_expandedGroups[group] ?? false);
    });
  }

  bool _hasActiveNotams(List<Notam> notams) {
    final now = DateTime.now().toUtc();
    return notams.any((notam) {
      return notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
    });
  }

  int _getGroupPriority(NotamGroup group) {
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

  // Public methods for external control
  void expandAll() {
    setState(() {
      for (final group in NotamGroup.values) {
        _expandedGroups[group] = true;
      }
    });
  }

  void collapseAll() {
    setState(() {
      for (final group in NotamGroup.values) {
        _expandedGroups[group] = false;
      }
    });
  }

  void toggleGroup(NotamGroup group) {
    setState(() {
      _expandedGroups[group] = !(_expandedGroups[group] ?? false);
    });
  }

  bool isGroupExpanded(NotamGroup group) {
    return _expandedGroups[group] ?? false;
  }
} 