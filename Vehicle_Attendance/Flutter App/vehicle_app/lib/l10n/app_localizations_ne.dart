// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get app_name => 'सवारी साधन उपस्थिति';

  @override
  String get common_language_selector_label => 'Language / भाषा';

  @override
  String get common_english => 'English';

  @override
  String get common_nepali => 'नेपाली';

  @override
  String get common_cancel => 'रद्द गर्नुहोस्';

  @override
  String get common_save => 'सुरक्षित गर्नुहोस्';

  @override
  String get common_edit => 'सम्पादन';

  @override
  String get common_close => 'बन्द गर्नुहोस्';

  @override
  String get common_add => '+ थप्नुहोस्';

  @override
  String get common_loading => 'लोड हुँदैछ...';

  @override
  String get common_saving => 'सुरक्षित हुँदैछ...';

  @override
  String get common_currency_rs => 'रु.';

  @override
  String get common_unit_km => 'कि.मि.';

  @override
  String get common_unit_liters => 'लिटर';

  @override
  String get common_unit_l => 'लि.';

  @override
  String get auth_login_title => 'सवारी साधन उपस्थिति';

  @override
  String get auth_login_subtitle => 'ड्यासबोर्ड हेर्न लग-इन गर्नुहोस्';

  @override
  String get auth_login_emailLabel => 'इमेल ठेगाना';

  @override
  String get auth_login_emailHint => 'your@email.com';

  @override
  String get auth_login_emailRequired => 'इमेल अनिवार्य छ';

  @override
  String get auth_login_emailInvalid => 'मान्य इमेल ठेगाना प्रविष्ट गर्नुहोस्';

  @override
  String get auth_login_passwordLabel => 'पासवर्ड';

  @override
  String get auth_login_passwordHint => '••••••••';

  @override
  String get auth_login_passwordRequired => 'पासवर्ड अनिवार्य छ';

  @override
  String get auth_login_passwordMinLength =>
      'पासवर्ड कम्तिमा ६ अक्षरको हुनुपर्छ';

  @override
  String get auth_login_rememberMe => 'मलाई सम्झनुहोस्';

  @override
  String get auth_login_signInButton => 'लग-इन गर्नुहोस्';

  @override
  String get auth_login_signingInButton => 'लग-इन हुँदैछ...';

  @override
  String dashboard_appbar_subtitle(
    String monthName,
    String year,
    String englishRange,
  ) {
    return '$monthName $year ($englishRange)';
  }

  @override
  String get dashboard_drawer_title => 'सवारी साधन उपस्थिति प्रणाली';

  @override
  String get dashboard_drawer_nav_dashboard => 'ड्यासबोर्ड';

  @override
  String get dashboard_drawer_nav_fuelBills => 'ईन्धन बिल रेकर्ड';

  @override
  String get dashboard_drawer_nav_downloadReport => 'रिपोर्ट डाउनलोड (PDF)';

  @override
  String get dashboard_drawer_nav_signOut => 'बाहिरिनुहोस्';

  @override
  String get dashboard_signOut_dialogTitle => 'बाहिरिनुहोस्';

  @override
  String get dashboard_signOut_dialogMessage =>
      'के तपाईं सवारी साधन उपस्थिति प्रणालीबाट बाहिरिन चाहनुहुन्छ?';

  @override
  String get dashboard_bottomNav_home => 'गृहपृष्ठ';

  @override
  String get dashboard_bottomNav_calendar => 'पात्रो';

  @override
  String get summary_card_title => 'मासिक सारांश';

  @override
  String get summary_presentDays => 'उपस्थित दिन';

  @override
  String get summary_replacementDays => 'सट्टा दिन';

  @override
  String get summary_totalKm => 'जम्मा किलोमिटर';

  @override
  String get summary_extraTrips => 'अतिरिक्त आम्दानी (रु.)';

  @override
  String get summary_deductions => 'कटौती (रु.)';

  @override
  String get summary_netIncome => 'खुद आम्दानी (रु.)';

  @override
  String get summary_netIncomeFormula => 'आम्दानी - कटौती';

  @override
  String get summary_deductions_exceed => 'कटौती आम्दानीभन्दा बढी छ';

  @override
  String get summary_earnings => 'आम्दानी';

  @override
  String get summary_sec_attendance => 'उपस्थिति';

  @override
  String get summary_sec_performance => 'कार्य सम्पादन';

  @override
  String get summary_unit_days => 'दिन';

  @override
  String get summary_present_label => 'उपस्थित';

  @override
  String get summary_replacement_label => 'सट्टा';

  @override
  String get summary_distance_run => 'चलेको दुरी';

  @override
  String get calendar_todayChip => 'आज';

  @override
  String get calendar_prevMonthTooltip => 'अघिल्लो महिना';

  @override
  String get calendar_nextMonthTooltip => 'अर्को महिना';

  @override
  String calendar_missingDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिनको डाटा बाँकी छ',
      one: '१ दिनको डाटा बाँकी छ',
      zero: 'सबै दिनको विवरण भरिएको छ',
    );
    return '$_temp0';
  }

  @override
  String get calendar_legend_present => 'उपस्थित';

  @override
  String get calendar_legend_holiday => 'बिदा';

  @override
  String get calendar_legend_replace => 'सट्टा';

  @override
  String get calendar_legend_missingStatus => 'अवस्था बाँकी';

  @override
  String get calendar_legend_missingKm => 'किलोमिटर बाँकी';

  @override
  String get calendar_legend_today => 'आज';

  @override
  String calendar_semantics_day(
    String nepaliDay,
    String nepaliMonth,
    String status,
    String kmTotal,
  ) {
    return '$nepaliDay $nepaliMonth, $status, $kmTotal किलोमिटर';
  }

  @override
  String get status_present => 'उपस्थित';

  @override
  String get status_holiday => 'बिदा';

  @override
  String get status_replace => 'सट्टा';

  @override
  String get status_unselected => 'बाँकी';

  @override
  String get status_presentRate => 'रु. १,२००';

  @override
  String get status_holidaySubtitle => 'तलब नपाउने';

  @override
  String get status_replaceDeduction => '-रु. ३,०००';

  @override
  String get day_sheet_missingStatusAlert =>
      'यस मितिको अवस्था चयन गर्न बाँकी छ';

  @override
  String get day_sheet_missingKmAlert => 'किलोमिटर प्रविष्टि गर्न बाँकी छ';

  @override
  String get day_sheet_attendanceStatusTitle => 'उपस्थिति स्थिति';

  @override
  String get day_sheet_detailsRecordsTitle => 'विवरण तथा रेकर्ड';

  @override
  String get day_sheet_enterKmTitle => 'किलोमिटर प्रविष्ट गर्नुहोस्';

  @override
  String get day_sheet_enterKmSubtitle => 'सुरु र अन्तिम मिटरको अंक';

  @override
  String get day_sheet_extraTripTitle => 'अतिरिक्त आम्दानी';

  @override
  String get day_sheet_extraTripSubtitle => 'आजको अतिरिक्त आम्दानी';

  @override
  String get km_sheet_title => 'ओडोमिटर किलोमिटर';

  @override
  String get km_sheet_subtitle => 'सुरु र अन्तिम रिडिङ प्रविष्ट गर्नुहोस्';

  @override
  String get km_sheet_startKmLabel => 'सुरुको किलोमिटर';

  @override
  String get km_sheet_startKmHint => 'जस्तै: १०२४०';

  @override
  String get km_sheet_endKmLabel => 'अन्तिम किलोमिटर';

  @override
  String get km_sheet_endKmHint => 'जस्तै: १०३२०';

  @override
  String km_sheet_totalRun(String km) {
    return 'जम्मा चलेको: $km कि.मि.';
  }

  @override
  String get km_sheet_saveButton => 'किलोमिटर सुरक्षित गर्नुहोस्';

  @override
  String get km_sheet_validationRequired =>
      'सुरु र अन्तिम दुबै किलोमिटर आवश्यक छ';

  @override
  String get km_sheet_validationEndLessThanStart =>
      'अन्तिम किलोमिटर सुरुभन्दा कम हुन सक्दैन';

  @override
  String get trip_dialog_title => 'अतिरिक्त टिप विवरण';

  @override
  String get trip_dialog_subtitle =>
      'यो टिप कहाँबाट र कति रकम अपेक्षा गरिएको हो उल्लेख गर्नुहोस्।';

  @override
  String get trip_dialog_locationLabel => 'टिप कहाँको थियो?';

  @override
  String get trip_dialog_upayeToggle => 'उपाय हो ?';

  @override
  String get upaye_badge => 'उपाय';

  @override
  String get trip_dialog_locationHint => 'जस्तै: साँझको बजार, विशेष यात्रा';

  @override
  String get trip_dialog_amountLabel => 'अपेक्षित टिप रकम (रु.)';

  @override
  String get trip_dialog_amountHint => '०';

  @override
  String get trip_dialog_save => 'टिप सुरक्षित गर्नुहोस्';

  @override
  String get trip_dialog_validationRequired => 'रकम अनिवार्य छ';

  @override
  String get tips_record_title => 'टिप रेकर्ड';

  @override
  String get tips_record_noNote => 'कुनै गन्तव्य छैन';

  @override
  String get fuel_records_tile_title => 'ईन्धन बिल रेकर्ड';

  @override
  String fuel_records_tile_lastEnded(String date) {
    return 'अन्तिम बिल मिति: $date';
  }

  @override
  String get fuel_records_tile_noBills => 'कुनै ईन्धन बिल छैन';

  @override
  String get fuel_records_dialog_title => 'ईन्धन बिल रेकर्ड';

  @override
  String get fuel_records_dialog_lastEndedTitle => 'अघिल्लो बिल सकिएको मिति';

  @override
  String get fuel_records_dialog_lastEndedHint =>
      'यो तपाईंको अघिल्लो ईन्धन बिल सकिएको मिति हो। गल्ती भएमा सच्याउनुहोस्।';

  @override
  String get fuel_records_dialog_editDateButton => 'सम्पादन';

  @override
  String get fuel_records_dialog_generateBillButton => 'नयाँ बिल बनाउनुहोस्';

  @override
  String get fuel_records_dialog_historyTitle => 'बिल इतिहास';

  @override
  String fuel_records_dialog_recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count रेकर्ड',
      one: '१ रेकर्ड',
    );
    return '$_temp0';
  }

  @override
  String get fuel_records_dialog_emptyState => 'कुनै ईन्धन बिल रेकर्ड भेटिएन।';

  @override
  String get fuel_records_col_period => 'समयावधि';

  @override
  String get fuel_records_col_totalKm => 'जम्मा कि.मि.';

  @override
  String get fuel_records_col_expectedLiters => 'अनुमानित';

  @override
  String get fuel_records_col_actualLiters => 'प्राप्त';

  @override
  String get km_summary_table_title => 'मासिक गाडी चलेको विवरण';

  @override
  String get km_summary_col_date => 'मिति';

  @override
  String get km_summary_col_start => 'सुरु';

  @override
  String get km_summary_col_end => 'अन्तिम';

  @override
  String get km_summary_col_total => 'जम्मा';

  @override
  String get km_summary_empty => 'यस महिना कुनै किलोमिटर रेकर्ड छैन';

  @override
  String get km_summary_month_total => 'महिनाको जम्मा';

  @override
  String get generate_fuel_dialog_title => 'ईन्धन बिल बनाउनुहोस्';

  @override
  String get generate_fuel_dialog_lastEnded => 'अघिल्लो बिल सकिएको मिति';

  @override
  String get generate_fuel_dialog_lastEndedHint =>
      'अघिल्लो बिल यस मितिमा सकिएको थियो';

  @override
  String get generate_fuel_dialog_startDate => 'बिल सुरु मिति (देखि)';

  @override
  String get generate_fuel_dialog_startDateHint =>
      'अघिल्लो बिलको भोलिपल्टबाट स्वतः गणना गरिएको';

  @override
  String get generate_fuel_dialog_endDate => 'बिल अन्तिम मिति (सम्म)';

  @override
  String get generate_fuel_dialog_calculating => 'गणना हुँदैछ…';

  @override
  String get generate_fuel_dialog_periodLabel => 'समयावधि:';

  @override
  String get generate_fuel_dialog_totalKmLabel => 'जम्मा कि.मि.:';

  @override
  String get generate_fuel_dialog_expectedFuelLabel =>
      'अनुमानित ईन्धन (÷ ७.५):';

  @override
  String generate_fuel_dialog_litersDisplay(String liters) {
    return '$liters लिटर';
  }

  @override
  String get generate_fuel_dialog_actualLitersLabel => 'प्राप्त ईन्धन (ऐच्छिक)';

  @override
  String get generate_fuel_dialog_actualLitersHint => 'जस्तै: ४५.५';

  @override
  String get generate_fuel_dialog_actualLitersHelper =>
      'कम्पनीले उपलब्ध गराएको वास्तविक लिटर प्रविष्ट गर्नुहोस्';

  @override
  String get generate_fuel_dialog_saveButton => 'बिल सुरक्षित गर्नुहोस्';

  @override
  String get generate_fuel_dialog_savingButton => 'सुरक्षित हुँदैछ...';

  @override
  String get quick_actions_fuelBill_title => 'ईन्धन बिल बनाउनुहोस्';

  @override
  String get quick_actions_fuelBill_subtitle => 'ईन्धन खपत गणना गर्नुहोस्';

  @override
  String get quick_actions_downloadPdf_title => 'रिपोर्ट डाउनलोड';

  @override
  String get quick_actions_downloadPdf_subtitle => 'PDF ढाँचामा (आजसम्मको)';

  @override
  String get pdf_report_systemTitle => 'सवारी साधन उपस्थिति प्रणाली';

  @override
  String get pdf_report_sheetTitle => 'मासिक विवरण पाना';

  @override
  String pdf_report_generatedDate(String date) {
    return 'सिर्जना गरिएको: $date';
  }

  @override
  String get pdf_report_earningSection => 'आम्दानी विवरण';

  @override
  String get pdf_report_fuelSection => 'ईन्धन बिल रेकर्ड';

  @override
  String get pdf_report_finalSettlementSection => 'अन्तिम हिसाब मिलान';

  @override
  String get pdf_report_col_sn => 'क्र.सं.';

  @override
  String get pdf_report_col_bsDate => 'नेपाली मिति';

  @override
  String get pdf_report_col_adDate => 'अंग्रेजी मिति';

  @override
  String get pdf_report_col_status => 'अवस्था';

  @override
  String get pdf_report_col_startKm => 'सुरु कि.मि.';

  @override
  String get pdf_report_col_endKm => 'अन्तिम कि.मि.';

  @override
  String get pdf_report_col_totalKm => 'जम्मा कि.मि.';

  @override
  String get pdf_report_col_extraTrip => 'अतिरिक्त आम्दानी';

  @override
  String get pdf_report_col_note => 'कैफियत';

  @override
  String pdf_report_totalPresentDays(String days) {
    return 'जम्मा उपस्थित दिन = $days';
  }

  @override
  String pdf_report_totalReplacementDays(String days) {
    return 'सट्टा दिन = $days';
  }

  @override
  String pdf_report_totalAbsentDays(String days) {
    return 'अनुपस्थित दिन = $days';
  }

  @override
  String get pdf_report_grossEarnings => 'जम्मा आम्दानी';

  @override
  String get pdf_report_tdsDeduction => 'टि.डि.एस. कटौती (१.५%)';

  @override
  String get pdf_report_netPayable => 'खुद भुक्तानी';

  @override
  String get pdf_report_formulaExplanation =>
      'उपस्थित दिनको आम्दानीबाट सट्टा दिनको कटौती घटाई गणना गरिएको';

  @override
  String pdf_report_pageNumber(int page, int total) {
    return 'पृष्ठ $page / $total';
  }

  @override
  String get toast_futureDateError => 'भविष्यको मितिको हाजिरी गर्न मिल्दैन';

  @override
  String get toast_deleteSuccess => 'उपस्थिति मेटाइयो';

  @override
  String toast_deleteFailed(String error) {
    return 'मेट्दा समस्या आयो: $error';
  }

  @override
  String toast_saveFailed(String error) {
    return 'सुरक्षित गर्दा समस्या आयो: $error';
  }

  @override
  String toast_kmSaved(String km) {
    return 'किलोमिटर सुरक्षित गरियो ($km कि.मि.)';
  }

  @override
  String toast_kmFailed(String error) {
    return 'किलोमिटर सुरक्षित गर्न सकिएन: $error';
  }

  @override
  String get toast_extraTripSaved => 'अतिरिक्त आम्दानी सुरक्षित गरियो';

  @override
  String toast_extraTripFailed(String error) {
    return 'अतिरिक्त आम्दानी सुरक्षित गर्न सकिएन: $error';
  }

  @override
  String get toast_lastBillDateUpdated => 'अन्तिम बिल मिति परिवर्तन गरियो';

  @override
  String get toast_lastBillDateFailed => 'अन्तिम बिल मिति परिवर्तन गर्न सकिएन';

  @override
  String get fuel_bill_created_success => 'ईन्धन बिल सिर्जना गरियो';

  @override
  String get fuel_bill_created_failed => 'ईन्धन बिल सिर्जना गर्न सकिएन';

  @override
  String get toast_pdfGenerated => 'PDF सफलतापूर्वक डाउनलोड भयो';

  @override
  String toast_pdfFailed(String error) {
    return 'PDF सिर्जना गर्न समस्या भयो: $error';
  }

  @override
  String get toast_genericError => 'अज्ञात समस्या देखा पर्यो';

  @override
  String get toast_networkError => 'इन्टरनेट कनेक्सन जाँच गर्नुहोस्';

  @override
  String get error_invalidCredentials => 'इमेल वा पासवर्ड मिलेन';

  @override
  String get error_sessionExpired =>
      'सत्र समाप्त भयो, कृपया पुन: लग-इन गर्नुहोस्';

  @override
  String get error_unauthorized => 'पहुँच अस्वीकृत गरियो';

  @override
  String get error_serverError =>
      'सर्भरमा समस्या आयो, कृपया पछि प्रयास गर्नुहोस्';
}
