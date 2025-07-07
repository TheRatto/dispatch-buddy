import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'grid_item.dart';
import '../constants/weather_colors.dart';

class TafPeriodCard extends StatelessWidget {
  final TimePeriod period;
  final List<String> timePeriodStrings;
  final List<TimePeriod> allPeriods;

  const TafPeriodCard({
    super.key,
    required this.period,
    required this.timePeriodStrings,
    required this.allPeriods,
  });

  @override
  Widget build(BuildContext context) {
    final isInitial = period.baselinePeriod.type == 'INITIAL';
    final isTempo = period.baselinePeriod.type == 'TEMPO';
    final isInter = period.baselinePeriod.type == 'INTER';
    final isBecmg = period.baselinePeriod.type == 'BECMG';
    final isFm = period.baselinePeriod.type == 'FM';
    
    final weather = period.baselinePeriod.weather;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period.baselinePeriod.type,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: WeatherColors.getColorForPeriodType(period.baselinePeriod.type),
                  ),
                ),
                Text(
                  period.baselinePeriod.time ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridItem(
                  label: 'Wind',
                  value: weather['Wind'],
                  isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Wind'),
                ),
                const SizedBox(width: 16),
                GridItem(
                  label: 'Visibility',
                  value: weather['Visibility'],
                  isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Visibility'),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridItem(
                  label: 'Weather',
                  value: weather['Weather'],
                  isPhenomenaOrRemark: true,
                ),
                const SizedBox(width: 16),
                GridItem(
                  label: 'Cloud',
                  value: weather['Cloud'],
                  isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Cloud'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 