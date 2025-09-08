import 'package:flutter/material.dart';

/// Airport Pill Widget
/// 
/// Reusable airport selection pill using existing TAF selector styling.
/// Displays ICAO code with selected/unselected states.
class AirportPillWidget extends StatelessWidget {
  final String icao;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanUpdate;
  final VoidCallback? onPanEnd;

  const AirportPillWidget({
    super.key,
    required this.icao,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      onPanStart: isDisabled ? null : (_) => onPanStart?.call(),
      onPanUpdate: isDisabled ? null : (_) => onPanUpdate?.call(),
      onPanEnd: isDisabled ? null : (_) => onPanEnd?.call(),
      child: Container(
        width: 60, // Fixed width for consistent grid layout
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            icao,
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isDisabled) {
      return Colors.grey[400]!;
    }
    return isSelected ? const Color(0xFFF97316) : const Color(0xFFE0F2FE); // Light blue
  }

  Color _getBorderColor() {
    if (isDisabled) {
      return Colors.grey[400]!;
    }
    return isSelected ? const Color(0xFFF97316) : const Color(0xFF1E3A8A); // Blue border
  }

  Color _getTextColor() {
    if (isDisabled) {
      return Colors.grey[600]!;
    }
    return isSelected ? Colors.white : const Color(0xFF1E3A8A); // Blue text
  }
}
