import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/utils/nepal_clock.dart';
import '../../../core/utils/nepali_calendar_helper.dart';
import '../models/attendance_log.dart';
import '../models/monthly_summary.dart';
import '../repositories/attendance_repository.dart';

/// State representation for monthly attendance dashboard.
class AttendanceState {
  final int currentYear;
  final int currentMonthIndex; // 0-based: 0 (Baisakh) to 11 (Chaitra)
  final List<AttendanceLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> savingDates;

  const AttendanceState({
    required this.currentYear,
    required this.currentMonthIndex,
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.savingDates = const {},
  });

  bool isSaving(String logDate) => savingDates.contains(logDate);

  MonthlySummary get summary => MonthlySummary.calculate(logs);

  AttendanceLog? findByDate(String logDate) {
    for (final log in logs) {
      if (log.logDate == logDate) return log;
    }
    return null;
  }

  AttendanceState copyWith({
    int? currentYear,
    int? currentMonthIndex,
    List<AttendanceLog>? logs,
    bool? isLoading,
    String? errorMessage,
    Set<String>? savingDates,
  }) {
    return AttendanceState(
      currentYear: currentYear ?? this.currentYear,
      currentMonthIndex: currentMonthIndex ?? this.currentMonthIndex,
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      savingDates: savingDates ?? this.savingDates,
    );
  }
}

final attendanceControllerProvider =
    NotifierProvider<AttendanceController, AttendanceState>(AttendanceController.new);

/// Riverpod controller managing attendance state, optimistic mutations,
/// single-date rollback, and BS month transitions.
class AttendanceController extends Notifier<AttendanceState> {
  late AttendanceRepository _repository;
  late ToastService _toastService;

