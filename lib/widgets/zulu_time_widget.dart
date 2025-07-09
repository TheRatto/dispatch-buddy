import 'package:flutter/material.dart';
import 'dart:async';

class ZuluTimeWidget extends StatefulWidget {
  final bool showIcon;
  final bool compact;
  final double? fontSize;
  
  const ZuluTimeWidget({
    super.key,
    this.showIcon = true,
    this.compact = false,
    this.fontSize,
  });

  @override
  _ZuluTimeWidgetState createState() => _ZuluTimeWidgetState();
}

class _ZuluTimeWidgetState extends State<ZuluTimeWidget> {
  String _currentZuluTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateZuluTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateZuluTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateZuluTime() {
      final now = DateTime.now().toUtc();
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    
      setState(() {
      _currentZuluTime = '$day $hour:$minute Z';
      });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // Compact version for app bar leading - subtle and clean
      return Text(
        _currentZuluTime,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: widget.fontSize ?? 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    
    // Full version for app bar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
          const Icon(Icons.access_time, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          ],
          Text(
            _currentZuluTime,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.fontSize ?? 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
} 