import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_log.dart';

/// Dialog allowing driver to enter extra trip earnings for a day.
class ExtraTripDialog extends StatefulWidget {
  final AttendanceLog log;
  final String dateTitle;
  final ValueChanged<int> onSave;

  const ExtraTripDialog({
    super.key,
    required this.log,
    required this.dateTitle,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceLog log,
    required String dateTitle,
    required ValueChanged<int> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ExtraTripDialog(
        log: log,
        dateTitle: dateTitle,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ExtraTripDialog> createState() => _ExtraTripDialogState();
}

class _ExtraTripDialogState extends State<ExtraTripDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.log.extraTripIncome > 0 ? widget.log.extraTripIncome.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final amount = int.tryParse(_controller.text.trim()) ?? 0;
    widget.onSave(amount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Extra Trip Income (${widget.dateTitle})'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'e.g. 500',
          prefixText: 'Rs. ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _handleSubmit,
          child: const Text('Save Extra Trip'),
        ),
      ],
    );
  }
}

