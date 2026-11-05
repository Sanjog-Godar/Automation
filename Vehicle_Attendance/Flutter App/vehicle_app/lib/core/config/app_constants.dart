/// Central application constants and financial rates.
/// 
/// Rates and business constants must ONLY be defined here.
/// Never hard-code values elsewhere.
class AppConstants {
  AppConstants._();

  /// Daily wage in Rs. for a present driver.
  static const int dailyWage = 1200;

  /// Deduction amount in Rs. when a replacement driver is sent.
  static const int replacementDeduction = 3000;

  /// Vehicle fuel mileage rate: 7.5 kilometers per 1 liter of fuel.
  static const double fuelMileageKmPerLiter = 7.5;

  /// Tax Deducted at Source (TDS) rate for final report settlement (1.5%).
  static const double tdsRate = 0.015;

  /// Default vehicle identification number.
  static const String vehicleNumber = 'Ga 2 Pa 4066';

  /// Standard default cutoff date for fuel bills if database record is unset.
  static const String defaultLastFuelBillDate = '2026-01-15';
}

