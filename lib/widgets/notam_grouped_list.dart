import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';
import 'package:dispatch_buddy/services/notam_status_service.dart';
import 'package:dispatch_buddy/widgets/notam_group_header.dart';
import 'package:dispatch_buddy/widgets/notam_group_content.dart';

class NotamGroupedList extends StatefulWidget {
  final List<Notam> notams;
  final Function(Notam)? onNotamTap;
  final bool showGroupHeaders;
  final bool initiallyExpanded;
  final String? flightContext;

  const NotamGroupedList({
    super.key,
    required this.notams,
    this.onNotamTap,
    this.showGroupHeaders = true,
    this.initiallyExpanded = false,
    this.flightContext,
  });

  @override
  State<NotamGroupedList> createState() => _NotamGroupedListState();
}

class _NotamGroupedListState extends State<NotamGroupedList> {
  final Map<NotamGroup, bool> _expandedGroups = {};
  final NotamGroupingService _groupingService = NotamGroupingService();
  final NotamStatusService _statusService = NotamStatusService();
  
  // Track hidden counts for each group
  final Map<NotamGroup, int> _hiddenCounts = {};
  
  // Cache for filtered NOTAMs
  Map<NotamGroup, List<Notam>>? _filteredGroupedNotams;
  
  // Track which NOTAM is currently being swiped
  String? _currentlySwipedNotamId;

  @override
  void initState() {
    super.initState();
    // Initialize all groups as collapsed or expanded based on initiallyExpanded
    for (final group in NotamGroup.values) {
      _expandedGroups[group] = widget.initiallyExpanded;
    }
    _loadHiddenCounts();
    _loadFilteredNotams();
  }

  @override
  void didUpdateWidget(covariant NotamGroupedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the NOTAMs list or flight context changes, reload filtered/grouped NOTAMs
    if (widget.notams != oldWidget.notams || widget.flightContext != oldWidget.flightContext) {
      debugPrint('DEBUG: didUpdateWidget called - NOTAMs changed or flight context changed');
      debugPrint('DEBUG: Old NOTAM count: ${oldWidget.notams.length}, New NOTAM count: ${widget.notams.length}');
      debugPrint('DEBUG: Old flight context: ${oldWidget.flightContext}, New flight context: ${widget.flightContext}');
      if (widget.notams.isNotEmpty) {
        debugPrint('DEBUG: First NOTAM ID: ${widget.notams.first.id}');
      }
      _loadFilteredNotams();
      _loadHiddenCounts();
    } else {
      debugPrint('DEBUG: didUpdateWidget called - no changes detected');
    }
  }

  Future<void> _loadHiddenCounts() async {
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: widget.flightContext);
    
    // Get all NOTAMs for each group (including hidden ones)
    final allGroupedNotams = _groupNotamsByGroup();
    
