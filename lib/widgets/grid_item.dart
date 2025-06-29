import 'package:flutter/material.dart';

class GridItem extends StatelessWidget {
  final String label;
  final String? value;
  final bool isPhenomenaOrRemark;

  const GridItem({
    Key? key,
    required this.label,
    this.value,
    this.isPhenomenaOrRemark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayValue = value ?? '-';
    if (isPhenomenaOrRemark) {
      if (value == null || value!.isEmpty || value == 'No significant weather') {
        displayValue = '-';
      }
    } else {
      if (value == null || value!.isEmpty || value!.contains('unavailable') || value!.contains('No cloud information')) {
        displayValue = '-'; // Show - instead of N/A to match weather heading
      }
    }
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 