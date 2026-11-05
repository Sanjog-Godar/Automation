/// Model representing a vehicle fuel bill record.
/// Corresponds to Supabase `fuel_bills` table and `/api/fuel-bills`.
class FuelBill {
  final int id;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final int totalKm;
  final double expectedLiters;
  final double? actualLiters;
  final DateTime? createdAt;

  const FuelBill({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalKm,
    required this.expectedLiters,
    this.actualLiters,
    this.createdAt,
  });

  factory FuelBill.fromJson(Map<String, dynamic> json) {
    return FuelBill(
      id: json['id'] as int,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      totalKm: (json['total_km'] as num).toInt(),
      expectedLiters: (json['expected_liters'] as num).toDouble(),
      actualLiters: json['actual_liters'] != null
          ? (json['actual_liters'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate,
      'end_date': endDate,
      'total_km': totalKm,
      'expected_liters': expectedLiters,
      'actual_liters': actualLiters,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

