/// Domain entity representing month-end bank salary settlement.
class MonthlySettlement {
  final int? id;
  final int bsYear;
  final int bsMonthIndex;
  final int expectedAmount;
  final int bankReceivedAmount;
  final String settlementStatus;
  final String? paymentDate;
  final String? note;

  const MonthlySettlement({
    this.id,
    required this.bsYear,
    required this.bsMonthIndex,
    required this.expectedAmount,
    this.bankReceivedAmount = 0,
    this.settlementStatus = 'unsettled',
    this.paymentDate,
    this.note,
  });

  /// The unpaid balance or deficit for the month.
  int get pendingAmount => (expectedAmount - bankReceivedAmount).clamp(0, 99999999);

  /// True if company paid the full expected salary or more into the bank.
  bool get isFullySettled => bankReceivedAmount >= expectedAmount && bankReceivedAmount > 0;

  /// True if company deposited a partial amount leaving a remaining due.
  bool get isPartiallySettled => bankReceivedAmount > 0 && bankReceivedAmount < expectedAmount;

  /// True if no bank deposit has been recorded yet.
  bool get isUnsettled => bankReceivedAmount <= 0;

  factory MonthlySettlement.fromJson(Map<String, dynamic> json) {
    return MonthlySettlement(
      id: (json['id'] as num?)?.toInt(),
      bsYear: (json['bs_year'] as num).toInt(),
      bsMonthIndex: (json['bs_month_index'] as num).toInt(),
      expectedAmount: (json['expected_amount'] as num?)?.toInt() ?? 0,
      bankReceivedAmount: (json['bank_received_amount'] as num?)?.toInt() ?? 0,
      settlementStatus: json['settlement_status'] as String? ?? 'unsettled',
      paymentDate: json['payment_date'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'bs_year': bsYear,
      'bs_month_index': bsMonthIndex,
      'expected_amount': expectedAmount,
      'bank_received_amount': bankReceivedAmount,
      'settlement_status': settlementStatus,
      'payment_date': paymentDate,
      'note': note,
    };
  }

  MonthlySettlement copyWith({
    int? id,
    int? bsYear,
    int? bsMonthIndex,
    int? expectedAmount,
    int? bankReceivedAmount,
    String? settlementStatus,
    String? paymentDate,
    String? note,
  }) {
    return MonthlySettlement(
      id: id ?? this.id,
      bsYear: bsYear ?? this.bsYear,
      bsMonthIndex: bsMonthIndex ?? this.bsMonthIndex,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      bankReceivedAmount: bankReceivedAmount ?? this.bankReceivedAmount,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
    );
  }
}

