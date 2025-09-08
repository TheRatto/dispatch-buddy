import 'package:flutter/material.dart';

/// State Tab Selector Widget
/// 
/// Horizontal state selection tabs using existing radar selector styling.
/// Allows users to filter airports by Australian state/territory.
class StateTabSelector extends StatefulWidget {
  final String selectedState;
  final Function(String) onStateSelected;
  final List<String> states;

  const StateTabSelector({
    super.key,
    required this.selectedState,
    required this.onStateSelected,
    required this.states,
  });

  @override
  State<StateTabSelector> createState() => _StateTabSelectorState();
}

class _StateTabSelectorState extends State<StateTabSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.states.length,
      vsync: this,
    );
    
    // Set initial tab based on selected state
    final initialIndex = widget.states.indexOf(widget.selectedState);
    if (initialIndex != -1) {
      _tabController.index = initialIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ClipRect(
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black87,
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 3,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onTap: (index) {
            final state = widget.states[index];
            widget.onStateSelected(state);
          },
          tabs: widget.states.map((state) {
            return Tab(
              text: state,
              height: 40,
            );
          }).toList(),
        ),
      ),
    );
  }
}
