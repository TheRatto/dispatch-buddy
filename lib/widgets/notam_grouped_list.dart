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

class _NotamGroupedListState extends State<NotamGroupedList> with TickerProviderStateMixin {
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFilteredNotams() async {
    debugPrint('DEBUG: _loadFilteredNotams called');
    
    // Get hidden NOTAM IDs
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: widget.flightContext);
    
    // Filter out hidden NOTAMs
    final filteredNotams = widget.notams.where((notam) => !hiddenIds.contains(notam.id)).toList();
    
    // Group the filtered NOTAMs using the grouping service
    final grouped = _groupingService.groupNotams(filteredNotams);
    
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

  Future<void> _loadHiddenCounts() async {
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: widget.flightContext);
    final hiddenCounts = <NotamGroup, int>{};
    
    for (final group in NotamGroup.values) {
      final groupNotams = widget.notams.where((notam) => notam.group == group).toList();
      final hiddenCount = groupNotams.where((notam) => hiddenIds.contains(notam.id)).length;
      hiddenCounts[group] = hiddenCount;
    }
    
    if (mounted) {
      setState(() {
        _hiddenCounts.clear();
        _hiddenCounts.addAll(hiddenCounts);
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
      
      debugPrint('DEBUG: Group $group: ${groupNotams.length} visible, $hiddenCount hidden, expanded: $isExpanded');
      
      if (groupNotams.isEmpty && hiddenCount == 0) {
        debugPrint('DEBUG:   -> Skipping group $group (no visible or hidden NOTAMs)');
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
            // Animated expansion content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded && groupNotams.isNotEmpty 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: NotamGroupContent(
                notams: _sortNotamsInGroup(groupNotams),
                group: group,
                onNotamTap: widget.onNotamTap,
                flightContext: widget.flightContext,
                onStatusChanged: _onStatusChanged,
                onSwipeStart: _onNotamSwipeStart,
                onSwipeEnd: _onNotamSwipeEnd,
                currentlySwipedNotamId: _currentlySwipedNotamId,
              ),
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
    final wasExpanded = _expandedGroups[group] ?? false;
    setState(() {
      _expandedGroups[group] = !wasExpanded;
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
      case NotamGroup.runways:
        return 'Runways';
      case NotamGroup.taxiways:
        return 'Taxiways';
      case NotamGroup.instrumentProcedures:
        return 'Instrument Procedures';
      case NotamGroup.airportServices:
        return 'Airport Services';
      case NotamGroup.hazards:
        return 'Hazards';
      case NotamGroup.admin:
        return 'Admin';
      case NotamGroup.other:
        return 'Other';
    }
  }

  int _getGroupPriority(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return 1;
      case NotamGroup.taxiways:
        return 2;
      case NotamGroup.instrumentProcedures:
        return 3;
      case NotamGroup.airportServices:
        return 4;
      case NotamGroup.hazards:
        return 5;
      case NotamGroup.admin:
        return 6;
      case NotamGroup.other:
        return 7;
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
    _toggleGroup(group);
  }

  bool isGroupExpanded(NotamGroup group) {
    return _expandedGroups[group] ?? false;
  }
} 