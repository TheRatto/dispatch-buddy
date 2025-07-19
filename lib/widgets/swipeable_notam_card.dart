import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notam.dart';
import '../services/notam_status_service.dart';

/// Swipeable NOTAM card with Apple Mail-style hide/flag actions
class SwipeableNotamCard extends StatefulWidget {
  final Notam notam;
  final Widget child;
  final String? flightContext;
  final VoidCallback? onNotamTap;
  final VoidCallback? onStatusChanged;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeEnd;
  final bool shouldClose;

  const SwipeableNotamCard({
    super.key,
    required this.notam,
    required this.child,
    this.flightContext,
    this.onNotamTap,
    this.onStatusChanged,
    this.onSwipeStart,
    this.onSwipeEnd,
    this.shouldClose = false,
  });

  @override
  State<SwipeableNotamCard> createState() => _SwipeableNotamCardState();
}

class _SwipeableNotamCardState extends State<SwipeableNotamCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dismissController;
  double _dragExtent = 0.0;
  double _maxSlideDuringDrag = 0.0;
  final NotamStatusService _statusService = NotamStatusService();
  bool _isHidden = false;
  bool _isFlagged = false;
  bool _isDismissing = false;
  bool _autoHideTriggered = false;
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
    _loadNotamStatus();
  }

  @override
  void didUpdateWidget(covariant SwipeableNotamCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('DEBUG: didUpdateWidget - shouldClose: ${widget.shouldClose}, oldShouldClose: ${oldWidget.shouldClose}');
    if (widget.shouldClose && !oldWidget.shouldClose) {
      debugPrint('DEBUG: shouldClose triggered for NOTAM ${widget.notam.id}');
      _closeActions();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  Future<void> _loadNotamStatus() async {
    final status = await _statusService.getStatus(widget.notam.id);
    if (mounted) {
      setState(() {
        _isHidden = status?.isHidden ?? false;
        _isFlagged = status?.isFlagged ?? false;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final newDragExtent = (_dragExtent + details.delta.dx).clamp(-_maxDrag, 0.0);
    final newAnimationValue = -newDragExtent / _maxDrag;
    final slidePx = -newDragExtent; // Use actual slide position
    debugPrint('DEBUG: Drag update - delta: ${details.delta.dx}, oldExtent: $_dragExtent, newExtent: $newDragExtent, animValue: $newAnimationValue, slidePx: $slidePx');
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
        _autoHideTriggered = false;
        _maxSlideDuringDrag = 0.0; // Reset max slide when starting new drag
        // Notify parent that this NOTAM is being swiped
        widget.onSwipeStart?.call();
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) async {
    final cardWidth = MediaQuery.of(context).size.width;
    final currentSlidePx = -_dragExtent; // Use actual drag extent
    final halfOpenThreshold = 74.0; // Threshold for snap decisions
    final buttonFullyVisiblePx = 112.0 + 36.0; // flagStartPx + fadeWindow = 148px
    final autoHideThreshold = cardWidth * 0.8;
    
    debugPrint('DEBUG: Drag ended - current slidePx=$currentSlidePx, max slide during drag=$_maxSlideDuringDrag');
    
    // Notify parent that swipe ended
    widget.onSwipeEnd?.call();
    
    // Reset drag started flag
    _dragStarted = false;
    
    if (_maxSlideDuringDrag >= autoHideThreshold) {
      // Auto-hide triggered, let the build method handle it
      debugPrint('DEBUG: Drag ended at auto-hide threshold, maxSlide=$_maxSlideDuringDrag');
    } else if (currentSlidePx >= halfOpenThreshold) {
      // Snap to buttons fully visible (148px) - if we released at or past 74px
      debugPrint('DEBUG: Snap to buttons, currentSlidePx=$currentSlidePx');
      _snapToButtons();
    } else {
      // Snap closed (0px) - if we released before 74px
      debugPrint('DEBUG: Snap closed, currentSlidePx=$currentSlidePx');
      _closeActions();
    }
  }

  void _closeActions() {
    debugPrint('DEBUG: _closeActions called for NOTAM ${widget.notam.id}');
    _animationController.animateTo(0.0, curve: Curves.easeOut);
    setState(() {
      _dragExtent = 0.0;
      _maxSlideDuringDrag = 0.0; // Reset max slide when closing
    });
    debugPrint('DEBUG: Card closed - dragExtent=0.0, slide=0.0');
  }

  void _snapToButtons() {
    final buttonFullyVisiblePx = 112.0 + 36.0; // flagStartPx + fadeWindow
    final targetValue = buttonFullyVisiblePx / _maxDrag;
    debugPrint('DEBUG: _snapToButtons - buttonFullyVisiblePx=$buttonFullyVisiblePx, targetValue=$targetValue');
    _animationController.animateTo(targetValue, curve: Curves.easeOut);
    setState(() {
      _dragExtent = -buttonFullyVisiblePx;
    });
    debugPrint('DEBUG: Snapped to buttons - dragExtent=$_dragExtent, slide=$buttonFullyVisiblePx');
  }

  Future<void> _onHideTap() async {
    HapticFeedback.mediumImpact();
    // Close actions first, then animate dismiss
    _closeActions();
    // Wait for close animation to complete
    await Future.delayed(const Duration(milliseconds: 250));
    
    // Animate dismiss, then hide
    setState(() {
      _isDismissing = true;
    });
    await _dismissController.forward();
    await _statusService.hideNotam(widget.notam.id, flightContext: widget.flightContext);
    await _loadNotamStatus();
    widget.onStatusChanged?.call();
    _dismissController.value = 0.0;
    setState(() {
      _isDismissing = false;
    });
    _showUndoToast('NOTAM hidden');
  }

  Future<void> _onFlagTap() async {
    HapticFeedback.mediumImpact();
    if (_isFlagged) {
      await _statusService.unflagNotam(widget.notam.id);
    } else {
      await _statusService.flagNotam(widget.notam.id, flightContext: widget.flightContext);
    }
    await _loadNotamStatus();
    widget.onStatusChanged?.call();
    _closeActions();
    _showUndoToast(_isFlagged ? 'NOTAM unflagged' : 'NOTAM flagged');
  }

  void _showUndoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width;
    final slide = -_dragExtent; // Use actual drag extent, not animation value
    final showActions = slide > 1.0; // Show actions when slide is more than 1px
    final progress = slide / _maxDrag; // Calculate progress based on actual slide
    // Button geometry
    const double buttonSize = 48.0;
    const double buttonSpacing = 12.0;
    const double sidePadding = 4.0;
    const double fadeWindow = 36.0;
    const double hideButtonMaxWidth = 120.0;
    final slidePx = -_dragExtent; // Use actual drag extent for consistency
    // Button reveal thresholds
    final hideStartPx = buttonSize + sidePadding; // when hide button starts to appear
    final flagStartPx = hideStartPx + buttonSpacing + buttonSize; // when flag button starts to appear
    // Hide button reveal: fade/scale in over fadeWindow after hideStartPx
    final hideAnim = ((slidePx - hideStartPx) / fadeWindow).clamp(0.0, 1.0);
    // Flag button reveal: fade/scale in over fadeWindow after flagStartPx
    final flagAnim = ((slidePx - flagStartPx) / fadeWindow).clamp(0.0, 1.0);
    // Hide button expansion: starts after both buttons are fully visible
    final expansionStartPx = flagStartPx + fadeWindow;
    final expansionEndPx = cardWidth * 0.8; // Use card width for consistent 80% threshold
    double hideButtonWidth = buttonSize;
    double expansionAnim = 0.0;
    if (slidePx > expansionStartPx) {
      expansionAnim = ((slidePx - expansionStartPx) / (expansionEndPx - expansionStartPx)).clamp(0.0, 1.0);
      hideButtonWidth = buttonSize + (hideButtonMaxWidth - buttonSize) * expansionAnim;
    }
    // Card overlay: fade to grey as you swipe
    final overlayOpacity = (progress * 0.5).clamp(0.0, 0.5);
    // Auto-hide at 80% of card width
    final autoHideThreshold = cardWidth * 0.8;
    if (!_isDismissing && slidePx >= autoHideThreshold && !_autoHideTriggered) {
      debugPrint('DEBUG: Auto-hide triggered at slidePx=$slidePx (threshold: $autoHideThreshold)');
      _autoHideTriggered = true;
      _onHideTap();
    }
    debugPrint('DEBUG: slidePx=$slidePx, cardWidth=$cardWidth, hideStartPx=$hideStartPx, flagStartPx=$flagStartPx, hideAnim=$hideAnim, flagAnim=$flagAnim, expansionAnim=$expansionAnim, hideButtonWidth=$hideButtonWidth');
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
                            icon: _isFlagged ? Icons.flag : Icons.outlined_flag,
                            label: _isFlagged ? 'Unflag' : 'Flag',
                            onTap: _onFlagTap,
                            anim: flagAnim,
                            width: buttonSize,
                          ),
                          const SizedBox(width: buttonSpacing),
                          // Hide button (right, expands internally)
                          SizedBox(
                            width: hideButtonWidth,
                            child: _buildAnimatedActionButton(
                              color: Colors.orange,
                              icon: Icons.visibility_off,
                              label: 'Hide',
                              onTap: _onHideTap,
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
                            child: widget.child,
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
    return AnimatedOpacity(
      opacity: anim,
      duration: const Duration(milliseconds: 100),
      child: Transform.scale(
        scale: 0.7 + 0.3 * anim, // scale from 0.7 to 1.0
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