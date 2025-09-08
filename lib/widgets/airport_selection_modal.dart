import 'package:flutter/material.dart';
import '../services/airport_usage_tracker.dart';
import '../services/ersa_data_service.dart';
import 'airport_pill_widget.dart';
import 'state_tab_selector.dart';

/// Airport Selection Modal
/// 
/// Bottom sheet modal for selecting airports from usage history and by state.
/// Follows existing radar location selector pattern.
class AirportSelectionModal extends StatefulWidget {
  final Function(List<String>) onAirportsSelected;

  const AirportSelectionModal({
    super.key,
    required this.onAirportsSelected,
  });

  @override
  State<AirportSelectionModal> createState() => _AirportSelectionModalState();
}

class _AirportSelectionModalState extends State<AirportSelectionModal> {
  final List<String> _selectedAirports = [];
  final int _maxSelections = 10;
  String _selectedState = '';
  List<String> _commonAirports = [];
  List<String> _stateAirports = [];
  List<String> _availableStates = [];
  bool _isLoading = true;
  
  // Swipe selection state
  bool _isSwipeSelecting = false;
  List<String> _swipeSelectedAirports = [];
  String? _swipeStartAirport;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load commonly used airports
      final commonAirports = await AirportUsageTracker.getMostUsedAirports(limit: 10);
      
      // Load available states from ERSA data
      final availableStates = await ERSADataService.getAllStates();
      
      // Set first state as selected
      final selectedState = availableStates.isNotEmpty ? availableStates.first : '';
      
      // Load airports for selected state
      final stateAirports = await ERSADataService.getAirportsForState(selectedState);
      
      setState(() {
        _commonAirports = commonAirports;
        _availableStates = availableStates;
        _selectedState = selectedState;
        _stateAirports = stateAirports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AirportSelectionModal: Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onStateChanged(String state) async {
    setState(() {
      _selectedState = state;
    });
    
    // Load airports for the new state
    final stateAirports = await ERSADataService.getAirportsForState(state);
    setState(() {
      _stateAirports = stateAirports;
    });
  }

  void _toggleAirport(String icao) {
    setState(() {
      if (_selectedAirports.contains(icao)) {
        _selectedAirports.remove(icao);
      } else if (_selectedAirports.length < _maxSelections) {
        _selectedAirports.add(icao);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedAirports.clear();
      _swipeSelectedAirports.clear();
      _isSwipeSelecting = false;
      _swipeStartAirport = null;
    });
  }

  void _startSwipeSelection(String icao) {
    setState(() {
      _isSwipeSelecting = true;
      _swipeStartAirport = icao;
      _swipeSelectedAirports = [icao];
    });
  }

  void _updateSwipeSelection(String icao) {
    if (!_isSwipeSelecting || _swipeStartAirport == null) return;
    
    setState(() {
      // Find the range between start and current airport
      final allAirports = [..._commonAirports, ..._stateAirports];
      final startIndex = allAirports.indexOf(_swipeStartAirport!);
      final currentIndex = allAirports.indexOf(icao);
      
      if (startIndex != -1 && currentIndex != -1) {
        final start = startIndex < currentIndex ? startIndex : currentIndex;
        final end = startIndex < currentIndex ? currentIndex : startIndex;
        
        _swipeSelectedAirports = allAirports.sublist(start, end + 1);
      }
    });
  }

  void _endSwipeSelection() {
    if (!_isSwipeSelecting) return;
    
    setState(() {
      // Add swipe selected airports to main selection (up to max limit)
      for (final icao in _swipeSelectedAirports) {
        if (!_selectedAirports.contains(icao) && _selectedAirports.length < _maxSelections) {
          _selectedAirports.add(icao);
        }
      }
      
      // Reset swipe state
      _isSwipeSelecting = false;
      _swipeSelectedAirports.clear();
      _swipeStartAirport = null;
    });
  }

  void _generateBriefing() {
    if (_selectedAirports.isNotEmpty) {
      widget.onAirportsSelected(_selectedAirports);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Text(
            'Select Airports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (_isLoading) ...[
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected airports section
                    _buildSelectedSection(),
                    const SizedBox(height: 24),
                    
                    // Commonly used airports section
                    _buildCommonSection(),
                    const SizedBox(height: 24),
                    
                    // State selector and airports
                    _buildStateSection(),
                  ],
                ),
              ),
            ),
          ],
          
          // Action buttons
          if (!_isLoading) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected (${_selectedAirports.length}/$_maxSelections):',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120), // Pre-allocate space for 10 pills
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _selectedAirports.isEmpty
              ? Center(
                  child: Text(
                    'No airports selected',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Show selected airports
                    ..._selectedAirports.map((icao) {
                      return AirportPillWidget(
                        icao: icao,
                        isSelected: true,
                        onTap: () => _toggleAirport(icao),
                      );
                    }).toList(),
                    // Show empty slots for remaining selections
                    ...List.generate(
                      _maxSelections - _selectedAirports.length,
                      (index) => Container(
                        width: 60,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commonly Used:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAirportGrid(_commonAirports),
      ],
    );
  }

  Widget _buildStateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State tabs
        StateTabSelector(
          selectedState: _selectedState,
          onStateSelected: _onStateChanged,
          states: _availableStates,
        ),
        const SizedBox(height: 16),
        
        // State airports
        Text(
          '$_selectedState Airports:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildAirportGrid(_stateAirports),
      ],
    );
  }

  Widget _buildAirportGrid(List<String> airports) {
    return GestureDetector(
      onPanStart: (details) {
        // Swipe selection will be handled by individual pill gestures
        // This is a placeholder for future enhancement
      },
      onPanUpdate: (details) {
        // Update swipe selection as user drags
        // This would need more sophisticated hit testing in a real implementation
      },
      onPanEnd: (details) {
        _endSwipeSelection();
      },
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: airports.map((icao) {
          final isSelected = _selectedAirports.contains(icao);
          final isSwipeSelected = _swipeSelectedAirports.contains(icao);
          final isDisabled = !isSelected && _selectedAirports.length >= _maxSelections;
          
          return AirportPillWidget(
            icao: icao,
            isSelected: isSelected || isSwipeSelected,
            isDisabled: isDisabled,
            onTap: () => _toggleAirport(icao),
            onPanStart: () => _startSwipeSelection(icao),
            onPanUpdate: () => _updateSwipeSelection(icao),
            onPanEnd: () => _endSwipeSelection(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _selectedAirports.isEmpty ? null : _clearAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedAirports.isEmpty ? null : _generateBriefing,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate Briefing'),
          ),
        ),
      ],
    );
  }
}
