import 'package:flutter/material.dart';
import 'dart:async';

class ZuluTimeWidget extends StatefulWidget {
  const ZuluTimeWidget({Key? key}) : super(key: key);

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
    if (mounted) {
      final now = DateTime.now().toUtc();
      setState(() {
        _currentZuluTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}Z';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            _currentZuluTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
} 