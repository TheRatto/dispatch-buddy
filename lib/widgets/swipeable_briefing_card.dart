import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
import '../services/data_freshness_service.dart';

class SwipeableBriefingCard extends StatefulWidget {
  final Briefing briefing;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeEnd;
  final bool shouldClose;

  const SwipeableBriefingCard({
    super.key,
    required this.briefing,
    this.onTap,
    this.onRefresh,
    this.onSwipeStart,
    this.onSwipeEnd,
    this.shouldClose = false,
  });

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

  static const double _actionWidth = 72.0;
  static const double _maxDrag = 400.0; // Allow much more drag to reach 80% of card width
  static const double _swipeThreshold = 0.5; // 50% of max drag

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void didUpdateWidget(covariant SwipeableBriefingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldClose && !oldWidget.shouldClose) {
      _closeActions();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissController.dispose();
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
    final halfOpenThreshold = 74.0; // Threshold for snap decisions
    final buttonFullyVisiblePx = 112.0 + 36.0; // flagStartPx + fadeWindow = 148px
    final autoDeleteThreshold = cardWidth * 0.8;
    
    // Notify parent that swipe ended
    widget.onSwipeEnd?.call();
    
    // Reset drag started flag
    _dragStarted = false;
    
    if (_maxSlideDuringDrag >= autoDeleteThreshold) {
      // Auto-delete triggered, let the build method handle it
    } else if (currentSlidePx >= halfOpenThreshold) {
      // Snap to buttons fully visible (148px) - if we released at or past 74px
      _snapToButtons();
    } else {
      // Snap closed (0px) - if we released before 74px
      _closeActions();
    }
  }

  void _closeActions() {
    _animationController.animateTo(0.0, curve: Curves.easeOut);
    setState(() {
      _dragExtent = 0.0;
      _maxSlideDuringDrag = 0.0; // Reset max slide when closing
    });
  }

  void _snapToButtons() {
    final buttonFullyVisiblePx = 112.0 + 36.0; // flagStartPx + fadeWindow
    final targetValue = buttonFullyVisiblePx / _maxDrag;
    _animationController.animateTo(targetValue, curve: Curves.easeOut);
    setState(() {
      _dragExtent = -buttonFullyVisiblePx;
    });
  }

  Future<void> _onDeleteTap() async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Briefing'),
        content: Text('Are you sure you want to delete "${widget.briefing.name}"?'),
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
      ),
    );

    if (confirmed == true) {
      // Close actions first, then animate dismiss
      _closeActions();
      // Wait for close animation to complete
      await Future.delayed(const Duration(milliseconds: 250));
      
      // Animate dismiss, then delete
      setState(() {
        _isDismissing = true;
      });
      await _dismissController.forward();
      
      final success = await BriefingStorageService.deleteBriefing(widget.briefing.id);
      if (success) {
        widget.onRefresh?.call();
        _showUndoToast('Briefing deleted');
      }
      
      _dismissController.value = 0.0;
      setState(() {
        _isDismissing = false;
      });
    }
  }

  Future<void> _onFlagTap() async {
    HapticFeedback.mediumImpact();
    
    final success = await BriefingStorageService.toggleFlag(widget.briefing.id);
    if (success) {
      widget.onRefresh?.call();
      _showUndoToast(
        widget.briefing.isFlagged ? 'Unflagged briefing' : 'Flagged briefing',
      );
    }
    _closeActions();
  }

  void _showUndoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width;
    final slide = -_dragExtent;
    final animValue = _animationController.value;
    
    // Calculate button positions and animations
    const hideStartPx = 52.0;
    const flagStartPx = 112.0;
    const sidePadding = 16.0;
    const buttonSpacing = 8.0;
    const buttonSize = 48.0;
    
    final hideAnim = ((slide - hideStartPx) / 36.0).clamp(0.0, 1.0); // 36px fade window
    final flagAnim = ((slide - flagStartPx) / 36.0).clamp(0.0, 1.0);
    final expansionAnim = ((slide - 148.0) / 36.0).clamp(0.0, 1.0); // Expand hide button
    final hideButtonWidth = buttonSize + (expansionAnim * 24.0).clamp(0.0, 24.0);
    
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
                            icon: widget.briefing.isFlagged ? Icons.flag : Icons.outlined_flag,
                            label: widget.briefing.isFlagged ? 'Unflag' : 'Flag',
                            onTap: _onFlagTap,
                            anim: flagAnim,
                            width: buttonSize,
                          ),
                          const SizedBox(width: buttonSpacing),
                          // Delete button (right, expands internally)
                          SizedBox(
                            width: hideButtonWidth,
                            child: _buildAnimatedActionButton(
                              color: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                              onTap: _onDeleteTap,
                              anim: hideAnim,
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
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name, flag, and freshness
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.briefing.name ?? 'Untitled Briefing',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.briefing.isFlagged)
                    const Icon(
                      Icons.flag,
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