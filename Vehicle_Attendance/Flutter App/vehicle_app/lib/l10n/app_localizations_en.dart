// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Bolero Attendance';

  @override
  String get common_language_selector_label => 'Language / भाषा';

  @override
  String get settings_font_scale_title => 'Text Size / अक्षरको आकार';

  @override
  String get settings_font_scale_normal => 'Normal';

  @override
  String get settings_font_scale_large => 'Large';

  @override
  String get settings_font_scale_senior => 'Senior (Extra Large)';

  @override
  String get common_english => 'English';

  @override
  String get common_nepali => 'नेपाली';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_close => 'Close';

  @override
  String get common_add => '+ Add';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_saving => 'Saving...';

  @override
  String get common_currency_rs => 'Rs.';

  @override
  String get common_unit_km => 'km';

  @override
  String get common_unit_liters => 'Liters';

  @override
  String get common_unit_l => 'L';

  @override
  String get auth_login_title => 'Bolero Attendance';

  @override
  String get auth_login_subtitle => 'Sign in to access your dashboard';

  @override
  String get auth_login_emailLabel => 'Email Address';

  @override
  String get auth_login_emailHint => 'your@email.com';

  @override
  String get auth_login_emailRequired => 'Email is required';

  @override
  String get auth_login_emailInvalid => 'Enter a valid email address';

  @override
  String get auth_login_passwordLabel => 'Password';

  @override
  String get auth_login_passwordHint => '••••••••';

  @override
  String get auth_login_passwordRequired => 'Password is required';

  @override
  String get auth_login_passwordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get auth_login_rememberMe => 'Remember me';

  @override
  String get auth_login_signInButton => 'Sign in';

  @override
  String get auth_login_signingInButton => 'Signing in...';

  @override
  String dashboard_appbar_subtitle(
    String monthName,
    String year,
    String englishRange,
  ) {
    return '$monthName $year ($englishRange)';
  }

  @override
  String get dashboard_drawer_title => 'Bolero Attendance System';

  @override
  String get dashboard_drawer_nav_dashboard => 'Dashboard';

  @override
  String get dashboard_drawer_nav_fuelBills => 'Fuel Bill Records';

  @override
  String get dashboard_drawer_nav_downloadReport => 'Download Report (PDF)';

  @override
  String get dashboard_drawer_nav_signOut => 'Sign Out';

  @override
  String get dashboard_signOut_dialogTitle => 'Sign Out';

  @override
  String get dashboard_signOut_dialogMessage =>
      'Are you sure you want to sign out of the vehicle attendance system?';

  @override
  String get dashboard_bottomNav_home => 'Home';

  @override
  String get dashboard_bottomNav_calendar => 'Calendar';

  @override
  String get summary_card_title => 'Monthly Summary';

  @override
  String get summary_presentDays => 'Present Days';

  @override
  String get summary_replacementDays => 'Replacement Days';

  @override
  String get summary_totalKm => 'Total KM Run';

  @override
  String get summary_extraTrips => 'Extra Trips (Rs.)';

  @override
  String get summary_deductions => 'Deductions (Rs.)';

  @override
  String get summary_netIncome => 'Net Income (Rs.)';

  @override
  String get summary_netIncomeFormula => 'Earnings - Deductions';

  @override
  String get summary_deductions_exceed => 'Deductions exceed earnings';

  @override
  String get summary_earnings => 'Earnings';

  @override
  String get summary_sec_attendance => 'Attendance';

  @override
  String get summary_sec_performance => 'Performance';

  @override
  String get summary_unit_days => 'days';

  @override
  String get summary_present_label => 'Present';

  @override
  String get summary_replacement_label => 'Replacement';

  @override
  String get summary_distance_run => 'Distance run';

  @override
  String get calendar_todayChip => 'Today';

  @override
  String get calendar_prevMonthTooltip => 'Previous Month';

  @override
  String get calendar_nextMonthTooltip => 'Next Month';

  @override
  String calendar_missingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days need data',
      one: '1 day needs data',
      zero: 'All days complete',
    );
    return '$_temp0';
  }

  @override
  String get calendar_legend_present => 'Present';

  @override
  String get calendar_legend_holiday => 'Holiday';

  @override
  String get calendar_legend_replace => 'Replace';

  @override
  String get calendar_legend_missingStatus => 'Missing Status';

  @override
  String get calendar_legend_missingKm => 'Missing KM';

  @override
  String get calendar_legend_today => 'Today';

  @override
  String calendar_semantics_day(
    String nepaliDay,
    String nepaliMonth,
    String status,
    String kmTotal,
  ) {
    return '$nepaliDay $nepaliMonth, $status, $kmTotal kilometers';
  }

  @override
  String get status_present => 'Present';

  @override
  String get status_holiday => 'Holiday';

  @override
  String get status_replace => 'Replace';

  @override
  String get status_unselected => 'Unmarked';

  @override
  String get status_presentRate => 'Rs. 1,200';

  @override
  String get status_holidaySubtitle => 'No pay';

  @override
  String get status_replaceDeduction => '-Rs. 3,000';

  @override
  String get day_sheet_missingStatusAlert =>
      'Missing: Status unmarked for this date';

  @override
  String get day_sheet_missingKmAlert => 'Missing: KM odometer entry required';

  @override
  String get day_sheet_attendanceStatusTitle => 'Attendance Status';

  @override
  String get day_sheet_detailsRecordsTitle => 'Details & Records';

  @override
  String get day_sheet_enterKmTitle => 'Enter Odometer KM';

  @override
  String get day_sheet_enterKmSubtitle => 'Starting & ending odometer reading';

  @override
  String get day_sheet_extraTripTitle => 'Extra Trip Income';

  @override
  String get day_sheet_extraTripSubtitle => 'Additional earnings for today';

  @override
  String get km_sheet_title => 'Odometer KM';

  @override
  String get km_sheet_subtitle => 'Enter starting and ending readings';

  @override
  String get km_sheet_startKmLabel => 'Starting KM';

  @override
  String get km_sheet_startKmHint => 'e.g. 10240';

  @override
  String get km_sheet_endKmLabel => 'Ending KM';

  @override
  String get km_sheet_endKmHint => 'e.g. 10320';

  @override
  String km_sheet_totalRun(String km) {
    return 'Total KM Run: $km km';
  }

  @override
  String get km_sheet_saveButton => 'Save KM';

  @override
  String get km_sheet_validationRequired =>
      'Both starting and ending KM are required';

  @override
  String get km_sheet_validationEndLessThanStart =>
      'Ending KM cannot be less than Starting KM';

  @override
  String get trip_dialog_title => 'Extra Tip Details';

  @override
  String get trip_dialog_subtitle =>
      'Note where this tip came from and how much you expect.';

  @override
  String get trip_dialog_locationLabel => 'Where was your tip?';

  @override
  String get trip_dialog_upayeToggle => 'Upaye Ho ?';

  @override
  String get upaye_badge => 'Upaye';

  @override
  String get trip_dialog_locationHint =>
      'e.g. Evening market return, special trip';

  @override
  String get trip_dialog_amountLabel => 'Expected tip amount (Rs.)';

  @override
  String get trip_dialog_amountHint => '0';

  @override
  String get trip_dialog_save => 'Save tip';

  @override
  String get trip_dialog_validationRequired => 'Amount is required';

  @override
  String get tips_record_title => 'Tips Record';

  @override
  String get tips_record_noNote => 'No destination';

  @override
  String get company_payments_tile_title => 'Company Payments Received';

  @override
  String company_payments_tile_total(String amount) {
    return 'Total received: $amount';
  }

  @override
  String get company_payments_tile_noPayments =>
      'Record mid-month payments before salary';

  @override
  String get company_payments_dialog_title => 'Company Payments Received';

  @override
  String get company_payments_dialog_subtitle =>
      'Record tips or partial payments received mid-month before salary. These will be automatically deducted from your final settlement.';

  @override
  String get company_payments_dialog_totalCard => 'Total Received This Month';

  @override
  String get company_payments_add_button => '+ Add Received Payment';

  @override
  String get company_payments_empty => 'No payments recorded for this month.';

  @override
  String get company_payments_entry_title => 'Record Received Payment';

  @override
  String get company_payments_entry_date => 'Received Date';

  @override
  String get company_payments_entry_amount => 'Received Amount (Rs.)';

  @override
  String get company_payments_entry_amount_hint => 'e.g. 6000';

  @override
  String get company_payments_entry_note => 'Remarks / Note';

  @override
  String get company_payments_entry_note_hint =>
      'e.g. Upaye tip for Kushma trip';

  @override
  String get company_payments_delete_confirm =>
      'Are you sure you want to delete this payment record?';

  @override
  String get settlement_tile_title => 'Bank Salary Settlement';

  @override
  String settlement_tile_fullySettled(String amount) {
    return 'Fully settled: $amount';
  }

  @override
  String settlement_tile_pending(String amount) {
    return 'Unpaid balance: $amount';
  }

  @override
  String get settlement_tile_notRecorded => 'Record final bank salary received';

  @override
  String get settlement_arrears_banner_title => 'Previous Month Dues Pending';

  @override
  String settlement_arrears_banner_desc(String amount, String month) {
    return '$amount is still pending from $month salary.';
  }

  @override
  String get settlement_dialog_title => 'Bank Salary Settlement';

  @override
  String get settlement_dialog_subtitle =>
      'Record the actual salary amount deposited by the company into your bank. Any unpaid balance will be automatically carried forward.';

  @override
  String get settlement_expected_label => 'Expected from Company (Net)';

  @override
  String get settlement_actual_label => 'Actual Received in Bank';

  @override
  String get settlement_date_label => 'Deposit Date';

  @override
  String get settlement_diff_label => 'Unpaid Due (Carried Forward)';

  @override
  String get settlement_fully_paid_badge => 'Fully Paid';

  @override
  String get settlement_partial_badge => 'Partial Payment';

  @override
  String get settlement_calendar_bs => 'Nepali (BS)';

  @override
  String get settlement_calendar_ad => 'English (AD)';

  @override
  String get settlement_pick_date => 'Select Date';

  @override
  String get fuel_records_tile_title => 'Fuel Bill Records';

  @override
  String fuel_records_tile_lastEnded(String date) {
    return 'Last bill ended: $date';
  }

  @override
  String get fuel_records_tile_noBills => 'No fuel bill yet';

  @override
  String get fuel_records_dialog_title => 'Fuel Bill Records';

  @override
  String get fuel_records_dialog_lastEndedTitle => 'Last Fuel Bill End Date';

  @override
  String get fuel_records_dialog_lastEndedHint =>
      'This is the last date your previous fuel bill ended. Edit it if there was a mistake.';

  @override
  String get fuel_records_dialog_editDateButton => 'Edit Date';

  @override
  String get fuel_records_dialog_generateBillButton => 'Generate Fuel Bill';

  @override
  String get fuel_records_dialog_historyTitle => 'Bill History';

  @override
  String fuel_records_dialog_recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get fuel_records_dialog_emptyState => 'No fuel bill records found.';

  @override
  String get fuel_records_col_period => 'Period';

  @override
  String get fuel_records_col_totalKm => 'Total KM';

  @override
  String get fuel_records_col_expectedLiters => 'Expected';

  @override
  String get fuel_records_col_actualLiters => 'Actual';

  @override
  String get km_summary_table_title => 'Monthly Running Summary';

  @override
  String get km_summary_col_date => 'Date';

  @override
  String get km_summary_col_start => 'Start';

  @override
  String get km_summary_col_end => 'End';

  @override
  String get km_summary_col_total => 'Total';

  @override
  String get km_summary_empty => 'No odometer records for this month';

  @override
  String get km_summary_month_total => 'Month Total';

  @override
  String get generate_fuel_dialog_title => 'Generate Fuel Bill';

  @override
  String get generate_fuel_dialog_lastEnded => 'Last Bill Ended On';

  @override
  String get generate_fuel_dialog_lastEndedHint =>
      'Previous bill ended on this date';

  @override
  String get generate_fuel_dialog_startDate => 'Bill Start Date (From)';

  @override
  String get generate_fuel_dialog_startDateHint =>
      'Auto-calculated as day after last bill (edit last bill date to change this)';

  @override
  String get generate_fuel_dialog_endDate => 'Bill End Date (To)';

  @override
  String get generate_fuel_dialog_calculating => 'Calculating…';

  @override
  String get generate_fuel_dialog_periodLabel => 'Period:';

  @override
  String get generate_fuel_dialog_totalKmLabel => 'Total KM:';

  @override
  String get generate_fuel_dialog_expectedFuelLabel => 'Expected Fuel (÷ 7.5):';

  @override
  String generate_fuel_dialog_litersDisplay(String liters) {
    return '$liters Liters';
  }

  @override
  String get generate_fuel_dialog_actualLitersLabel =>
      'Actual Fuel Given (Optional)';

  @override
  String get generate_fuel_dialog_actualLitersHint => 'e.g. 45.5';

  @override
  String get generate_fuel_dialog_actualLitersHelper =>
      'Enter the actual liters provided by the company';

  @override
  String get generate_fuel_dialog_saveButton => 'Save Fuel Bill';

  @override
  String get generate_fuel_dialog_savingButton => 'Saving...';

  @override
  String get quick_actions_fuelBill_title => 'Generate Fuel Bill';

  @override
  String get quick_actions_fuelBill_subtitle => 'Calculate fuel consumption';

  @override
  String get quick_actions_downloadPdf_title => 'Download Report';

  @override
  String get quick_actions_downloadPdf_subtitle => 'PDF format (up to today)';

  @override
  String get pdf_report_systemTitle => 'Bolero Attendance System';

  @override
  String get pdf_report_sheetTitle => 'Monthly Details Sheet';

  @override
  String pdf_report_generatedDate(String date) {
    return 'Generated: $date';
  }

  @override
  String get pdf_report_earningSection => 'Earning Sheet';

  @override
  String get pdf_report_fuelSection => 'Fuel Bill Records';

  @override
  String get pdf_report_finalSettlementSection => 'Final Settlement';

  @override
  String get pdf_report_col_sn => 'SN';

  @override
  String get pdf_report_col_bsDate => 'BS Date';

  @override
  String get pdf_report_col_adDate => 'AD Date';

  @override
  String get pdf_report_col_status => 'Status';

  @override
  String get pdf_report_col_startKm => 'Start KM';

  @override
  String get pdf_report_col_endKm => 'End KM';

  @override
  String get pdf_report_col_totalKm => 'Total KM';

  @override
  String get pdf_report_col_extraTrip => 'Extra Trip';

  @override
  String get pdf_report_col_note => 'Note';

  @override
  String pdf_report_totalPresentDays(String days) {
    return 'Total Present Days = $days';
  }

  @override
  String pdf_report_totalReplacementDays(String days) {
    return 'Replacement Days = $days';
  }

  @override
  String pdf_report_totalAbsentDays(String days) {
    return 'Absent Days = $days';
  }

  @override
  String get pdf_report_grossEarnings => 'Gross Earnings';

  @override
  String get pdf_report_tdsDeduction => 'TDS Deduction (1.5%)';

  @override
  String get pdf_report_netPayable => 'Net Payable';

  @override
  String get pdf_report_formulaExplanation =>
      'Calculated by earning from total present days - Replace Days';

  @override
  String pdf_report_pageNumber(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get toast_futureDateError =>
      'You cannot mark attendance for future dates';

  @override
  String get toast_deleteSuccess => 'Attendance deleted';

  @override
  String toast_deleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String toast_saveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String toast_kmSaved(String km) {
    return 'KM entry saved ($km km)';
  }

  @override
  String toast_kmFailed(String error) {
    return 'Failed to save KM: $error';
  }

  @override
  String get toast_extraTripSaved => 'Extra trip saved';

  @override
  String toast_extraTripFailed(String error) {
    return 'Failed to save extra trip: $error';
  }

  @override
  String get toast_lastBillDateUpdated => 'Last bill date updated successfully';

  @override
  String get toast_lastBillDateFailed => 'Failed to update last bill date';

  @override
  String get fuel_bill_created_success => 'Fuel bill created successfully';

  @override
  String get fuel_bill_created_failed => 'Failed to create fuel bill';

  @override
  String get toast_pdfGenerated => 'PDF downloaded successfully';

  @override
  String toast_pdfFailed(String error) {
    return 'Failed to generate PDF: $error';
  }

  @override
  String get toast_genericError => 'An unexpected error occurred';

  @override
  String get toast_networkError => 'Network error, please check connection';

  @override
  String get error_invalidCredentials => 'Invalid email or password';

  @override
  String get error_sessionExpired => 'Session expired, please sign in again';

  @override
  String get error_unauthorized => 'Unauthorized access';

  @override
  String get error_serverError => 'Server error, please try again later';
}