  @override
  AttendanceState build() {
    _repository = ref.watch(attendanceRepositoryProvider);
    _toastService = ref.watch(toastServiceProvider);

    final currentNepali = NepaliCalendarHelper.getCurrentNepaliYearMonth();

    // Listen to locale changes so that switching language always re-fetches
    // fresh data and immediately synchronizes the monthly summary.
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous != null && previous.languageCode != next.languageCode) {
        loadMonth(state.currentYear, state.currentMonthIndex);
      }
    });

    return AttendanceState(
      currentYear: currentNepali.year,
      currentMonthIndex: currentNepali.monthIndex,
      isLoading: false,
    );
  }

  /// Loads attendance logs for a specific BS year and monthIndex (0-11).
  Future<void> loadMonth(int year, int monthIndex) async {
    state = state.copyWith(
      currentYear: year,
      currentMonthIndex: monthIndex,
      isLoading: true,
      errorMessage: null,
    );

    try {
      final logs = await _repository.fetchMonthLogs(year, monthIndex);
      state = state.copyWith(
        logs: logs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      _toastService.showError(
        'Failed to load attendance: $e',
        nepaliMessage: 'उपस्थिति लोड गर्न सकिएन',
      );
    }
  }

  /// Navigates to previous BS month.
  Future<void> previousMonth() async {
    final prev = NepaliCalendarHelper.previousMonth(
      state.currentYear,
      state.currentMonthIndex,
    );
    await loadMonth(prev.year, prev.monthIndex);
  }

  /// Navigates to next BS month.
  Future<void> nextMonth() async {
    final next = NepaliCalendarHelper.nextMonth(
      state.currentYear,
      state.currentMonthIndex,
    );
    await loadMonth(next.year, next.monthIndex);
  }

  /// Handles status toggle or change for a specific day.
  ///
  /// Mirroring Next.js `handleStatusClick`:
  /// - If clicking the active status on a selected day, toggles delete (replaces with placeholder).
  /// - If status != present, resets extraTripIncome to 0 while preserving KM.
  /// - Rollback on error affects ONLY the mutated date.
  Future<void> changeStatus(String logDate, AttendanceStatus newStatus) async {
    if (NepalClock.isFuture(logDate)) {
      _toastService.showError(
        'You cannot mark attendance for future dates',
        nepaliMessage: 'भविष्यको मिति चयन गर्न सकिँदैन',
      );
      return;
    }

    final index = state.logs.indexWhere((l) => l.logDate == logDate);
    if (index == -1) return;

    final oldLog = state.logs[index];

    // Toggle delete if clicking same status on already selected day
    if (!oldLog.isUnselected && oldLog.status == newStatus) {
      final placeholder = AttendanceLog.unselectedPlaceholder(logDate);
      _replaceLogAtIndex(index, placeholder, logDate, isSaving: true);

      try {
        await _repository.deleteAttendance(logDate);
        _removeSavingDate(logDate);
      } catch (e) {
        // Rollback ONLY this date
        _replaceLogAtIndex(index, oldLog, logDate, isSaving: false);
        _toastService.showError(
          'Delete failed: $e',
          nepaliMessage: 'मेट्दा समस्या आयो',
        );
      }
      return;
    }

    // Upsert status
    final updatedLog = oldLog.copyWith(
      status: newStatus,
      extraTripIncome: oldLog.extraTripIncome,
      extraTipAmount: oldLog.extraTipAmount,
      extraTipNote: oldLog.extraTipNote,
      isUnselected: false,
    );

    _replaceLogAtIndex(index, updatedLog, logDate, isSaving: true);

    try {
      final savedLog = await _repository.upsertAttendance(updatedLog);
      _replaceLogAtIndex(index, savedLog, logDate, isSaving: false);
    } catch (e) {
      // Rollback ONLY this date
      _replaceLogAtIndex(index, oldLog, logDate, isSaving: false);
      _toastService.showError(
        'Save failed: $e',
        nepaliMessage: 'सेभ गर्दा समस्या आयो',
      );
    }
  }

  /// Updates extra tip amount and location note for a day.
  /// Synchronizes directly with the website's `extra_tip_amount` and `extra_tip_note` fields.
  Future<void> updateExtraTip({
    required String logDate,
    required int amount,
    String? note,
  }) async {
    final index = state.logs.indexWhere((l) => l.logDate == logDate);
    if (index == -1) return;

    final oldLog = state.logs[index];
    final updatedLog = oldLog.copyWith(
      extraTipAmount: amount,
      extraTipNote: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      extraTripIncome: amount,
      isUnselected: false,
    );

    _replaceLogAtIndex(index, updatedLog, logDate, isSaving: true);

    try {
      final savedLog = await _repository.upsertAttendance(updatedLog);
      _replaceLogAtIndex(index, savedLog, logDate, isSaving: false);
      _toastService.showSuccess(
        'Extra tip saved',
        nepaliMessage: 'अतिरिक्त टिप सुरक्षित गरियो',
      );
    } catch (e) {
      _replaceLogAtIndex(index, oldLog, logDate, isSaving: false);
      _toastService.showError(
        'Failed to save extra tip: $e',
        nepaliMessage: 'अतिरिक्त टिप सुरक्षित गर्न सकिएन',
      );
    }
  }

  /// Backward-compatible alias for updateExtraTip.
  Future<void> updateExtraTrip(String logDate, int extraTrip) async {
    await updateExtraTip(logDate: logDate, amount: extraTrip);
  }

  /// Updates odometer KM readings (start, end, and computed total).
  Future<void> updateKm(String logDate, int startKm, int endKm) async {
    if (endKm < startKm) {
      _toastService.showError(
        'Ending KM cannot be less than Starting KM',
        nepaliMessage: 'अन्तिम किलोमिटर सुरुभन्दा कम हुन सक्दैन',
      );
      return;
    }

    final index = state.logs.indexWhere((l) => l.logDate == logDate);
    if (index == -1) return;

    final oldLog = state.logs[index];
    final totalKm = endKm - startKm;

    final updatedLog = oldLog.copyWith(
      kmStart: startKm,
      kmEnd: endKm,
      kmTotal: totalKm,
    );

    _replaceLogAtIndex(index, updatedLog, logDate, isSaving: true);

    try {
      final savedLog = await _repository.upsertAttendance(updatedLog);
      _replaceLogAtIndex(index, savedLog, logDate, isSaving: false);
      _toastService.showSuccess(
        'KM entry saved ($totalKm km)',
        nepaliMessage: 'किलोमिटर सुरक्षित गरियो',
      );
    } catch (e) {
      _replaceLogAtIndex(index, oldLog, logDate, isSaving: false);
      _toastService.showError(
        'Failed to save KM: $e',
        nepaliMessage: 'किलोमिटर सेभ गर्न समस्या आयो',
      );
    }
  }

  void _replaceLogAtIndex(
    int index,
    AttendanceLog newLog,
    String logDate, {
    required bool isSaving,
  }) {
    final updatedLogs = List<AttendanceLog>.from(state.logs);
    updatedLogs[index] = newLog;

    final updatedSavingDates = Set<String>.from(state.savingDates);
    if (isSaving) {
      updatedSavingDates.add(logDate);
    } else {
      updatedSavingDates.remove(logDate);
    }

    state = state.copyWith(
      logs: updatedLogs,
      savingDates: updatedSavingDates,
    );
  }

  void _removeSavingDate(String logDate) {
    final updatedSavingDates = Set<String>.from(state.savingDates)..remove(logDate);
    state = state.copyWith(savingDates: updatedSavingDates);
  }
}
