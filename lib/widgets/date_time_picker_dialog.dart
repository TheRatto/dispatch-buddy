import 'package:flutter/material.dart';

class DateTimePickerDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final bool isZuluTime;

  const DateTimePickerDialog({
    super.key,
    required this.initialDateTime,
    required this.isZuluTime,
  });

  @override
  _DateTimePickerDialogState createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late DateTime _selectedDateTime;
  late bool _isZuluTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _isZuluTime = widget.isZuluTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 500;

              final content = isWide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTitle(),
                              const SizedBox(height: 12),
                              _buildTimeFormatToggle(),
                              const SizedBox(height: 12),
                              _buildDatePickerWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 60),
                              _buildTimePickerWidget(),
                              const SizedBox(height: 12),
                              _buildPreview(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildTimeFormatToggle(),
                        const SizedBox(height: 12),
                        _buildDatePickerWidget(),
                        const SizedBox(height: 12),
                        _buildTimePickerWidget(),
                        const SizedBox(height: 16),
                        _buildPreview(),
                        const SizedBox(height: 12),
                        _buildConfirmButton(),
                      ],
                    );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  if (isWide) ...[
                    const SizedBox(height: 12),
                    _buildConfirmButton(),
                  ]
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Row(
      children: [
        Icon(Icons.schedule, color: Color(0xFF1E3A8A)),
        SizedBox(width: 12),
        Text(
          'Select ETD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFormatToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Time Format:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton('Local', !_isZuluTime, () {
                setState(() => _isZuluTime = false);
              }),
              _buildToggleButton('Zulu', _isZuluTime, () {
                setState(() => _isZuluTime = true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerWidget() {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260, // Reduced height
            child: CalendarDatePicker(
              initialDate: _selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    _selectedDateTime.hour,
                    _selectedDateTime.minute,
                  );
                });
              },
              selectableDayPredicate: (date) =>
                  date.isAfter(DateTime.now().subtract(const Duration(days: 1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerWidget() {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100, // Reduced height
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(
                      initialItem: 1000 + _selectedDateTime.hour,
                    ),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2000,
                      builder: (context, index) {
                        final hour = index % 24;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final hour = index % 24;
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          hour,
                          _selectedDateTime.minute,
                        );
                      });
                    },
                  ),
                ),
                const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(
                      initialItem: 1000 + _selectedDateTime.minute,
                    ),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2000,
                      builder: (context, index) {
                        final minute = index % 60;
                        return Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final minute = index % 60;
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          _selectedDateTime.hour,
                          minute,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Preview',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 4),
          Text(
            _isZuluTime
                ? _formatZuluTime(_selectedDateTime)
                : _formatLocalTime(_selectedDateTime),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            _isZuluTime
                ? 'Local: ${_formatLocalTime(_selectedDateTime)}'
                : 'Zulu: ${_formatZuluTime(_selectedDateTime)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDateTime),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatLocalTime(DateTime dateTime) {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time (Local)';
  }

  String _formatZuluTime(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    final date = '${utcTime.day.toString().padLeft(2, '0')}/${utcTime.month.toString().padLeft(2, '0')}/${utcTime.year}';
    final time = '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}';
    return '$date at ${time}Z';
  }
} 