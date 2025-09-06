import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notam.dart';

/// Reusable widget for displaying detailed NOTAM information
/// Used in Raw Data screen and Facilities modal
class NotamDetailWidget extends StatelessWidget {
  final Notam notam;
  final String? title;

  const NotamDetailWidget({
    super.key,
    required this.notam,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with NOTAM ID and category badge
          Row(
            children: [
              Expanded(
                child: Text(
                  title ?? 'NOTAM ${notam.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(notam.group),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCategoryLabel(notam.group),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Basic Information Grid
          _buildInfoGrid(context),
          const SizedBox(height: 16),

          // Validity Period
          _buildValidityPeriod(context),
          const SizedBox(height: 16),

          // NOTAM Text (Main Content) - Field E + Altitude Info (Fields F & G)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main NOTAM text (Field E)
                Text(
                  notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                // Altitude information (Fields F & G) - only show if present
                if (notam.fieldF.isNotEmpty || notam.fieldG.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatAltitudeInfo(notam.fieldF, notam.fieldG),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Raw NOTAM Data
          _buildRawNotamData(context),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildInfoRow('ICAO', notam.icao),
          _buildInfoRow('Type', notam.type.toString().split('.').last.toUpperCase()),
          _buildInfoRow('Group', notam.group.toString().split('.').last.toUpperCase()),
          if (notam.qCode != null && notam.qCode!.isNotEmpty)
            _buildInfoRow('Q-Code', notam.qCode!),
          _buildInfoRow('Critical', notam.isCritical ? 'Yes' : 'No'),
          _buildInfoRow('Permanent', notam.isPermanent ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidityPeriod(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validity Period',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          _buildValidityRow('From', _formatDateTime(notam.validFrom)),
          _buildValidityRow('To', _formatDateTime(notam.validTo)),
          if (notam.isPermanent) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PERMANENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawNotamData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Raw NOTAM Data',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: SelectableText(
            notam.rawText,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: notam.rawText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('NOTAM copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy NOTAM'),
          ),
        ),
        const SizedBox(width: 8),
        if (notam.qCode != null && notam.qCode!.isNotEmpty)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: notam.qCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Q-Code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Q-Code'),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}Z';
  }

  String _formatAltitudeInfo(String fieldF, String fieldG) {
    final parts = <String>[];
    if (fieldF.isNotEmpty) parts.add('F: $fieldF');
    if (fieldG.isNotEmpty) parts.add('G: $fieldG');
    return parts.join(' | ');
  }

  Color _getCategoryColor(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return const Color(0xFFEF4444); // Red for runways
      case NotamGroup.taxiways:
        return const Color(0xFFF59E0B); // Amber for taxiways
      case NotamGroup.instrumentProcedures:
        return const Color(0xFF8B5CF6); // Purple for procedures
      case NotamGroup.airportServices:
        return const Color(0xFF3B82F6); // Blue for services
      case NotamGroup.lighting:
        return const Color(0xFFEAB308); // Yellow for lighting
      case NotamGroup.hazards:
        return const Color(0xFFF59E0B); // Amber for hazards
      case NotamGroup.admin:
        return const Color(0xFF6B7280); // Gray for admin
      case NotamGroup.other:
        return const Color(0xFF10B981); // Green for other
    }
  }

  String _getCategoryLabel(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return 'RWY';
      case NotamGroup.taxiways:
        return 'TWY';
      case NotamGroup.instrumentProcedures:
        return 'PROC';
      case NotamGroup.airportServices:
        return 'SVC';
      case NotamGroup.lighting:
        return 'LGT';
      case NotamGroup.hazards:
        return 'HAZ';
      case NotamGroup.admin:
        return 'ADM';
      case NotamGroup.other:
        return 'OTH';
    }
  }
}
