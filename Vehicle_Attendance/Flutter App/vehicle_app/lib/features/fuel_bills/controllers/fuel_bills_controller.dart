import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/toast_service.dart';
import '../models/fuel_bill.dart';
import '../repositories/fuel_bills_repository.dart';

class FuelBillsState {
  final List<FuelBill> bills;
  final String? lastBillDate;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const FuelBillsState({
    this.bills = const [],
    this.lastBillDate,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  FuelBillsState copyWith({
    List<FuelBill>? bills,
    String? lastBillDate,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return FuelBillsState(
      bills: bills ?? this.bills,
      lastBillDate: lastBillDate ?? this.lastBillDate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

final fuelBillsControllerProvider =
    NotifierProvider<FuelBillsController, FuelBillsState>(() {
  return FuelBillsController();
});

class FuelBillsController extends Notifier<FuelBillsState> {
  late FuelBillsRepository _repository;
  late ToastService _toastService;

  @override
  FuelBillsState build() {
    _repository = ref.watch(fuelBillsRepositoryProvider);
    _toastService = ref.watch(toastServiceProvider);
    return const FuelBillsState();
  }

  /// Loads both all fuel bills and the last bill date.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final billsFuture = _repository.fetchFuelBills();
      final lastDateFuture = _repository.fetchLastBillDate();

      final results = await Future.wait([billsFuture, lastDateFuture]);
      final bills = results[0] as List<FuelBill>;
      final lastDate = results[1] as String?;

      state = state.copyWith(
        bills: bills,
        lastBillDate: lastDate ?? (bills.isNotEmpty ? bills.first.endDate : '2026-01-15'),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Updates the last fuel bill end date.
  Future<bool> updateLastBillDate(String newDate) async {
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _repository.updateLastBillDate(newDate);
      state = state.copyWith(
        lastBillDate: updated ?? newDate,
        isSaving: false,
      );
      _toastService.showSuccess(
        'Last bill date updated successfully',
        nepaliMessage: 'अन्तिम बिल मिति सफलतापूर्वक परिवर्तन गरियो',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      _toastService.showError(
        'Failed to update last bill date',
        nepaliMessage: 'अन्तिम बिल मिति परिवर्तन गर्न असफल भयो',
      );
      return false;
    }
  }

  /// Creates a new fuel bill.
  Future<bool> createFuelBill({
    required String startDate,
    required String endDate,
    required int totalKm,
    required double expectedLiters,
    double? actualLiters,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.createFuelBill(
        startDate: startDate,
        endDate: endDate,
        totalKm: totalKm,
        expectedLiters: expectedLiters,
        actualLiters: actualLiters,
      );
      _toastService.showSuccess(
        'Fuel bill created successfully',
        nepaliMessage: 'ईन्धन बिल सफलतापूर्वक सिर्जना गरियो',
      );
      // Reload to ensure state and last bill date table are synchronized
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      _toastService.showError(
        'Failed to create fuel bill',
        nepaliMessage: 'ईन्धन बिल सिर्जना गर्न असफल भयो',
      );
      return false;
    }
  }
}
