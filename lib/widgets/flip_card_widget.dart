import 'package:flutter/material.dart';
import 'dart:async';
import '../models/decoded_weather_models.dart';
import '../models/weather.dart';
import '../services/taf_state_manager.dart';
import 'raw_taf_card.dart';
import 'decoded_weather_card.dart';

/// FlipCardWidget - A card that flips between raw TAF data and decoded weather view
/// 
/// Features:
/// - Smooth 3D flip animation
/// - Stylish flip button in top-right corner
/// - Default view shows raw data
/// - Slider functionality preserved for both views
/// - Space-efficient design for non-max iPhones
class FlipCardWidget extends StatefulWidget {
  final Weather taf;
  final Map<String, dynamic>? activePeriods;
  final DecodedForecastPeriod? baseline;
  final Map<String, String>? completeWeather;
  final List<DecodedForecastPeriod>? concurrentPeriods;
  final TafStateManager? tafStateManager;
  final String? airport;
  final double? sliderValue;
  final List<DecodedForecastPeriod>? allPeriods;
  final List<DateTime>? timeline;

  const FlipCardWidget({
    super.key,
    required this.taf,
    this.activePeriods,
    this.baseline,
    this.completeWeather,
    this.concurrentPeriods,
    this.tafStateManager,
    this.airport,
    this.sliderValue,
    this.allPeriods,
    this.timeline,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isShowingRaw = true; // Default to raw data view
  Timer? _ageUpdateTimer;
  String _ageText = '';

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: FlipCardWidget initState for ${widget.taf.icao}');
    
    // Initialize animation controller
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    // Create flip animation with smooth easing
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic, // More pronounced easing for better flip effect
    ));
    
    _updateAgeText();
    // Update age every minute
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAgeText();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateAgeText() {
    if (!mounted) return;
    
    // Extract issue time from TAF raw text
    final issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z').firstMatch(widget.taf.rawText);
    if (issueTimeMatch == null) {
      setState(() {
        _ageText = '';
      });
      return;
    }
    
    final day = int.parse(issueTimeMatch.group(1)!);
    final hour = int.parse(issueTimeMatch.group(2)!);
    final minute = int.parse(issueTimeMatch.group(3)!);
    
    // Create issue time with proper date handling
    final now = DateTime.now().toUtc();
    DateTime issueTime;
    
    // Try current day first
    issueTime = DateTime.utc(now.year, now.month, day, hour, minute);
    
    // If issue time is in the future, it must be from yesterday
    if (issueTime.isAfter(now)) {
      final yesterday = now.subtract(const Duration(days: 1));
      issueTime = DateTime.utc(yesterday.year, yesterday.month, day, hour, minute);
    }
    
    // Recalculate age with the correct date
    final finalAge = now.difference(issueTime);
    final hours = finalAge.inHours;
    final minutes = finalAge.inMinutes % 60;
    
    String ageText;
    if (hours > 0) {
      ageText = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} hrs old';
    } else {
      ageText = '${minutes.toString().padLeft(2, '0')} mins old';
    }
    
    setState(() {
      _ageText = ageText;
    });
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    
    setState(() {
      _isShowingRaw = !_isShowingRaw;
    });
    
    if (_isShowingRaw) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: FlipCardWidget build for ${widget.taf.icao} - showing ${_isShowingRaw ? 'raw' : 'decoded'}');
    
    return SizedBox(
      height: 320, // Increased from 290 to match decoded card height
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          // Calculate rotation angle based on animation progress
          final rotationY = _flipAnimation.value * 3.14159; // 0 to π radians (0° to 180°)
          
          // Determine which card to show based on rotation angle
          // Switch content at 90° (π/2 radians) - halfway through the flip
          final showRawCard = rotationY < 1.5708; // π/2 radians = 90°
          
          // Add subtle scale effect during flip (slightly smaller at 90° rotation)
          final scale = 1.0 - (0.1 * (1 - (rotationY - 1.5708).abs() / 1.5708).clamp(0.0, 1.0));
          
          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                // Raw TAF Card (back face)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(rotationY), // Rotate based on animation
                  child: showRawCard ? _buildRawCard() : const SizedBox.shrink(),
                ),
                // Decoded Weather Card (front face)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(rotationY + 3.14159), // Rotate 180° more than raw card
                  child: !showRawCard ? _buildDecodedCard() : const SizedBox.shrink(),
                ),
                // Flip button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildFlipButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRawCard() {
    return SizedBox(
      height: 320, // Increased from 290 to match decoded card height
      child: RawTafCard(
        key: ValueKey('raw_${widget.taf.icao}'),
        taf: widget.taf,
        activePeriods: widget.activePeriods,
      ),
    );
  }

  Widget _buildDecodedCard() {
    if (widget.baseline == null || widget.completeWeather == null) {
      return SizedBox(
        height: 320, // Increased from 290 to match decoded card height
        child: _buildEmptyDecodedCard(),
      );
    }
    
    return SizedBox(
      height: 320, // Increased from 290 to match decoded card height
      child: DecodedWeatherCard(
        key: ValueKey('decoded_${widget.taf.icao}'),
        baseline: widget.baseline!,
        completeWeather: widget.completeWeather!,
        concurrentPeriods: widget.concurrentPeriods ?? [],
        tafStateManager: widget.tafStateManager,
        airport: widget.airport,
        sliderValue: widget.sliderValue,
        allPeriods: widget.allPeriods,
        taf: widget.taf,
        timeline: widget.timeline,
      ),
    );
  }

  Widget _buildEmptyDecodedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with TAF age indicator in top left
            Row(
              children: [
                if (_ageText.isNotEmpty)
                  Text(
                    _ageText,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  'No decoded data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _flipCard,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isShowingRaw ? Icons.visibility : Icons.code,
            size: 18,
            color: Colors.blue[600],
          ),
        ),
      ),
    );
  }
}