    for (final group in NotamGroup.values) {
      final allGroupNotams = allGroupedNotams[group] ?? [];
      final hiddenCount = allGroupNotams.where((n) => hiddenIds.contains(n.id)).length;
      
      debugPrint('DEBUG: Group ${group} hidden count: ${hiddenCount} (out of ${allGroupNotams.length} total)');
      
      if (mounted) {
        setState(() {
          _hiddenCounts[group] = hiddenCount;
        });
      }
    }
  }

  Future<void> _loadFilteredNotams() async {
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: widget.flightContext);
    final filteredNotams = widget.notams.where((notam) => !hiddenIds.contains(notam.id)).toList();
    
    debugPrint('DEBUG: Total NOTAMs: ${widget.notams.length}');
    debugPrint('DEBUG: Hidden NOTAMs: ${hiddenIds.length}');
    debugPrint('DEBUG: Filtered NOTAMs: ${filteredNotams.length}');
    
    // First, get all groups that have any NOTAMs (visible or hidden)
    final allGroupedNotams = _groupNotamsByGroup();
    
    final grouped = <NotamGroup, List<Notam>>{};
    
    // Add groups that have visible NOTAMs
    for (final notam in filteredNotams) {
      final group = notam.group;
      grouped.putIfAbsent(group, () => []).add(notam);
    }
    
    // Add groups that have hidden NOTAMs but no visible NOTAMs
    for (final entry in allGroupedNotams.entries) {
      final group = entry.key;
      final allGroupNotams = entry.value;
      final hiddenCount = allGroupNotams.where((n) => hiddenIds.contains(n.id)).length;
      
      // If this group has hidden NOTAMs but no visible NOTAMs, add it with empty list
      if (hiddenCount > 0 && !grouped.containsKey(group)) {
        grouped[group] = [];
      }
    }
    
    // Debug: Log group statistics
    debugPrint('DEBUG: Grouped NOTAMs:');
    for (final entry in grouped.entries) {
      debugPrint('DEBUG:   ${entry.key}: ${entry.value.length} NOTAMs');
      for (final notam in entry.value) {
        final preview = notam.rawText.length > 50 
            ? '${notam.rawText.substring(0, 50)}...'
            : notam.rawText;
        debugPrint('DEBUG:     - ${notam.id}: $preview');
      }
    }
    
    if (mounted) {
      setState(() {
        _filteredGroupedNotams = grouped;
      });
    }
  }

  void _onStatusChanged() {
    _loadHiddenCounts();
    _loadFilteredNotams();
  }

  void _onNotamSwipeStart(String notamId) {
    debugPrint('DEBUG: _onNotamSwipeStart called with notamId: $notamId');
    setState(() {
      _currentlySwipedNotamId = notamId;
    });
    debugPrint('DEBUG: _currentlySwipedNotamId set to: $_currentlySwipedNotamId');
  }

  void _onNotamSwipeEnd() {
    debugPrint('DEBUG: _onNotamSwipeEnd called');
    setState(() {
      _currentlySwipedNotamId = null;
    });
    debugPrint('DEBUG: _currentlySwipedNotamId cleared to: $_currentlySwipedNotamId');
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredGroupedNotams == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedNotams = _filteredGroupedNotams!;
    final sortedGroups = _sortGroupsByPriority(groupedNotams.keys.toList());

    debugPrint('DEBUG: Building NOTAM list with ${sortedGroups.length} groups');
    debugPrint('DEBUG: Available groups: ${groupedNotams.keys.map((g) => g.toString()).join(', ')}');
    debugPrint('DEBUG: Sorted groups: ${sortedGroups.map((g) => g.toString()).join(', ')}');
    
    for (final group in sortedGroups) {
      final groupNotams = groupedNotams[group] ?? [];
      final hiddenCount = _hiddenCounts[group] ?? 0;
      final isExpanded = _expandedGroups[group] ?? false;
      
      debugPrint('DEBUG: Group ${group}: ${groupNotams.length} visible, ${hiddenCount} hidden, expanded: $isExpanded');
      
      if (groupNotams.isEmpty && hiddenCount == 0) {
        debugPrint('DEBUG:   -> Skipping group ${group} (no visible or hidden NOTAMs)');
      }
    }

    return ListView.builder(
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        final group = sortedGroups[index];
        final groupNotams = groupedNotams[group] ?? [];
        final isExpanded = _expandedGroups[group] ?? false;
        final hiddenCount = _hiddenCounts[group] ?? 0;

        // Show group if there are visible NOTAMs OR if there are hidden NOTAMs
        if (groupNotams.isEmpty && hiddenCount == 0) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            if (widget.showGroupHeaders)
              NotamGroupHeader(
                group: group,
                notamCount: groupNotams.length,
                hiddenCount: hiddenCount,
                isExpanded: isExpanded,
                onToggle: () => _toggleGroup(group),
                isActive: _hasActiveNotams(groupNotams),
                onHiddenTap: () => _showHiddenNotams(group),
              ),
            if (isExpanded && groupNotams.isNotEmpty)
              NotamGroupContent(
                notams: _sortNotamsInGroup(groupNotams),
                group: group,
                onNotamTap: widget.onNotamTap,
                flightContext: widget.flightContext,
                onStatusChanged: _onStatusChanged,
                onSwipeStart: _onNotamSwipeStart,
                onSwipeEnd: _onNotamSwipeEnd,
                currentlySwipedNotamId: _currentlySwipedNotamId,
              ),
          ],
        );
      },
    );
  }

  List<Notam> _getNotamsForGroup(NotamGroup group) {
    return widget.notams.where((notam) => notam.group == group).toList();
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

  void _showHiddenNotams(NotamGroup group) async {
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: widget.flightContext);
    final allGroupNotams = _getNotamsForGroup(group);
    final hiddenNotams = allGroupNotams.where((n) => hiddenIds.contains(n.id)).toList();
    
    if (hiddenNotams.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildHiddenNotamsModal(group, hiddenNotams),
    );
  }

  Widget _buildHiddenNotamsModal(NotamGroup group, List<Notam> hiddenNotams) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Hidden ${_getGroupTitle(group)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${hiddenNotams.length} NOTAM${hiddenNotams.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Hidden NOTAMs list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: hiddenNotams.length,
                  itemBuilder: (context, index) {
                    final notam = hiddenNotams[index];
                    return ListTile(
                      title: Text(notam.id),
                      subtitle: Text(notam.displayRawText),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () async {
                          await _statusService.unhideNotam(notam.id);
                          Navigator.of(context).pop();
                          _onStatusChanged();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGroupTitle(NotamGroup group) {
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