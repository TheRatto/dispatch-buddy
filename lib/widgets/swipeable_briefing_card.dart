import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
import '../services/data_freshness_service.dart';
import '../providers/flight_provider.dart';

class SwipeableBriefingCard extends StatefulWidget {
  final Briefing briefing;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeEnd;
  final bool shouldClose;

  SwipeableBriefingCard({
    super.key,
    required this.briefing,
    this.onTap,
    this.onRefresh,
    this.onSwipeStart,
    this.onSwipeEnd,
    this.shouldClose = false,
  }) {
    debugPrint('DEBUG: 🎯 SwipeableBriefingCard constructor called for briefing ${briefing.id}');
  }

  @override
  State<SwipeableBriefingCard> createState() => _SwipeableBriefingCardState();
}

class _SwipeableBriefingCardState extends State<SwipeableBriefingCard>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _dismissController;
  double _dragExtent = 0.0;
  double _maxSlideDuringDrag = 0.0;
  bool _isDismissing = false;
  bool _autoDeleteTriggered = false;
  bool _dragStarted = false;
  
  // Inline editing state
  bool _isEditing = false;
  late TextEditingController _editController;
  late FocusNode _editFocusNode;
  
  // Refresh state
  bool _isRefreshing = false;
  
  // Age update timer
  Timer? _ageUpdateTimer;

  static const double _actionWidth = 72.0;
  static const double _maxDrag = 400.0; // Allow much more drag to reach 80% of card width
  static const double _swipeThreshold = 0.5; // 50% of max drag

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: 🎯 SwipeableBriefingCard initState called for briefing ${widget.briefing.id}');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 0.0,
    );
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0.0,
    );
    
    // Initialize inline editing controllers
    _editController = TextEditingController(text: widget.briefing.name ?? '');
    _editFocusNode = FocusNode();
    
    // Start timer to update age string every minute
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update age string
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SwipeableBriefingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldClose && !oldWidget.shouldClose) {
      _closeActions();
    }
    
    // Update edit controller if briefing name changes
    if (widget.briefing.name != oldWidget.briefing.name) {
      _editController.text = widget.briefing.name ?? '';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final newDragExtent = (_dragExtent + details.delta.dx).clamp(-_maxDrag, 0.0);
    final newAnimationValue = -newDragExtent / _maxDrag;
    final slidePx = -newDragExtent;
    
    setState(() {
      _dragExtent = newDragExtent;
      _animationController.value = newAnimationValue;
      // Track maximum slide during this drag
      if (slidePx > _maxSlideDuringDrag) {
        _maxSlideDuringDrag = slidePx;
      }
      // Track when drag starts and notify parent
      if (!_dragStarted && newDragExtent != 0.0) {
        _dragStarted = true;
        _autoDeleteTriggered = false;
        _maxSlideDuringDrag = 0.0; // Reset max slide when starting new drag
        widget.onSwipeStart?.call();
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    final cardWidth = MediaQuery.of(context).size.width;
    final currentSlidePx = -_dragExtent;
    const halfOpenThreshold = 74.0; // Threshold for snap decisions
    const buttonFullyVisiblePx = 48.0 + 8.0 + 48.0 + 8.0 + 48.0 + 16.0 + 36.0; // Three buttons + spacing + padding + extra space
    final autoDeleteThreshold = cardWidth * 0.8;
    
    // Determine final position based on velocity and current position
    double targetSlide = 0.0;
    
    if (currentSlidePx >= autoDeleteThreshold) {
      // Auto-delete threshold reached
      targetSlide = autoDeleteThreshold;
    } else if (currentSlidePx >= buttonFullyVisiblePx) {
      // Buttons fully visible - snap to open
      targetSlide = buttonFullyVisiblePx;
    } else if (currentSlidePx >= halfOpenThreshold) {
      // Past half-open threshold - snap to open
      targetSlide = buttonFullyVisiblePx;
    } else {
      // Below threshold - snap to closed
      targetSlide = 0.0;
    }
    
    // Animate to target position
    final animationDuration = Duration(
      milliseconds: (300 * (targetSlide - currentSlidePx).abs() / buttonFullyVisiblePx).round(),
    );
    
    _animationController.duration = animationDuration;
    final targetValue = -targetSlide / _maxDrag;
    
    await _animationController.animateTo(targetValue);
    
    setState(() {
      _dragExtent = -targetSlide;
      _dragStarted = false;
    });
    
    // Trigger auto-delete if threshold reached
    if (targetSlide >= autoDeleteThreshold && !_autoDeleteTriggered) {
      _autoDeleteTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onDeleteTap();
        }
      });
    }
  }

  void _closeActions() {
    _animationController.animateTo(0.0);
    setState(() {
      _dragExtent = 0.0;
    });
  }

  void _onFlagTap() async {
    try {
      final updatedBriefing = widget.briefing.copyWith(
        isFlagged: !widget.briefing.isFlagged,
      );
      
      final success = await BriefingStorageService.updateBriefing(updatedBriefing);
      
      if (success) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedBriefing.isFlagged ? 'Briefing pinned' : 'Briefing unpinned',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the list
        widget.onRefresh?.call();
      } else {
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update briefing'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR: Failed to flag/unflag briefing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onRenameTap() async {
    // Snap card back to closed position
    await _animationController.animateTo(0.0);
    setState(() {
      _dragExtent = 0.0;
      _isEditing = true;
    });
    
    // Focus the text field and show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _saveRename() async {
    final newName = _editController.text.trim();
    
    if (newName != widget.briefing.name) {
      try {
        final updatedBriefing = widget.briefing.copyWith(
          name: newName.isEmpty ? null : newName,
        );
        
        final success = await BriefingStorageService.updateBriefing(updatedBriefing);
        
        if (success) {
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newName.isEmpty 
                  ? 'Briefing name removed' 
                  : 'Briefing renamed to "$newName"',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Refresh the list
          widget.onRefresh?.call();
        } else {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to rename briefing'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('ERROR: Failed to rename briefing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Exit editing mode
    setState(() {
      _isEditing = false;
    });
    _editFocusNode.unfocus();
  }

  void _cancelRename() {
    // Restore original name
    _editController.text = widget.briefing.name ?? '';
    
    // Exit editing mode
    setState(() {
      _isEditing = false;
    });
    _editFocusNode.unfocus();
  }

  void _onRefreshTap() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    
    debugPrint('DEBUG: 🔄 REFRESH BUTTON TAPPED for briefing ${widget.briefing.id}');
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      debugPrint('DEBUG: Starting unified card refresh for briefing ${widget.briefing.id}');
      
      // Use the unified refresh method that can refresh any briefing
      final flightProvider = Provider.of<FlightProvider>(context, listen: false);
      final success = await flightProvider.refreshBriefingByIdUnified(widget.briefing.id);
      
      if (success) {
        debugPrint('DEBUG: Unified card refresh completed successfully');
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Briefing refreshed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Notify parent to refresh the list
        widget.onRefresh?.call();
      } else {
        debugPrint('DEBUG: Unified card refresh failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh briefing'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR: Failed to refresh briefing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh briefing: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _onDeleteTap() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Briefing'),
          content: Text(
            'Are you sure you want to delete "${widget.briefing.displayName}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        final success = await BriefingStorageService.deleteBriefing(widget.briefing.id);
        
        if (success) {
          // Immediately refresh the list to remove the gap
          widget.onRefresh?.call();
          
          // Then animate out the card
          _isDismissing = true;
          await _dismissController.forward();
        } else {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete briefing'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('ERROR: Failed to delete briefing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width;
    final slide = -_dragExtent;
    final animValue = _animationController.value;
    
    // Calculate button positions and animations
    const buttonSize = 48.0;
    const buttonSpacing = 8.0;
    const sidePadding = 16.0;
    const fadeWindow = 36.0;
    
    // Calculate when each button should start appearing (right to left)
    const deleteStartPx = buttonSize + sidePadding; // Rightmost button appears first
    const renameStartPx = deleteStartPx + buttonSpacing + buttonSize; // Middle button appears second
    const flagStartPx = renameStartPx + buttonSpacing + buttonSize; // Leftmost button appears third
    
    final deleteAnim = ((slide - deleteStartPx) / fadeWindow).clamp(0.0, 1.0);
    final renameAnim = ((slide - renameStartPx) / fadeWindow).clamp(0.0, 1.0);
    final flagAnim = ((slide - flagStartPx) / fadeWindow).clamp(0.0, 1.0);
    
    // Delete button expansion: starts after all buttons are fully visible
    final expansionStartPx = flagStartPx + fadeWindow;
    final expansionEndPx = cardWidth * 0.8;
    double deleteButtonWidth = buttonSize;
    double expansionAnim = 0.0;
    if (slide > expansionStartPx) {
      expansionAnim = ((slide - expansionStartPx) / (expansionEndPx - expansionStartPx)).clamp(0.0, 1.0);
      deleteButtonWidth = buttonSize + (expansionAnim * 24.0).clamp(0.0, 24.0);
    }
    
    final overlayOpacity = (animValue * 0.3).clamp(0.0, 0.3);
    final showActions = slide > 0;
    
    // Auto-delete trigger - use post-frame callback to avoid build-time navigation
    final autoDeleteThreshold = cardWidth * 0.8;
    if (slide >= autoDeleteThreshold && !_autoDeleteTriggered) {
      _autoDeleteTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onDeleteTap();
        }
      });
    }
    
    // Dismiss animation: slide further left and fade out
    return AnimatedBuilder(
      animation: _dismissController,
      builder: (context, child) {
        final dismissProgress = _dismissController.value;
        final dismissOffset = -cardWidth * dismissProgress;
        final dismissOpacity = 1.0 - dismissProgress;
        return Opacity(
          opacity: dismissOpacity,
          child: Transform.translate(
            offset: Offset(dismissOffset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _isDismissing ? null : _handleDragUpdate,
              onHorizontalDragEnd: _isDismissing ? null : _handleDragEnd,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (showActions && !_isDismissing)
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Flag button (left)
                          _buildAnimatedActionButton(
                            color: Colors.blue,
                            icon: widget.briefing.isFlagged ? Icons.star : Icons.star_border,
                            label: widget.briefing.isFlagged ? 'Unpin' : 'Pin',
                            onTap: _onFlagTap,
                            anim: flagAnim,
                            width: buttonSize,
                          ),
                          const SizedBox(width: buttonSpacing),
                          // Rename button (middle)
                          _buildAnimatedActionButton(
                            color: Colors.orange,
                            icon: Icons.edit,
                            label: 'Rename',
                            onTap: _onRenameTap,
                            anim: renameAnim,
                            width: buttonSize,
                          ),
                          const SizedBox(width: buttonSpacing),
                          // Delete button (right, expands internally)
                          SizedBox(
                            width: deleteButtonWidth,
                            child: _buildAnimatedActionButton(
                              color: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                              onTap: _onDeleteTap,
                              anim: deleteAnim,
                              width: buttonSize, // Keep internal button size fixed
                            ),
                          ),
                          const SizedBox(width: sidePadding),
                        ],
                      ),
                    ),
                  // Card content (slides left)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Transform.translate(
                      offset: Offset(-slide, 0),
                      child: Stack(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: _buildCardContent(),
                          ),
                          // Grey overlay as you swipe
                          if (overlayOpacity > 0)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: overlayOpacity),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    final ageString = DataFreshnessService.getAgeString(widget.briefing.timestamp);
    final freshnessColor = DataFreshnessService.getFreshnessColor(widget.briefing.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: _isEditing ? null : widget.onTap, // Disable tap when editing
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name, flag, freshness, and refresh
              Row(
                children: [
                  Expanded(
                    child: _isEditing 
                      ? _buildInlineEditField()
                      : Text(
                          widget.briefing.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                  if (!_isEditing) ...[
                    // Refresh button
                    IconButton(
                      onPressed: _isRefreshing ? null : () {
                        debugPrint('DEBUG: 🔄 REFRESH BUTTON PRESSED for briefing ${widget.briefing.id}');
                        debugPrint('DEBUG: 🎯 ABOUT TO CALL _onRefreshTap()');
                        _onRefreshTap();
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.briefing.isFlagged)
                      const Icon(
                        Icons.star,
                        color: Colors.blue,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      color: freshnessColor,
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              
              // Airports
              Text(
                widget.briefing.airports.join(', '),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              
              // Age
              Text(
                ageString,
                style: TextStyle(
                  fontSize: 14,
                  color: freshnessColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInlineEditField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _editController,
          focusNode: _editFocusNode,
          decoration: const InputDecoration(
            hintText: 'Enter briefing name...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _saveRename(),
          onEditingComplete: _saveRename,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelRename,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveRename,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double anim,
    double width = 48.0,
  }) {
    // Clamp animation values to valid range
    final clampedAnim = anim.clamp(0.0, 1.0);
    
    return AnimatedOpacity(
      opacity: clampedAnim,
      duration: const Duration(milliseconds: 100),
      child: Transform.scale(
        scale: 0.7 + 0.3 * clampedAnim, // scale from 0.7 to 1.0
        child: SizedBox(
          width: width,
          child: _buildActionButton(
            color: color,
            icon: icon,
            label: label,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
} 