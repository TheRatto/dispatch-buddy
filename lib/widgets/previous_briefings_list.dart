import 'package:flutter/material.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
import '../services/data_freshness_service.dart';
import 'swipeable_briefing_card.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../screens/briefing_tabs_screen.dart';

/// Previous Briefings List Widget
/// 
/// Displays a list of saved briefings with basic information
/// and data freshness indicators.
class PreviousBriefingsList extends StatefulWidget {
  final VoidCallback? onBriefingSelected;

  const PreviousBriefingsList({
    super.key,
    this.onBriefingSelected,
  });

  @override
  State<PreviousBriefingsList> createState() => _PreviousBriefingsListState();
}

class _PreviousBriefingsListState extends State<PreviousBriefingsList> {
  List<Briefing> _briefings = [];
  bool _isLoading = true;
  String? _error;
  String? _currentlySwipedBriefingId;

  @override
  void initState() {
    super.initState();
    _loadBriefings();
    // _addTestData(); // Removed - now using real auto-save
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh briefings when dependencies change (e.g., returning to screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBriefings();
      }
    });
  }

  Future<void> _loadBriefings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('DEBUG: Loading briefings from storage...');
      final briefings = await BriefingStorageService.loadAllBriefings();
      debugPrint('DEBUG: Loaded ${briefings.length} briefings from storage');
      
      // Debug: Print details of each briefing
      for (final briefing in briefings) {
        debugPrint('DEBUG: Briefing ${briefing.id} - ${briefing.displayName} - Created: ${briefing.timestamp} - Age: ${briefing.ageInHours}h');
      }
      
      setState(() {
        _briefings = briefings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DEBUG: Error loading briefings: $e');
      setState(() {
        _error = 'Failed to load briefings: $e';
        _isLoading = false;
      });
    }
  }

  void _onBriefingSwipeStart(String briefingId) {
    setState(() {
      _currentlySwipedBriefingId = briefingId;
    });
  }

  void _onBriefingSwipeEnd() {
    setState(() {
      _currentlySwipedBriefingId = null;
    });
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBriefings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_briefings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Previous Briefings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your briefings will appear here after you generate them',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBriefings,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _briefings.length,
                      itemBuilder: (context, index) {
                final briefing = _briefings[index];
                return SwipeableBriefingCard(
                  briefing: briefing,
                  onTap: () {
                    // Load the briefing into FlightProvider
                    Provider.of<FlightProvider>(context, listen: false).loadBriefing(briefing);
                    // Navigate to the briefing tabs screen (with bottom navigation)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BriefingTabsScreen(),
                      ),
                    );
                    widget.onBriefingSelected?.call();
                  },
                  onRefresh: _loadBriefings,
                  onSwipeStart: () => _onBriefingSwipeStart(briefing.id),
                  onSwipeEnd: _onBriefingSwipeEnd,
                  shouldClose: _currentlySwipedBriefingId != null && 
                              _currentlySwipedBriefingId != briefing.id,
                );
              },
      ),
    );
  }
}

 