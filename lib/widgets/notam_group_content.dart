import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_status_service.dart';
import 'swipeable_notam_card.dart';

class NotamGroupContent extends StatelessWidget {
  final List<Notam> notams;
  final NotamGroup group;
  final Function(Notam)? onNotamTap;
  final String? flightContext;
  final VoidCallback? onStatusChanged;
  final Function(String)? onSwipeStart;
  final VoidCallback? onSwipeEnd;
  final String? currentlySwipedNotamId;

  const NotamGroupContent({
    super.key,
    required this.notams,
    required this.group,
    this.onNotamTap,
    this.flightContext,
    this.onStatusChanged,
    this.onSwipeStart,
    this.onSwipeEnd,
    this.currentlySwipedNotamId,
  });

  @override
  Widget build(BuildContext context) {
    if (notams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: notams.map((notam) => _buildNotamItem(context, notam)).toList(),
      ),
    );
  }

  Widget _buildNotamItem(BuildContext context, Notam notam) {
    final shouldClose = currentlySwipedNotamId != null && currentlySwipedNotamId != notam.id;
    debugPrint('DEBUG: _buildNotamItem - NOTAM ${notam.id}, currentlySwipedNotamId: $currentlySwipedNotamId, shouldClose: $shouldClose');
    return SwipeableNotamCard(
      notam: notam,
      flightContext: flightContext,
      onNotamTap: () => onNotamTap?.call(notam),
      onStatusChanged: onStatusChanged,
      onSwipeStart: () => onSwipeStart?.call(notam.id),
      onSwipeEnd: onSwipeEnd,
      shouldClose: shouldClose,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildNotamIcon(notam),
          title: _buildNotamTitle(notam),
          subtitle: _buildNotamSubtitle(notam),
          trailing: _buildNotamTrailing(notam),
          onTap: () => onNotamTap?.call(notam),
        ),
      ),
    );
  }

  Widget _buildNotamIcon(Notam notam) {
    IconData iconData;
    Color iconColor;

    // Determine icon based on NOTAM type
    switch (notam.type) {
      case NotamType.runway:
        iconData = Icons.airplanemode_active;
        iconColor = Colors.blue;
        break;
      case NotamType.navaid:
        iconData = Icons.radar;
        iconColor = Colors.purple;
        break;
      case NotamType.taxiway:
        iconData = Icons.directions_car;
        iconColor = Colors.green;
        break;
      case NotamType.lighting:
        iconData = Icons.lightbulb;
        iconColor = Colors.yellow.shade700;
        break;
      case NotamType.procedure:
        iconData = Icons.flight_takeoff;
        iconColor = Colors.orange;
        break;
      case NotamType.airspace:
        iconData = Icons.space_bar;
        iconColor = Colors.indigo;
        break;
      case NotamType.other:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 16,
      ),
    );
  }

  Widget _buildNotamTitle(Notam notam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                notam.id,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            // Flag indicator
            FutureBuilder<NotamStatus?>(
              future: NotamStatusService().getStatus(notam.id),
              builder: (context, snapshot) {
                final isFlagged = snapshot.data?.isFlagged ?? false;
                if (!isFlagged) return const SizedBox.shrink();
                
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.flag,
                    color: Colors.blue,
                    size: 14,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          notam.icao,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildNotamSubtitle(Notam notam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notam.decodedText != null && notam.decodedText!.isNotEmpty)
          Text(
            notam.decodedText!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          )
        else if (notam.rawText != null && notam.rawText!.isNotEmpty)
          Text(
            notam.displayRawText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 6),
        _buildTimeRange(notam),
      ],
    );
  }

  Widget _buildTimeRange(Notam notam) {
    final now = DateTime.now().toUtc();
    final validFrom = notam.validFrom;
    final validTo = notam.validTo;

    if (validFrom == null || validTo == null) {
      return const SizedBox.shrink();
    }

    // Check if NOTAM is currently active
    final isActive = now.isAfter(validFrom) && now.isBefore(validTo);
    final isFuture = now.isBefore(validFrom);
    final isExpired = now.isAfter(validTo);

    if (isActive) {
      // Active NOTAM - show "Active" on left (amber) and "Ends in..." on right (green)
      return Row(
        children: [
          Text(
            'Active',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Ends in ${_formatTimeDifference(validTo, now)}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (isFuture) {
      // Future NOTAM - show "Starts in..." on left and "Ends in..." on right
      return Row(
        children: [
          Text(
            'Starts in ${_formatTimeDifference(validFrom, now)}',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Ends in ${_formatTimeDifference(validTo, now)}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Expired NOTAM - show "Expired..." on the left
      return Row(
        children: [
          Text(
            'Expired ${_formatTimeDifference(now, validTo)} ago',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildNotamTrailing(Notam notam) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getGroupColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getGroupShortName(),
            style: TextStyle(
              color: _getGroupColor(),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 16,
        ),
      ],
    );
  }

  String _getGroupShortName() {
    switch (group) {
      case NotamGroup.runways:
        return 'RWY';
      case NotamGroup.taxiways:
        return 'TWY';
      case NotamGroup.instrumentProcedures:
        return 'PROC';
      case NotamGroup.airportServices:
        return 'SERV';
      case NotamGroup.hazards:
        return 'HAZ';
      case NotamGroup.admin:
        return 'ADM';
      case NotamGroup.other:
        return 'OTH';
    }
  }

  Color _getGroupColor() {
    switch (group) {
      case NotamGroup.runways:
        return Colors.blue;
      case NotamGroup.taxiways:
        return Colors.green;
      case NotamGroup.instrumentProcedures:
        return Colors.purple;
      case NotamGroup.airportServices:
        return Colors.orange;
      case NotamGroup.hazards:
        return Colors.red;
      case NotamGroup.admin:
        return Colors.teal;
      case NotamGroup.other:
        return Colors.grey;
    }
  }

  String _formatTimeDifference(DateTime later, DateTime earlier) {
    final difference = later.difference(earlier);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
} 