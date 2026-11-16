import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/toast_service.dart';
import '../models/monthly_settlement.dart';
import '../repositories/settlements_repository.dart';

class SettlementsState {
  final MonthlySettlement? currentSettlement;
  final MonthlySettlement? previousSettlement;
  final bool isLoading;

  const SettlementsState({
    this.currentSettlement,
    this.previousSettlement,
    this.isLoading = false,
  });

  /// Previous month's unpaid balance carried forward into the current month.
  int get previousMonthDue => previousSettlement?.pendingAmount ?? 0;

  /// True if previous month has an unpaid balance.
  bool get hasPreviousMonthDue => previousMonthDue > 0;

  SettlementsState copyWith({
    MonthlySettlement? currentSettlement,
    MonthlySettlement? previousSettlement,
    bool? isLoading,
    bool clearCurrent = false,
    bool clearPrevious = false,
  }) {
    return SettlementsState(
      currentSettlement: clearCurrent ? null : (currentSettlement ?? this.currentSettlement),
      previousSettlement: clearPrevious ? null : (previousSettlement ?? this.previousSettlement),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final settlementsControllerProvider =
    NotifierProvider<SettlementsController, SettlementsState>(SettlementsController.new);

class SettlementsController extends Notifier<SettlementsState> {
  late SettlementsRepository _repository;
  late ToastService _toastService;

  @override
  SettlementsState build() {
    _repository = ref.watch(settlementsRepositoryProvider);
    _toastService = ref.watch(toastServiceProvider);
    return const SettlementsState();
  }

  /// Loads the current and previous month settlements.
  Future<void> load({required int bsYear, required int bsMonthIndex}) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.fetchSettlements(
        bsYear: bsYear,
        bsMonthIndex: bsMonthIndex,
      );
      state = state.copyWith(
        currentSettlement: result.current,
        previousSettlement: result.previous,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Saves the bank salary received for the month.
  Future<void> saveSettlement({
    required int bsYear,
    required int bsMonthIndex,
    required int expectedAmount,
    required int bankReceivedAmount,
    required String? paymentDate,
    String? note,
  }) async {
    final settlement = MonthlySettlement(
      bsYear: bsYear,
      bsMonthIndex: bsMonthIndex,
      expectedAmount: expectedAmount,
      bankReceivedAmount: bankReceivedAmount,
      paymentDate: paymentDate,
      note: note,
    );

    try {
      final saved = await _repository.saveSettlement(settlement);
      if (saved != null) {
        state = state.copyWith(currentSettlement: saved);
        _toastService.showSuccess(
          'Bank salary settlement recorded',
          nepaliMessage: 'बैंक तलब भुक्तानी सुरक्षित गरियो',
        );
      }
    } catch (e) {
      _toastService.showError(
        'Failed to save bank settlement: $e',
        nepaliMessage: 'बैंक भुक्तानी सुरक्षित गर्न सकिएन',
      );
    }
  }
}
