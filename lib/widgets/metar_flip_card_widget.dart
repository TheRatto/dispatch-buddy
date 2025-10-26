import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/weather.dart';
import 'raw_metar_card.dart';
import 'decoded_metar_card.dart';

class MetarFlipCardWidget extends StatefulWidget {
  final Weather metar;
  final String icao;

  const MetarFlipCardWidget({
    super.key,
    required this.metar,
    required this.icao,
  });

  @override
  State<MetarFlipCardWidget> createState() => _MetarFlipCardWidgetState();
}

class _MetarFlipCardWidgetState extends State<MetarFlipCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isShowingRaw = true;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: MetarFlipCardWidget initState for ${widget.metar.icao}');
    
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
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
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
    debugPrint('DEBUG: MetarFlipCardWidget build for ${widget.icao} - showing ${_isShowingRaw ? 'raw' : 'decoded'}');
    
    return SizedBox(
      height: 320, // Same height as TAF flip card for consistency
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
                // Raw METAR Card (back face)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(rotationY), // Rotate based on animation
                  child: showRawCard ? RawMetarCard(
                    metar: widget.metar,
                    icao: widget.icao,
                  ) : const SizedBox.shrink(),
                ),
                // Decoded METAR Card (front face)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(rotationY + 3.14159), // Rotate 180° more than raw card
                  child: !showRawCard ? DecodedMetarCard(
                    metar: widget.metar,
                    icao: widget.icao,
                  ) : const SizedBox.shrink(),
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
