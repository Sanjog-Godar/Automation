import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/attendance_log.dart';

/// Dialog allowing user to enter extra tip details (location note, expected amount, and Upaye toggle).
/// Perfectly mirrors the website's Extra Tip modal, allows tagging whether Upaye provided the tip,
/// and synchronizes seamlessly with the database.
class ExtraTripDialog extends StatefulWidget {
  final AttendanceLog log;
  final String dateTitle;
  final ValueChanged<int>? onSave;
  final void Function(int amount, String? note)? onSaveTip;

  const ExtraTripDialog({
    super.key,
    required this.log,
    required this.dateTitle,
    this.onSave,
    this.onSaveTip,
  });

  static Future<void> show({
    required BuildContext context,
    required AttendanceLog log,
    required String dateTitle,
    ValueChanged<int>? onSave,
    void Function(int amount, String? note)? onSaveTip,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ExtraTripDialog(
        log: log,
        dateTitle: dateTitle,
        onSave: onSave,
        onSaveTip: onSaveTip,
      ),
    );
  }

  /// Decomposes an extra tip note into whether it came from Upaye and the clean location note.
  static ({bool isUpaye, String cleanNote}) parseUpayeNote(String? rawNote) {
    if (rawNote == null || rawNote.trim().isEmpty) {
      return (isUpaye: false, cleanNote: '');
    }
    final trimmed = rawNote.trim();
    final lower = trimmed.toLowerCase();

    // Exact standalone matches
    if (lower == 'upaye' || lower == 'upaya' || trimmed == 'उपाय') {
      return (isUpaye: true, cleanNote: '');
    }

    // Prefixes with delimiters
    const prefixes = [
      'upaye - ',
      'upaya - ',
      'upaye: ',
      'upaya: ',
      'उपाय - ',
      'उपाय: ',
      'upaye ',
      'upaya ',
      'उपाय ',
    ];

    for (final prefix in prefixes) {
      if (lower.startsWith(prefix) || trimmed.startsWith(prefix)) {
        final remainder = trimmed.substring(prefix.length).trim();
        return (isUpaye: true, cleanNote: remainder);
      }
    }

    // Bracketed format: e.g. [Upaye] Kushma or [उपाय] कुश्मा
    if (lower.startsWith('[upaye]') || lower.startsWith('[upaya]') || trimmed.startsWith('[उपाय]')) {
      final closeIdx = trimmed.indexOf(']');
      final remainder = trimmed.substring(closeIdx + 1).trim();
      return (isUpaye: true, cleanNote: remainder);
    }

    return (isUpaye: false, cleanNote: trimmed);
  }

  /// Formats the tip note for database persistence based on the Upaye toggle state.
  static String? formatUpayeNote({
    required bool isUpaye,
    required String? note,
    required bool isNepali,
  }) {
    final clean = note?.trim() ?? '';
    if (!isUpaye) {
      return clean.isNotEmpty ? clean : null;
    }

    final upayeTag = isNepali ? 'उपाय' : 'Upaye';
    if (clean.isEmpty) {
      return upayeTag;
    }
    return '$upayeTag - $clean';
  }

  @override
  State<ExtraTripDialog> createState() => _ExtraTripDialogState();
}

typedef ExtraTipDialog = ExtraTripDialog;

class _ExtraTripDialogState extends State<ExtraTripDialog> {
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;
  late bool _isUpaye;

  @override
  void initState() {
    super.initState();
    final effectiveAmount = widget.log.effectiveTipAmount;
    final parsed = ExtraTripDialog.parseUpayeNote(widget.log.extraTipNote);
    _isUpaye = parsed.isUpaye;
    _noteController = TextEditingController(text: parsed.cleanNote);
    _amountController = TextEditingController(
      text: effectiveAmount > 0 ? effectiveAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final formattedNote = ExtraTripDialog.formatUpayeNote(
      isUpaye: _isUpaye,
      note: _noteController.text,
      isNepali: isNepali,
    );

    if (widget.onSaveTip != null) {
      widget.onSaveTip!(amount, formattedNote);
    } else if (widget.onSave != null) {
      widget.onSave!(amount);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.trip_dialog_title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.dateTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.trip_dialog_subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Location Header Row with "Upaye Ho ?" Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n.trip_dialog_locationLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isUpaye = !_isUpaye;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.trip_dialog_upayeToggle,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 13,
                            fontWeight: _isUpaye ? FontWeight.bold : FontWeight.w600,
                            color: _isUpaye ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch.adaptive(
                            key: const Key('upaye_toggle_switch'),
                            value: _isUpaye,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _isUpaye = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l10n.trip_dialog_locationHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Amount field
            Text(
              l10n.trip_dialog_amountLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
              decoration: InputDecoration(
                hintText: l10n.trip_dialog_amountHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixText: '${l10n.common_currency_rs} ',
                prefixStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.common_cancel,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _handleSubmit,
          child: Text(
            l10n.trip_dialog_save,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
