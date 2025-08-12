import 'dart:async';
import 'package:flutter/material.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
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
  Timer? _ageUpdateTimer;
  
  // Bulk refresh state
  bool _isBulkRefreshing = false;
  int _refreshProgress = 0;
  int _totalBriefings = 0;

  @override
  void initState() {
    super.initState();
    _loadBriefings();
    // _addTestData(); // Removed - now using real auto-save
    
    // Start timer to update age strings every minute
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update age strings
        });
      }
    });
    
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

  Future<void> _refreshAllBriefings() async {
    if (_isBulkRefreshing || _briefings.isEmpty) return;
    
    setState(() {
      _isBulkRefreshing = true;
      _refreshProgress = 0;
      _totalBriefings = _briefings.length;
    });
    
    int successCount = 0;
    int failureCount = 0;
    
    try {
      // Refresh from bottom to top so the last refreshed ones stay at the top
      for (int i = _briefings.length - 1; i >= 0; i--) {
        final briefing = _briefings[i];
        
        try {
          debugPrint('DEBUG: Starting unified bulk refresh for briefing ${briefing.id} (${_briefings.length - i}/${_briefings.length})');
          
          // Use the bulk refresh method that doesn't load into UI
          final flightProvider = Provider.of<FlightProvider>(context, listen: false);
          final success = await flightProvider.refreshBriefingByIdForBulk(briefing.id);
          
          if (success) {
            debugPrint('DEBUG: ✅ Unified bulk refresh completed for briefing ${briefing.id}');
            successCount++;
          } else {
            debugPrint('DEBUG: ❌ Unified bulk refresh failed for briefing ${briefing.id}');
            failureCount++;
          }
        } catch (e) {
          debugPrint('ERROR: Failed to refresh briefing ${briefing.id}: $e');
          failureCount++;
        }
        
        setState(() {
          _refreshProgress = _briefings.length - i;
        });
        
        // Add a small delay between refreshes to avoid overwhelming the APIs
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      debugPrint('DEBUG: Bulk refresh completed - Success: $successCount, Failed: $failureCount');
      
      // Reload briefings to get updated data
      await _loadBriefings();
      
      // Show results
      final message = failureCount == 0 
        ? 'Successfully refreshed all $successCount briefings'
        : 'Refreshed $successCount briefings, $failureCount failed';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('ERROR: Bulk refresh failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh briefings: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isBulkRefreshing = false;
        _refreshProgress = 0;
        _totalBriefings = 0;
      });
    }
  }

  @override
  void dispose() {
    _ageUpdateTimer?.cancel();
    super.dispose();
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

    return Column(
      children: [
        // Header with Refresh All button
        if (_briefings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Previous Briefings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isBulkRefreshing ? null : _refreshAllBriefings,
                  icon: _isBulkRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                  label: Text(_isBulkRefreshing 
                    ? 'Refreshing... ($_refreshProgress/$_totalBriefings)'
                    : 'Refresh All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        // Briefings list
        Expanded(
            child: ListView.builder(
            key: ValueKey('briefings_list_${_briefings.length}_${_briefings.map((b) => b.id).join('_')}'),
              padding: EdgeInsets.zero,
              itemCount: _briefings.length,
              itemBuilder: (context, index) {
                final briefing = _briefings[index];
                return SwipeableBriefingCard(
                  briefing: briefing,
                  onTap: () async {
                  debugPrint('DEBUG: 🎯 BRIEFING CARD TAPPED for briefing ${briefing.id}');
                    // Load the briefing into FlightProvider
                    await Provider.of<FlightProvider>(context, listen: false).loadBriefing(briefing);
                  debugPrint('DEBUG: 🎯 loadBriefing completed for briefing ${briefing.id}');
                    // Navigate to the briefing tabs screen (with bottom navigation)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BriefingTabsScreen(),
                      ),
                    );
                  debugPrint('DEBUG: 🎯 Navigation completed for briefing ${briefing.id}');
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
        ),
      ],
    );
  }
}

 