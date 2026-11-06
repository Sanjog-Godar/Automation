import 'package:flutter/material.dart';
import '../../../core/l10n/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';

/// Modal bottom sheet for entering daily odometer readings (Starting KM and Ending KM).
/// Fully localized with strict single-language rendering.
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
      backgroundColor: AppColors.surface,
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

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    final start = int.tryParse(_startController.text.trim());
    final end = int.tryParse(_endController.text.trim());

    if (start == null || end == null) {
      setState(() {
        _validationError = l10n.km_sheet_validationRequired;
      });
      return;
    }

    if (end < start) {
      setState(() {
        _validationError = l10n.km_sheet_validationEndLessThanStart;
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
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
              Expanded(
                child: Text(
                  '${l10n.km_sheet_title} (${widget.dateTitle})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
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
          Text(
            l10n.km_sheet_startKmLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _startController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.km_sheet_startKmHint,
              suffixText: l10n.common_unit_km,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.km_sheet_endKmLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _endController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.km_sheet_endKmHint,
              suffixText: l10n.common_unit_km,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          if (totalKm != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.km_sheet_totalRun(AppFormatters.formatNumber(totalKm, locale)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_cancel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaving ? null : () => _handleSubmit(l10n),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.km_sheet_saveButton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
