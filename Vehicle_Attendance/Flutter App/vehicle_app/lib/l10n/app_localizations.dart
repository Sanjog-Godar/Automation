import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// Application display title
  ///
  /// In en, this message translates to:
  /// **'Bolero Attendance'**
  String get app_name;

  /// Bilingual language header in sidebar drawer
  ///
  /// In en, this message translates to:
  /// **'Language / भाषा'**
  String get common_language_selector_label;

  /// Bilingual text size header in sidebar drawer
  ///
  /// In en, this message translates to:
  /// **'Text Size / अक्षरको आकार'**
  String get settings_font_scale_title;

  /// Standard font size option
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settings_font_scale_normal;

  /// Large font size option
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settings_font_scale_large;

  /// Extra large font size option for seniors
  ///
  /// In en, this message translates to:
  /// **'Senior (Extra Large)'**
  String get settings_font_scale_senior;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get common_english;

  /// Nepali language option in Devanagari
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get common_nepali;

  /// Generic Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Generic Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// Generic Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// Generic Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// Generic Add action
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get common_add;

  /// Generic Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// Generic Saving text
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get common_saving;

  /// Currency prefix
  ///
  /// In en, this message translates to:
  /// **'Rs.'**
  String get common_currency_rs;

  /// Kilometer unit abbreviation
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get common_unit_km;

  /// Fuel volume unit
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get common_unit_liters;

  /// Short fuel volume abbreviation
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get common_unit_l;

  /// Title on login card
  ///
  /// In en, this message translates to:
  /// **'Bolero Attendance'**
  String get auth_login_title;

  /// Subtitle on login card
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your dashboard'**
  String get auth_login_subtitle;

  /// Label for email field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_login_emailLabel;

  /// Hint text for email field
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get auth_login_emailHint;

  /// Validation message when email is empty
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get auth_login_emailRequired;

  /// Validation message when email is malformed
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get auth_login_emailInvalid;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_login_passwordLabel;

  /// Hint text for password field
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get auth_login_passwordHint;

  /// Validation message when password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get auth_login_passwordRequired;

  /// Validation message when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_login_passwordMinLength;

  /// Label for remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get auth_login_rememberMe;

  /// Login submit button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get auth_login_signInButton;

  /// Login submit button text when loading
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get auth_login_signingInButton;

  /// Subtitle in top AppBar with month and year
  ///
  /// In en, this message translates to:
  /// **'{monthName} {year} ({englishRange})'**
  String dashboard_appbar_subtitle(
    String monthName,
    String year,
    String englishRange,
  );

  /// Header title inside navigation drawer
  ///
  /// In en, this message translates to:
  /// **'Bolero Attendance System'**
  String get dashboard_drawer_title;

  /// Drawer navigation item for dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_drawer_nav_dashboard;

  /// Drawer navigation item for fuel bills
  ///
  /// In en, this message translates to:
  /// **'Fuel Bill Records'**
  String get dashboard_drawer_nav_fuelBills;

  /// Drawer navigation item for report export
  ///
  /// In en, this message translates to:
  /// **'Download Report (PDF)'**
  String get dashboard_drawer_nav_downloadReport;

  /// Drawer navigation item to log out
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get dashboard_drawer_nav_signOut;

  /// Title of sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get dashboard_signOut_dialogTitle;

  /// Body message of sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of the vehicle attendance system?'**
  String get dashboard_signOut_dialogMessage;

  /// Bottom navigation label for the earnings home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboard_bottomNav_home;

  /// Bottom navigation label for the attendance calendar tab
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get dashboard_bottomNav_calendar;

  /// Header title of the monthly summary card
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get summary_card_title;

  /// Metric tile label for present days
  ///
  /// In en, this message translates to:
  /// **'Present Days'**
  String get summary_presentDays;

  /// Metric tile label for replacement days
  ///
  /// In en, this message translates to:
  /// **'Replacement Days'**
  String get summary_replacementDays;

  /// Metric tile label for total kilometers
  ///
  /// In en, this message translates to:
  /// **'Total KM Run'**
  String get summary_totalKm;

  /// Metric tile label for extra trips income
  ///
  /// In en, this message translates to:
  /// **'Extra Trips (Rs.)'**
  String get summary_extraTrips;

  /// Metric tile label for deductions
  ///
  /// In en, this message translates to:
  /// **'Deductions (Rs.)'**
  String get summary_deductions;

  /// Label for prominent net income metric
  ///
  /// In en, this message translates to:
  /// **'Net Income (Rs.)'**
  String get summary_netIncome;

  /// Subtitle explaining net income formula
  ///
  /// In en, this message translates to:
  /// **'Earnings - Deductions'**
  String get summary_netIncomeFormula;

  /// Pill text when deductions exceed earnings
  ///
  /// In en, this message translates to:
  /// **'Deductions exceed earnings'**
  String get summary_deductions_exceed;

  /// Label for gross earnings inside hero card
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get summary_earnings;

  /// Section header for attendance metrics
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get summary_sec_attendance;

  /// Section header for performance metrics
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get summary_sec_performance;

  /// Unit for days count
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get summary_unit_days;

  /// Label for present days in attendance section
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get summary_present_label;

  /// Label for replacement days in attendance section
  ///
  /// In en, this message translates to:
  /// **'Replacement'**
  String get summary_replacement_label;

  /// Label for distance run in performance section
  ///
  /// In en, this message translates to:
  /// **'Distance run'**
  String get summary_distance_run;

  /// Today jump chip in month navigation
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendar_todayChip;

  /// Tooltip for previous month chevron
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get calendar_prevMonthTooltip;

  /// Tooltip for next month chevron
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get calendar_nextMonthTooltip;

  /// Plural missing days notification chip
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All days complete} =1{1 day needs data} other{{count} days need data}}'**
  String calendar_missingDays(int count);

  /// Legend label for present day
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get calendar_legend_present;

  /// Legend label for holiday
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get calendar_legend_holiday;

  /// Legend label for replacement day
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get calendar_legend_replace;

  /// Legend label for missing status badge
  ///
  /// In en, this message translates to:
  /// **'Missing Status'**
  String get calendar_legend_missingStatus;

  /// Legend label for missing KM badge
  ///
  /// In en, this message translates to:
  /// **'Missing KM'**
  String get calendar_legend_missingKm;

  /// Legend label for today highlight ring
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendar_legend_today;

  /// Accessibility screen-reader label for a day cell
  ///
  /// In en, this message translates to:
  /// **'{nepaliDay} {nepaliMonth}, {status}, {kmTotal} kilometers'**
  String calendar_semantics_day(
    String nepaliDay,
    String nepaliMonth,
    String status,
    String kmTotal,
  );

  /// Status name for present
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get status_present;

  /// Status name for holiday
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get status_holiday;

  /// Status name for replacement
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get status_replace;

  /// Status name for unselected day
  ///
  /// In en, this message translates to:
  /// **'Unmarked'**
  String get status_unselected;

  /// Rate subtitle on present button
  ///
  /// In en, this message translates to:
  /// **'Rs. 1,200'**
  String get status_presentRate;

  /// Rate subtitle on holiday button
  ///
  /// In en, this message translates to:
  /// **'No pay'**
  String get status_holidaySubtitle;

  /// Deduction subtitle on replace button
  ///
  /// In en, this message translates to:
  /// **'-Rs. 3,000'**
  String get status_replaceDeduction;

  /// Banner when day status is unmarked
  ///
  /// In en, this message translates to:
  /// **'Missing: Status unmarked for this date'**
  String get day_sheet_missingStatusAlert;

  /// Banner when present day has missing KM
  ///
  /// In en, this message translates to:
  /// **'Missing: KM odometer entry required'**
  String get day_sheet_missingKmAlert;

  /// Section title for attendance status toggle
  ///
  /// In en, this message translates to:
  /// **'Attendance Status'**
  String get day_sheet_attendanceStatusTitle;

  /// Section title for detail records
  ///
  /// In en, this message translates to:
  /// **'Details & Records'**
  String get day_sheet_detailsRecordsTitle;

  /// Row title for odometer KM entry
  ///
  /// In en, this message translates to:
  /// **'Enter Odometer KM'**
  String get day_sheet_enterKmTitle;

  /// Row subtitle for odometer KM entry
  ///
  /// In en, this message translates to:
  /// **'Starting & ending odometer reading'**
  String get day_sheet_enterKmSubtitle;

  /// Row title for extra trip earnings
  ///
  /// In en, this message translates to:
  /// **'Extra Trip Income'**
  String get day_sheet_extraTripTitle;

  /// Row subtitle for extra trip earnings
  ///
  /// In en, this message translates to:
  /// **'Additional earnings for today'**
  String get day_sheet_extraTripSubtitle;

  /// Title on KM entry bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Odometer KM'**
  String get km_sheet_title;

  /// Subtitle on KM entry bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Enter starting and ending readings'**
  String get km_sheet_subtitle;

  /// Label for starting odometer reading
  ///
  /// In en, this message translates to:
  /// **'Starting KM'**
  String get km_sheet_startKmLabel;

  /// Hint for starting odometer reading
  ///
  /// In en, this message translates to:
  /// **'e.g. 10240'**
  String get km_sheet_startKmHint;

  /// Label for ending odometer reading
  ///
  /// In en, this message translates to:
  /// **'Ending KM'**
  String get km_sheet_endKmLabel;

  /// Hint for ending odometer reading
  ///
  /// In en, this message translates to:
  /// **'e.g. 10320'**
  String get km_sheet_endKmHint;

  /// Live preview of computed total distance
  ///
  /// In en, this message translates to:
  /// **'Total KM Run: {km} km'**
  String km_sheet_totalRun(String km);

  /// Button to save odometer KM
  ///
  /// In en, this message translates to:
  /// **'Save KM'**
  String get km_sheet_saveButton;

  /// Validation message when KM fields are empty
  ///
  /// In en, this message translates to:
  /// **'Both starting and ending KM are required'**
  String get km_sheet_validationRequired;

  /// Validation message when ending KM is less than starting
  ///
  /// In en, this message translates to:
  /// **'Ending KM cannot be less than Starting KM'**
  String get km_sheet_validationEndLessThanStart;

  /// Title on extra tip details dialog
  ///
  /// In en, this message translates to:
  /// **'Extra Tip Details'**
  String get trip_dialog_title;

  /// Subtitle on extra tip details dialog
  ///
  /// In en, this message translates to:
  /// **'Note where this tip came from and how much you expect.'**
  String get trip_dialog_subtitle;

  /// Label for where tip came from
  ///
  /// In en, this message translates to:
  /// **'Where was your tip?'**
  String get trip_dialog_locationLabel;

  /// Toggle label for Upaye tip
  ///
  /// In en, this message translates to:
  /// **'Upaye Ho ?'**
  String get trip_dialog_upayeToggle;

  /// Badge label for Upaye
  ///
  /// In en, this message translates to:
  /// **'Upaye'**
  String get upaye_badge;

  /// Hint for where tip came from
  ///
  /// In en, this message translates to:
  /// **'e.g. Evening market return, special trip'**
  String get trip_dialog_locationHint;

  /// Label for expected tip amount field
  ///
  /// In en, this message translates to:
  /// **'Expected tip amount (Rs.)'**
  String get trip_dialog_amountLabel;

  /// Hint for expected tip amount field
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get trip_dialog_amountHint;

  /// Button to save tip
  ///
  /// In en, this message translates to:
  /// **'Save tip'**
  String get trip_dialog_save;

  /// Validation message when amount is empty
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get trip_dialog_validationRequired;

  /// Title for the Tips Record card below running summary
  ///
  /// In en, this message translates to:
  /// **'Tips Record'**
  String get tips_record_title;

  /// Fallback text when tip note is empty
  ///
  /// In en, this message translates to:
  /// **'No destination'**
  String get tips_record_noNote;

  /// Title on company payments received tile
  ///
  /// In en, this message translates to:
  /// **'Company Payments Received'**
  String get company_payments_tile_title;

  /// Subtitle showing total received this month
  ///
  /// In en, this message translates to:
  /// **'Total received: {amount}'**
  String company_payments_tile_total(String amount);

  /// Subtitle when no company payments are recorded
  ///
  /// In en, this message translates to:
  /// **'Record mid-month payments before salary'**
  String get company_payments_tile_noPayments;

  /// Title on company payments dialog
  ///
  /// In en, this message translates to:
  /// **'Company Payments Received'**
  String get company_payments_dialog_title;

  /// Subtitle explanation on company payments dialog
  ///
  /// In en, this message translates to:
  /// **'Record tips or partial payments received mid-month before salary. These will be automatically deducted from your final settlement.'**
  String get company_payments_dialog_subtitle;

  /// Label for month total card in payments dialog
  ///
  /// In en, this message translates to:
  /// **'Total Received This Month'**
  String get company_payments_dialog_totalCard;

  /// Button to record a new payment
  ///
  /// In en, this message translates to:
  /// **'+ Add Received Payment'**
  String get company_payments_add_button;

  /// Empty state text in company payments dialog
  ///
  /// In en, this message translates to:
  /// **'No payments recorded for this month.'**
  String get company_payments_empty;

  /// Title for add/edit payment dialog
  ///
  /// In en, this message translates to:
  /// **'Record Received Payment'**
  String get company_payments_entry_title;

  /// Label for date picker
  ///
  /// In en, this message translates to:
  /// **'Received Date'**
  String get company_payments_entry_date;

  /// Label for amount field
  ///
  /// In en, this message translates to:
  /// **'Received Amount (Rs.)'**
  String get company_payments_entry_amount;

  /// Hint for amount field
  ///
  /// In en, this message translates to:
  /// **'e.g. 6000'**
  String get company_payments_entry_amount_hint;

  /// Label for remarks field
  ///
  /// In en, this message translates to:
  /// **'Remarks / Note'**
  String get company_payments_entry_note;

  /// Hint for remarks field
  ///
  /// In en, this message translates to:
  /// **'e.g. Upaye tip for Kushma trip'**
  String get company_payments_entry_note_hint;

  /// Confirmation prompt before deleting payment
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment record?'**
  String get company_payments_delete_confirm;

  /// Title on bank salary settlement tile
  ///
  /// In en, this message translates to:
  /// **'Bank Salary Settlement'**
  String get settlement_tile_title;

  /// Subtitle when bank salary matches or exceeds expected
  ///
  /// In en, this message translates to:
  /// **'Fully settled: {amount}'**
  String settlement_tile_fullySettled(String amount);

  /// Subtitle when bank salary was less than expected
  ///
  /// In en, this message translates to:
  /// **'Unpaid balance: {amount}'**
  String settlement_tile_pending(String amount);

  /// Subtitle when bank salary has not been recorded yet
  ///
  /// In en, this message translates to:
  /// **'Record final bank salary received'**
  String get settlement_tile_notRecorded;

  /// Title of warning banner when previous month salary has unpaid balance
  ///
  /// In en, this message translates to:
  /// **'Previous Month Dues Pending'**
  String get settlement_arrears_banner_title;

  /// Description in arrears warning banner
  ///
  /// In en, this message translates to:
  /// **'{amount} is still pending from {month} salary.'**
  String settlement_arrears_banner_desc(String amount, String month);

  /// Dialog title for bank salary settlement
  ///
  /// In en, this message translates to:
  /// **'Bank Salary Settlement'**
  String get settlement_dialog_title;

  /// Dialog subtitle explanation
  ///
  /// In en, this message translates to:
  /// **'Record the actual salary amount deposited by the company into your bank. Any unpaid balance will be automatically carried forward.'**
  String get settlement_dialog_subtitle;

  /// Label for expected net receivable amount
  ///
  /// In en, this message translates to:
  /// **'Expected from Company (Net)'**
  String get settlement_expected_label;

  /// Label for actual bank deposit amount
  ///
  /// In en, this message translates to:
  /// **'Actual Received in Bank'**
  String get settlement_actual_label;

  /// Label for bank deposit date
  ///
  /// In en, this message translates to:
  /// **'Deposit Date'**
  String get settlement_date_label;

  /// Label for remaining unpaid balance
  ///
  /// In en, this message translates to:
  /// **'Unpaid Due (Carried Forward)'**
  String get settlement_diff_label;

  /// Badge text when salary is fully settled
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get settlement_fully_paid_badge;

  /// Badge text when salary is partially settled
  ///
  /// In en, this message translates to:
  /// **'Partial Payment'**
  String get settlement_partial_badge;

  /// Bikram Sambat calendar mode toggle
  ///
  /// In en, this message translates to:
  /// **'Nepali (BS)'**
  String get settlement_calendar_bs;

  /// Gregorian calendar mode toggle
  ///
  /// In en, this message translates to:
  /// **'English (AD)'**
  String get settlement_calendar_ad;

  /// Button to open calendar picker
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get settlement_pick_date;

  /// Title on fuel bill records tile
  ///
  /// In en, this message translates to:
  /// **'Fuel Bill Records'**
  String get fuel_records_tile_title;

  /// Subtitle showing last fuel bill end date
  ///
  /// In en, this message translates to:
  /// **'Last bill ended: {date}'**
  String fuel_records_tile_lastEnded(String date);

  /// Subtitle when no fuel bill exists
  ///
  /// In en, this message translates to:
  /// **'No fuel bill yet'**
  String get fuel_records_tile_noBills;

  /// Title on fuel bill records dialog
  ///
  /// In en, this message translates to:
  /// **'Fuel Bill Records'**
  String get fuel_records_dialog_title;

  /// Card title for cutoff date block
  ///
  /// In en, this message translates to:
  /// **'Last Fuel Bill End Date'**
  String get fuel_records_dialog_lastEndedTitle;

  /// Description under cutoff date
  ///
  /// In en, this message translates to:
  /// **'This is the last date your previous fuel bill ended. Edit it if there was a mistake.'**
  String get fuel_records_dialog_lastEndedHint;

  /// Button to edit cutoff date
  ///
  /// In en, this message translates to:
  /// **'Edit Date'**
  String get fuel_records_dialog_editDateButton;

  /// Primary action to generate a new fuel bill
  ///
  /// In en, this message translates to:
  /// **'Generate Fuel Bill'**
  String get fuel_records_dialog_generateBillButton;

  /// Section header for history table
  ///
  /// In en, this message translates to:
  /// **'Bill History'**
  String get fuel_records_dialog_historyTitle;

  /// Count of existing records
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String fuel_records_dialog_recordsCount(int count);

  /// Empty state message when no bills exist
  ///
  /// In en, this message translates to:
  /// **'No fuel bill records found.'**
  String get fuel_records_dialog_emptyState;

  /// Table column for date period
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get fuel_records_col_period;

  /// Table column for total KM
  ///
  /// In en, this message translates to:
  /// **'Total KM'**
  String get fuel_records_col_totalKm;

  /// Table column for expected liters
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get fuel_records_col_expectedLiters;

  /// Table column for actual liters
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get fuel_records_col_actualLiters;

  /// Title for monthly vehicle running summary table
  ///
  /// In en, this message translates to:
  /// **'Monthly Running Summary'**
  String get km_summary_table_title;

  /// Date column header
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get km_summary_col_date;

  /// Start odometer reading column header
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get km_summary_col_start;

  /// End odometer reading column header
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get km_summary_col_end;

  /// Total distance run column header
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get km_summary_col_total;

  /// Empty state when no KM is recorded
  ///
  /// In en, this message translates to:
  /// **'No odometer records for this month'**
  String get km_summary_empty;

  /// Total summary label for the month
  ///
  /// In en, this message translates to:
  /// **'Month Total'**
  String get km_summary_month_total;

  /// Title of modal to generate fuel bill
  ///
  /// In en, this message translates to:
  /// **'Generate Fuel Bill'**
  String get generate_fuel_dialog_title;

  /// Section label for last bill end date
  ///
  /// In en, this message translates to:
  /// **'Last Bill Ended On'**
  String get generate_fuel_dialog_lastEnded;

  /// Hint text for previous bill end date
  ///
  /// In en, this message translates to:
  /// **'Previous bill ended on this date'**
  String get generate_fuel_dialog_lastEndedHint;

  /// Label for bill start date
  ///
  /// In en, this message translates to:
  /// **'Bill Start Date (From)'**
  String get generate_fuel_dialog_startDate;

  /// Explanation of start date calculation
  ///
  /// In en, this message translates to:
  /// **'Auto-calculated as day after last bill (edit last bill date to change this)'**
  String get generate_fuel_dialog_startDateHint;

  /// Label for bill end date picker
  ///
  /// In en, this message translates to:
  /// **'Bill End Date (To)'**
  String get generate_fuel_dialog_endDate;

  /// Loading state during calculation
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get generate_fuel_dialog_calculating;

  /// Label for period in calculation box
  ///
  /// In en, this message translates to:
  /// **'Period:'**
  String get generate_fuel_dialog_periodLabel;

  /// Label for total KM in calculation box
  ///
  /// In en, this message translates to:
  /// **'Total KM:'**
  String get generate_fuel_dialog_totalKmLabel;

  /// Label for expected fuel calculation
  ///
  /// In en, this message translates to:
  /// **'Expected Fuel (÷ 7.5):'**
  String get generate_fuel_dialog_expectedFuelLabel;

  /// Computed liters value display
  ///
  /// In en, this message translates to:
  /// **'{liters} Liters'**
  String generate_fuel_dialog_litersDisplay(String liters);

  /// Label for actual fuel input
  ///
  /// In en, this message translates to:
  /// **'Actual Fuel Given (Optional)'**
  String get generate_fuel_dialog_actualLitersLabel;

  /// Hint for actual fuel input
  ///
  /// In en, this message translates to:
  /// **'e.g. 45.5'**
  String get generate_fuel_dialog_actualLitersHint;

  /// Helper note under actual fuel field
  ///
  /// In en, this message translates to:
  /// **'Enter the actual liters provided by the company'**
  String get generate_fuel_dialog_actualLitersHelper;

  /// Action button to save fuel bill
  ///
  /// In en, this message translates to:
  /// **'Save Fuel Bill'**
  String get generate_fuel_dialog_saveButton;

  /// Saving state on fuel bill action button
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get generate_fuel_dialog_savingButton;

  /// Quick action title to create fuel bill
  ///
  /// In en, this message translates to:
  /// **'Generate Fuel Bill'**
  String get quick_actions_fuelBill_title;

  /// Quick action subtitle to create fuel bill
  ///
  /// In en, this message translates to:
  /// **'Calculate fuel consumption'**
  String get quick_actions_fuelBill_subtitle;

  /// Quick action title to download PDF
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get quick_actions_downloadPdf_title;

  /// Quick action subtitle to download PDF
  ///
  /// In en, this message translates to:
  /// **'PDF format (up to today)'**
  String get quick_actions_downloadPdf_subtitle;

  /// Header title on PDF export
  ///
  /// In en, this message translates to:
  /// **'Bolero Attendance System'**
  String get pdf_report_systemTitle;

  /// Subtitle on PDF export
  ///
  /// In en, this message translates to:
  /// **'Monthly Details Sheet'**
  String get pdf_report_sheetTitle;

  /// Timestamp on PDF export
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String pdf_report_generatedDate(String date);

  /// Section header on PDF for earnings
  ///
  /// In en, this message translates to:
  /// **'Earning Sheet'**
  String get pdf_report_earningSection;

  /// Section header on PDF for fuel bills
  ///
  /// In en, this message translates to:
  /// **'Fuel Bill Records'**
  String get pdf_report_fuelSection;

  /// Section header on PDF for final summary
  ///
  /// In en, this message translates to:
  /// **'Final Settlement'**
  String get pdf_report_finalSettlementSection;

  /// PDF serial number column
  ///
  /// In en, this message translates to:
  /// **'SN'**
  String get pdf_report_col_sn;

  /// PDF BS date column
  ///
  /// In en, this message translates to:
  /// **'BS Date'**
  String get pdf_report_col_bsDate;

  /// PDF AD date column
  ///
  /// In en, this message translates to:
  /// **'AD Date'**
  String get pdf_report_col_adDate;

  /// PDF attendance status column
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pdf_report_col_status;

  /// PDF starting KM column
  ///
  /// In en, this message translates to:
  /// **'Start KM'**
  String get pdf_report_col_startKm;

  /// PDF ending KM column
  ///
  /// In en, this message translates to:
  /// **'End KM'**
  String get pdf_report_col_endKm;

  /// PDF total KM column
  ///
  /// In en, this message translates to:
  /// **'Total KM'**
  String get pdf_report_col_totalKm;

  /// PDF extra trip column
  ///
  /// In en, this message translates to:
  /// **'Extra Trip'**
  String get pdf_report_col_extraTrip;

  /// PDF note column
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get pdf_report_col_note;

  /// PDF total present count
  ///
  /// In en, this message translates to:
  /// **'Total Present Days = {days}'**
  String pdf_report_totalPresentDays(String days);

  /// PDF replacement days count
  ///
  /// In en, this message translates to:
  /// **'Replacement Days = {days}'**
  String pdf_report_totalReplacementDays(String days);

  /// PDF absent days count
  ///
  /// In en, this message translates to:
  /// **'Absent Days = {days}'**
  String pdf_report_totalAbsentDays(String days);

  /// PDF gross earnings line
  ///
  /// In en, this message translates to:
  /// **'Gross Earnings'**
  String get pdf_report_grossEarnings;

  /// PDF TDS tax deduction line
  ///
  /// In en, this message translates to:
  /// **'TDS Deduction (1.5%)'**
  String get pdf_report_tdsDeduction;

  /// PDF final net payable amount
  ///
  /// In en, this message translates to:
  /// **'Net Payable'**
  String get pdf_report_netPayable;

  /// PDF calculation note
  ///
  /// In en, this message translates to:
  /// **'Calculated by earning from total present days - Replace Days'**
  String get pdf_report_formulaExplanation;

  /// PDF page footer
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pdf_report_pageNumber(int page, int total);

  /// Toast message on tapping a future date
  ///
  /// In en, this message translates to:
  /// **'You cannot mark attendance for future dates'**
  String get toast_futureDateError;

  /// Toast message when attendance is deleted
  ///
  /// In en, this message translates to:
  /// **'Attendance deleted'**
  String get toast_deleteSuccess;

  /// Toast message when delete fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String toast_deleteFailed(String error);

  /// Toast message when save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String toast_saveFailed(String error);

  /// Toast message when KM is saved
  ///
  /// In en, this message translates to:
  /// **'KM entry saved ({km} km)'**
  String toast_kmSaved(String km);

  /// Toast message when saving KM fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save KM: {error}'**
  String toast_kmFailed(String error);

  /// Toast message when extra trip is saved
  ///
  /// In en, this message translates to:
  /// **'Extra trip saved'**
  String get toast_extraTripSaved;

  /// Toast message when saving extra trip fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save extra trip: {error}'**
  String toast_extraTripFailed(String error);

  /// Toast message when cutoff date is updated
  ///
  /// In en, this message translates to:
  /// **'Last bill date updated successfully'**
  String get toast_lastBillDateUpdated;

  /// Toast message when cutoff date update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update last bill date'**
  String get toast_lastBillDateFailed;

  /// Toast message when fuel bill is created
  ///
  /// In en, this message translates to:
  /// **'Fuel bill created successfully'**
  String get fuel_bill_created_success;

  /// Toast message when fuel bill creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create fuel bill'**
  String get fuel_bill_created_failed;

  /// Toast message when PDF is generated
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded successfully'**
  String get toast_pdfGenerated;

  /// Toast message when PDF generation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF: {error}'**
  String toast_pdfFailed(String error);

  /// Generic fallback error toast
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get toast_genericError;

  /// Network connectivity error toast
  ///
  /// In en, this message translates to:
  /// **'Network error, please check connection'**
  String get toast_networkError;

  /// API error mapping for bad login
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get error_invalidCredentials;

  /// API error mapping for expired auth token
  ///
  /// In en, this message translates to:
  /// **'Session expired, please sign in again'**
  String get error_sessionExpired;

  /// API error mapping for 401/403
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access'**
  String get error_unauthorized;

  /// API error mapping for 500 server error
  ///
  /// In en, this message translates to:
  /// **'Server error, please try again later'**
  String get error_serverError;

  /// Title for app update dialog
  ///
  /// In en, this message translates to:
  /// **'New Update Available'**
  String get update_available_title;

  /// Description for app update dialog
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available. Update now to get the latest features and improvements.'**
  String update_available_desc(String version);

  /// Button to trigger update download
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get update_btn_update;

  /// Button to dismiss update dialog
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get update_btn_later;

  /// Progress message during update download
  ///
  /// In en, this message translates to:
  /// **'Downloading update: {percent}%'**
  String update_downloading(String percent);

  /// Message when update APK is ready to install
  ///
  /// In en, this message translates to:
  /// **'Installing update...'**
  String get update_installing;

  /// Error fallback message for update download
  ///
  /// In en, this message translates to:
  /// **'Update download failed. Tap to open in browser.'**
  String get update_failed;

  /// Message when app is already at newest version
  ///
  /// In en, this message translates to:
  /// **'Bolero Attendance is up to date (v{version})'**
  String update_up_to_date(String version);

  /// Drawer menu item to check for app updates
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get drawer_check_updates;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
