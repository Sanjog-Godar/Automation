import 'package:flutter/material.dart';
import '../models/attendance_log.dart';

/// Modal bottom sheet for entering daily odometer readings (Starting KM and Ending KM).
class KmBottomSheet extends StatefulWidget {
  final AttendanceLog log;
  final String dateTitle;
  final Future<void> Function(int startKm, int endKm) onSave;

  const KmBottomSheet({
    super.key,
    required this.log,
    required this.dateTitle,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceLog log,
    required String dateTitle,
    required Future<void> Function(int startKm, int endKm) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => KmBottomSheet(
        log: log,
        dateTitle: dateTitle,
        onSave: onSave,
      ),
    );
  }

  @override
  State<KmBottomSheet> createState() => _KmBottomSheetState();
}

class _KmBottomSheetState extends State<KmBottomSheet> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text: widget.log.kmStart != null ? widget.log.kmStart.toString() : '',
    );
    _endController = TextEditingController(
      text: widget.log.kmEnd != null ? widget.log.kmEnd.toString() : '',
    );

    _startController.addListener(_onKmChanged);
    _endController.addListener(_onKmChanged);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onKmChanged() {
    setState(() {
      _validationError = null;
    });
  }

  int? get _computedTotalKm {
    final start = int.tryParse(_startController.text.trim());
    final end = int.tryParse(_endController.text.trim());
    if (start != null && end != null && end >= start) {
      return end - start;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final start = int.tryParse(_startController.text.trim());
    final end = int.tryParse(_endController.text.trim());

    if (start == null || end == null) {
      setState(() {
        _validationError = 'Please enter both Starting and Ending KM readings';
      });
      return;
    }

    if (end < start) {
      setState(() {
        _validationError = 'Ending KM cannot be less than Starting KM';
      });
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(start, end);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalKm = _computedTotalKm;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily KM (${widget.dateTitle})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_validationError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _validationError!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Starting KM',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _startController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. 12300',
              suffixText: 'km',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ending KM',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _endController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 12350',
              suffixText: 'km',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          if (totalKm != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF), // purple-100
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total KM: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$totalKm km',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7E22CE), // purple-700
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA), // purple-600
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaving ? null : _handleSubmit,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save KM'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
