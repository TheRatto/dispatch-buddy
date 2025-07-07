import 'package:flutter/material.dart';

/// TAF Airport Selector Widget
/// 
/// Displays horizontal scrollable airport bubbles for TAF selection:
/// - Airport ICAO code bubbles
/// - Selected state highlighting
/// - Cache clearing on airport change
/// - Add button for additional airports
/// - Long-press to edit/remove airports
/// - Chevron indicators for off-screen bubbles
/// - Exact styling preserved from original implementation
class TafAirportSelector extends StatefulWidget {
  final List<String> airports;
  final String? selectedAirport;
  final Function(String) onAirportSelected;
  final VoidCallback? onCacheClear;
  final Function(BuildContext)? onAddAirport;
  final Function(BuildContext, String)? onAirportLongPress;

  const TafAirportSelector({
    super.key,
    required this.airports,
    required this.selectedAirport,
    required this.onAirportSelected,
    this.onCacheClear,
    this.onAddAirport,
    this.onAirportLongPress,
  });

  @override
  State<TafAirportSelector> createState() => _TafAirportSelectorState();
}

class _TafAirportSelectorState extends State<TafAirportSelector> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftChevron = false;
  bool _showRightChevron = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check initial scroll state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateChevronVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateChevronVisibility();
  }

  void _updateChevronVisibility() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final showLeft = position.pixels > 0;
    final showRight = position.pixels < position.maxScrollExtent;
    
    if (showLeft != _showLeftChevron || showRight != _showRightChevron) {
      setState(() {
        _showLeftChevron = showLeft;
        _showRightChevron = showRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...widget.airports.map((icao) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildAirportBubble(
                  context,
                  icao,
                  widget.selectedAirport == icao,
                  () {
                    if (widget.selectedAirport != icao) {
                      widget.onCacheClear?.call(); // Clear cache when switching airports
                    }
                    widget.onAirportSelected(icao);
                  },
                ),
              )),
              // Add button
              if (widget.onAddAirport != null) Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildAddButton(context),
              ),
            ],
          ),
        ),
        // Left chevron indicator
        if (_showLeftChevron)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
        // Right chevron indicator
        if (_showRightChevron)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAirportBubble(BuildContext context, String icao, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: widget.onAirportLongPress != null ? () => widget.onAirportLongPress!(context, icao) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF97316) : Colors.grey[700]!,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF97316) : Colors.grey[600]!,
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onAddAirport!(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[700]!,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: Colors.white70,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Add',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 