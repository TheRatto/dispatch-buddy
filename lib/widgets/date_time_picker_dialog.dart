import 'package:flutter/material.dart';

class DateTimePickerDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final bool isZuluTime;

  const DateTimePickerDialog({
    Key? key,
    required this.initialDateTime,
    required this.isZuluTime,
  }) : super(key: key);

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
          padding: EdgeInsets.all(12), // Reduced padding
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
                              SizedBox(height: 12),
                              _buildTimeFormatToggle(),
                              SizedBox(height: 12),
                              _buildDatePickerWidget(),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 60),
                              _buildTimePickerWidget(),
                              SizedBox(height: 12),
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
                        SizedBox(height: 12),
                        _buildTimeFormatToggle(),
                        SizedBox(height: 12),
                        _buildDatePickerWidget(),
                        SizedBox(height: 12),
                        _buildTimePickerWidget(),
                        SizedBox(height: 16),
                        _buildPreview(),
                        SizedBox(height: 12),
                        _buildConfirmButton(),
                      ],
                    );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  if (isWide) ...[
                    SizedBox(height: 12),
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
    return Row(
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
        Text(
          'Time Format:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 12),
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
      padding: EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 260, // Reduced height
            child: CalendarDatePicker(
              initialDate: _selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
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
                  date.isAfter(DateTime.now().subtract(Duration(days: 1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerWidget() {
    return Container(
      padding: EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 100, // Reduced height
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: FixedExtentScrollPhysics(),
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: FixedExtentScrollPhysics(),
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1E3A8A).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Preview',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
          ),
          SizedBox(height: 4),
          Text(
            _isZuluTime
                ? _formatZuluTime(_selectedDateTime)
                : _formatLocalTime(_selectedDateTime),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
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
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDateTime),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E3A8A) : Colors.transparent,
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