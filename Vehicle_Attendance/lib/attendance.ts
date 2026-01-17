export type AttendanceStatus = 'present' | 'absent_holiday' | 'absent_replacement';

export interface AttendanceLog {
  /**
   * ISO date string in the format YYYY-MM-DD, maps to Supabase log_date.
   */
  log_date: string;
  status: AttendanceStatus;
  /**
   * Extra income for additional trips done on a Present day.
   */
  extra_trip_income: number;
  /**
   * Expected extra tip amount (tracked separately from salary).
   */
  extra_tip_amount?: number | null;
  /**
   * Short note about where the tip came from.
   */
  extra_tip_note?: string | null;
  /**
   * Starting kilometer reading for the day.
   */
  km_start?: number | null;
  /**
   * Ending kilometer reading for the day.
   */
  km_end?: number | null;
  /**
   * Total kilometers run for the day (km_end - km_start).
   */
  km_total?: number | null;
}

export interface MonthlySummary {
  totalPresentDays: number;
  totalReplacementDays: number;
  totalExtraIncome: number;
  totalExtraTips: number;
  totalKm: number;
  grossIncome: number;
  totalDeductions: number;
  netIncome: number;
}

export interface FuelBill {
  id?: number;
  start_date: string; // YYYY-MM-DD
  end_date: string; // YYYY-MM-DD
  total_km: number;
  expected_liters: number;
  actual_liters?: number | null;
  created_at?: string;
}

export const DAILY_WAGE = 1200;
export const REPLACEMENT_DEDUCTION = 3000;

export function calculateMonthlySummary(logs: AttendanceLog[]): MonthlySummary {
  let totalPresentDays = 0;
  let totalReplacementDays = 0;
  let totalExtraIncome = 0;
   let totalExtraTips = 0;
   let totalKm = 0;

  for (const log of logs) {
    if (log.status === 'present') {
      totalPresentDays += 1;
      totalExtraIncome += Number(log.extra_trip_income || 0);
    } else if (log.status === 'absent_replacement') {
      totalReplacementDays += 1;
    }

    totalExtraTips += Number((log.extra_tip_amount ?? 0) || 0);
    totalKm += Number((log.km_total ?? 0) || 0);
  }

  const grossIncome = totalPresentDays * DAILY_WAGE + totalExtraIncome;
  const totalDeductions = totalReplacementDays * REPLACEMENT_DEDUCTION;
  const netIncome = grossIncome - totalDeductions;

  return {
    totalPresentDays,
    totalReplacementDays,
    totalExtraIncome,
    totalExtraTips,
    totalKm,
    grossIncome,
    totalDeductions,
    netIncome,
  };
}
