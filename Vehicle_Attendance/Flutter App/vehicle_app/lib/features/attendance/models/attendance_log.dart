/// Represents the attendance status of a vehicle for a given day.
enum AttendanceStatus {
  present,
  absentHoliday,
  absentReplacement;

  String toApiValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absentHoliday:
        return 'absent_holiday';
      case AttendanceStatus.absentReplacement:
        return 'absent_replacement';
    }
  }

  static AttendanceStatus fromApiValue(String? value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent_replacement':
        return AttendanceStatus.absentReplacement;
      case 'absent_holiday':
      default:
        return AttendanceStatus.absentHoliday;
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absentHoliday:
        return 'Holiday';
      case AttendanceStatus.absentReplacement:
        return 'Replace';
    }
  }

  String get nepaliDisplayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'उपस्थित';
      case AttendanceStatus.absentHoliday:
        return 'विदा';
      case AttendanceStatus.absentReplacement:
        return 'सट्टा';
    }
  }
}

/// Domain entity representing a daily vehicle attendance log.
class AttendanceLog {
  final String logDate; // YYYY-MM-DD
  final AttendanceStatus status;
  final int extraTripIncome;
  final int? extraTipAmount;
  final String? extraTipNote;
  final int? kmStart;
  final int? kmEnd;
  final int? kmTotal;
  final bool isUnselected;

  const AttendanceLog({
    required this.logDate,
    required this.status,
    this.extraTripIncome = 0,
    this.extraTipAmount = 0,
    this.extraTipNote,
    this.kmStart,
    this.kmEnd,
    this.kmTotal,
    this.isUnselected = false,
  });

  /// Factory creating an unselected placeholder entry for a date
  /// matching Next.js `fullMonthLogs` initialization.
  factory AttendanceLog.unselectedPlaceholder(String dateStr) {
    return AttendanceLog(
      logDate: dateStr,
      status: AttendanceStatus.absentHoliday,
      extraTripIncome: 0,
      extraTipAmount: 0,
      extraTipNote: null,
      kmStart: null,
      kmEnd: null,
      kmTotal: null,
      isUnselected: true,
    );
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      logDate: json['log_date'] as String,
      status: AttendanceStatus.fromApiValue(json['status'] as String?),
      extraTripIncome: (json['extra_trip_income'] as num?)?.toInt() ?? 0,
      extraTipAmount: (json['extra_tip_amount'] as num?)?.toInt() ?? 0,
      extraTipNote: json['extra_tip_note'] as String?,
      kmStart: (json['km_start'] as num?)?.toInt(),
      kmEnd: (json['km_end'] as num?)?.toInt(),
      kmTotal: (json['km_total'] as num?)?.toInt(),
      isUnselected: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_date': logDate,
      'status': status.toApiValue(),
      'extra_trip_income': extraTripIncome,
      'extra_tip_amount': extraTipAmount ?? 0,
      'extra_tip_note': extraTipNote,
      'km_start': kmStart,
      'km_end': kmEnd,
      'km_total': kmTotal,
    };
  }

  AttendanceLog copyWith({
    String? logDate,
    AttendanceStatus? status,
    int? extraTripIncome,
    int? extraTipAmount,
    String? extraTipNote,
    int? kmStart,
    int? kmEnd,
    int? kmTotal,
    bool? isUnselected,
  }) {
    return AttendanceLog(
      logDate: logDate ?? this.logDate,
      status: status ?? this.status,
      extraTripIncome: extraTripIncome ?? this.extraTripIncome,
      extraTipAmount: extraTipAmount ?? this.extraTipAmount,
      extraTipNote: extraTipNote ?? this.extraTipNote,
      kmStart: kmStart ?? this.kmStart,
      kmEnd: kmEnd ?? this.kmEnd,
      kmTotal: kmTotal ?? this.kmTotal,
      isUnselected: isUnselected ?? this.isUnselected,
    );
  }

  @override
  String toString() =>
      'AttendanceLog(date: $logDate, status: ${status.name}, isUnselected: $isUnselected, extraTrip: $extraTripIncome, tip: $extraTipAmount, km: $kmTotal)';
}

