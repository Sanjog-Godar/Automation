"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { AttendanceLog, AttendanceStatus, FuelBill } from "@/lib/attendance";
import { calculateMonthlySummary, DAILY_WAGE, REPLACEMENT_DEDUCTION } from "@/lib/attendance";
import NepaliDate from "nepali-date-converter";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

const API_BASE = "/api/attendance"; // Next.js App Router API route
const FUEL_BILLS_API = "/api/fuel-bills";

const NEPALI_MONTHS = [
  "बैशाख",
  "जेष्ठ",
  "अषाढ",
  "श्रावण",
  "भाद्र",
  "आश्विन",
  "कार्तिक",
  "मंसिर",
  "पौष",
  "माघ",
  "फाल्गुन",
  "चैत्र",
];

const NEPALI_MONTHS_ENGLISH = [
  "Baisakh",
  "Jestha",
  "Ashadh",
  "Shrawan",
  "Bhadra",
  "Ashwin",
  "Kartik",
  "Mangsir",
  "Poush",
  "Magh",
  "Falgun",
  "Chaitra",
];

// Convert English numbers to Nepali numerals
function toNepaliNumber(num: number): string {
  const nepaliDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  return String(num)
    .split('')
    .map(digit => nepaliDigits[parseInt(digit)])
    .join('');
}

function getCurrentMonthKey() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`; // YYYY-MM
}

function formatDate(year: number, monthIndex: number, day: number): string {
  const y = String(year);
  const m = String(monthIndex + 1).padStart(2, "0");
  const d = String(day).padStart(2, "0");
  return `${y}-${m}-${d}`; // YYYY-MM-DD
}

async function fetchMonthAttendance(monthKey: string): Promise<AttendanceLog[]> {
  const res = await fetch(`${API_BASE}?month=${monthKey}`);
  if (!res.ok) {
    throw new Error("Failed to fetch attendance");
  }
  const json = await res.json();
  return (json.data as AttendanceLog[]) ?? [];
}

async function upsertAttendance(log: AttendanceLog): Promise<AttendanceLog> {
  const res = await fetch(API_BASE, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(log),
  });

  if (!res.ok) {
    throw new Error("Failed to save attendance");
  }
  const json = await res.json();
  return json.data as AttendanceLog;
}

async function deleteAttendance(log_date: string): Promise<void> {
  const res = await fetch(`${API_BASE}?log_date=${log_date}`, {
    method: "DELETE",
  });

  if (!res.ok) {
    throw new Error("Failed to delete attendance");
  }
}

async function fetchFuelBills(): Promise<FuelBill[]> {
  const res = await fetch(FUEL_BILLS_API);
  if (!res.ok) {
    throw new Error("Failed to fetch fuel bills");
  }
  const json = await res.json();
  return (json.data as FuelBill[]) ?? [];
}

async function createFuelBill(bill: Omit<FuelBill, 'id' | 'created_at'>): Promise<FuelBill> {
  const res = await fetch(FUEL_BILLS_API, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(bill),
  });

  if (!res.ok) {
    throw new Error("Failed to create fuel bill");
  }
  const json = await res.json();
  return json.data as FuelBill;
}

interface DayCardProps {
  dateLabel: string;
  nepaliDateLabel: string;
  log: AttendanceLog & { isUnselected?: boolean };
  onChangeStatus: (status: AttendanceStatus) => void;
  onChangeExtra: (extra: number) => void;
   onOpenTip: () => void;
   onOpenKm: () => void;
  isSaving: boolean;
  isToday?: boolean;
  hasMissingData?: boolean;
}

function DayCard({
  dateLabel,
  nepaliDateLabel,
  log,
  onChangeStatus,
  onChangeExtra,
  onOpenTip,
  onOpenKm,
  isSaving,
  isToday = false,
  hasMissingData = false,
}: DayCardProps) {
  const isPresent = log.status === "present";
  const isAbsentHoliday = log.status === "absent_holiday";
  const isAbsentReplacement = log.status === "absent_replacement";
  const isUnselected = log.isUnselected === true;

   const badgeLabel = isUnselected
     ? "—"
     : isPresent
     ? "Present"
     : isAbsentHoliday
     ? "Holiday"
     : "Replace";

   const badgeClass = isUnselected
     ? "bg-gray-100 text-gray-400 border border-gray-300"
     : isPresent
     ? "bg-green-600 text-white"
     : isAbsentHoliday
     ? "bg-red-600 text-white"
     : "bg-orange-600 text-white";

  // Determine border class based on missing data or today
  let borderClass = 'border';
  if (hasMissingData) {
    borderClass = 'border-2 border-red-500';
  } else if (isToday) {
    borderClass = 'border-2 border-blue-300';
  }

  // Determine background class
  let bgClass = 'bg-white';
  if (hasMissingData) {
    bgClass = 'bg-red-50';
  } else if (isToday) {
    bgClass = 'bg-blue-50';
  }

  return (
    <div className={`${borderClass} rounded-lg p-2 flex flex-col justify-between shadow-sm min-h-[110px] ${bgClass}`}>
      <div className="flex items-center justify-between mb-1">
        <div className="flex flex-col">
          <span className="text-sm font-semibold text-gray-800 font-mukta">{nepaliDateLabel}</span>
          <span className="text-[9px] text-gray-500">{dateLabel}</span>
        </div>
        <span
          className={`px-1.5 py-0.5 rounded-full text-[10px] font-semibold ${badgeClass}`}
        >
          {badgeLabel}
        </span>
      </div>

      <div className="flex justify-between gap-1 mb-1">
        <button
          type="button"
          onClick={() => onChangeStatus("present")}
          className={`flex-1 text-[11px] py-1 rounded border transition-colors ${
            isPresent && !isUnselected
              ? "bg-green-600 text-white border-green-600"
              : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          }`}
        >
          P
        </button>
        <button
          type="button"
          onClick={() => onChangeStatus("absent_holiday")}
          className={`flex-1 text-[11px] py-1 rounded border transition-colors ${
            isAbsentHoliday && !isUnselected
              ? "bg-red-600 text-white border-red-600"
              : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          }`}
        >
          H
        </button>
        <button
          type="button"
          onClick={() => onChangeStatus("absent_replacement")}
          className={`flex-1 text-[11px] py-1 rounded border transition-colors ${
            isAbsentReplacement && !isUnselected
              ? "bg-orange-600 text-white border-orange-600"
              : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          }`}
        >
          R
        </button>
      </div>

      {hasMissingData ? (
        <p className="mt-1 text-[10px] text-red-600 leading-snug font-semibold">
          ⚠️ Missing: {isUnselected ? 'Status' : !log.km_total ? 'KM entry' : 'Data'}
        </p>
      ) : isPresent && !isUnselected ? (
        <p className="mt-1 text-[10px] text-green-600 leading-snug font-medium">
          ✓ Marked present (Rs. 1,200)
        </p>
      ) : !isUnselected ? (
        <p className="mt-1 text-[10px] text-gray-500 leading-snug">
          {isAbsentHoliday
            ? "Route holiday (no pay, no deduction)"
            : "Replacement sent (- Rs. 3000)"}
        </p>
      ) : (
        <p className="mt-1 text-[10px] text-gray-400 leading-snug italic">
          No status selected
        </p>
      )}

      <div className="mt-1 flex items-center justify-end gap-2">
        <button
          type="button"
          onClick={onOpenTip}
          className="rounded-full border border-blue-500 px-2 py-0.5 text-[10px] font-medium text-blue-600 hover:bg-blue-50"
        >
          Extra Tip
        </button>
        <button
          type="button"
          onClick={onOpenKm}
          className="rounded-full border border-purple-500 px-2 py-0.5 text-[10px] font-medium text-purple-600 hover:bg-purple-50"
        >
          {log.km_total && log.km_total > 0 ? `${log.km_total} Km` : 'KM'}
        </button>
      </div>

      {isSaving && (
        <span className="mt-1 text-[10px] text-gray-400 self-end">Saving…</span>
      )}
    </div>
  );
}

// Helper function to get current Nepali date
function getCurrentNepaliDate() {
  const nd = new NepaliDate();
  return { year: nd.getYear(), month: nd.getMonth() };
}

export function MonthlyAttendanceClient() {
  const queryClient = useQueryClient();
  
  // Initialize with current Nepali date
  const [currentNepaliYear, setCurrentNepaliYear] = useState(() => getCurrentNepaliDate().year);
  const [currentNepaliMonth, setCurrentNepaliMonth] = useState(() => getCurrentNepaliDate().month);

  const [tipModal, setTipModal] = useState<{
    log_date: string;
    note: string;
    amount: string;
  } | null>(null);

  const [kmModal, setKmModal] = useState<{
    log_date: string;
    km_start: string;
    km_end: string;
  } | null>(null);

  const [fuelBillModal, setFuelBillModal] = useState<{
    start_date: string;
    end_date: string;
    actual_liters: string;
  } | null>(null);

  const [toast, setToast] = useState({
    message: '',
    nepaliMessage: '',
    show: false,
  });

  const showToast = (message: string, nepaliMessage: string) => {
    setToast({ message, nepaliMessage, show: true });
    setTimeout(() => {
      setToast({ message: '', nepaliMessage: '', show: false });
    }, 4000);
  };

  // Get number of days in current Nepali month by finding when the month changes
  const daysInNepaliMonth = useMemo(() => {
    // Try different day counts (Nepali months have 29-32 days)
    for (let day = 32; day >= 29; day--) {
      try {
        const testDate = new NepaliDate(currentNepaliYear, currentNepaliMonth, day);
        if (testDate.getMonth() === currentNepaliMonth) {
          return day;
        }
      } catch {
        continue;
      }
    }
    return 30; // fallback
  }, [currentNepaliYear, currentNepaliMonth]);

  // Generate a unique key for querying (we'll fetch all logs for this Nepali month)
  const nepaliMonthKey = `${currentNepaliYear}-${String(currentNepaliMonth + 1).padStart(2, "0")}`;

  const { data: serverLogs = [], isLoading } = useQuery({
    queryKey: ["attendance", nepaliMonthKey, daysInNepaliMonth],
    queryFn: async () => {
      // Fetch logs for all dates in this Nepali month
      // Convert first and last day of Nepali month to AD to get date range
      const firstNepaliDay = new NepaliDate(currentNepaliYear, currentNepaliMonth, 1);
      const lastNepaliDay = new NepaliDate(currentNepaliYear, currentNepaliMonth, daysInNepaliMonth);
      
      const firstAD = firstNepaliDay.toJsDate();
      const lastAD = lastNepaliDay.toJsDate();
      
      const startMonth = `${firstAD.getFullYear()}-${String(firstAD.getMonth() + 1).padStart(2, "0")}`;
      const endMonth = `${lastAD.getFullYear()}-${String(lastAD.getMonth() + 1).padStart(2, "0")}`;
      
      // Fetch logs for both months if Nepali month spans across two English months
      const logs: AttendanceLog[] = [];
      const months = new Set([startMonth, endMonth]);
      
      for (const month of months) {
        const res = await fetch(`${API_BASE}?month=${month}`);
        if (res.ok) {
          const json = await res.json();
          logs.push(...(json.data as AttendanceLog[] ?? []));
        }
      }
      
      return logs;
    },
    staleTime: 30000, // Cache for 30 seconds
    refetchOnWindowFocus: false, // Don't refetch on window focus
  });

  // Fetch fuel bills
  const { data: fuelBills = [] } = useQuery({
    queryKey: ["fuelBills"],
    queryFn: fetchFuelBills,
    staleTime: 30000,
  });

  const mutation = useMutation({
    mutationFn: upsertAttendance,
    onMutate: async (newLog: AttendanceLog) => {
      await queryClient.cancelQueries({ queryKey: ["attendance", nepaliMonthKey, daysInNepaliMonth] });
      const previous =
        (queryClient.getQueryData<AttendanceLog[]>(["attendance", nepaliMonthKey, daysInNepaliMonth]) ?? []);

      const updated = [
        ...previous.filter((l) => l.log_date !== newLog.log_date),
        newLog,
      ];

      queryClient.setQueryData(["attendance", nepaliMonthKey, daysInNepaliMonth], updated);

      return { previous };
    },
    onError: (_err, _newLog, context) => {
      if (context?.previous) {
        queryClient.setQueryData(["attendance", nepaliMonthKey, daysInNepaliMonth], context.previous);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["attendance", nepaliMonthKey, daysInNepaliMonth] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteAttendance,
    onMutate: async (log_date: string) => {
      await queryClient.cancelQueries({ queryKey: ["attendance", nepaliMonthKey, daysInNepaliMonth] });
      const previous =
        (queryClient.getQueryData<AttendanceLog[]>(["attendance", nepaliMonthKey, daysInNepaliMonth]) ?? []);

      const updated = previous.filter((l) => l.log_date !== log_date);

      queryClient.setQueryData(["attendance", nepaliMonthKey, daysInNepaliMonth], updated);

      return { previous };
    },
    onError: (_err, _log_date, context) => {
      if (context?.previous) {
        queryClient.setQueryData(["attendance", nepaliMonthKey, daysInNepaliMonth], context.previous);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["attendance", nepaliMonthKey, daysInNepaliMonth] });
    },
  });

  const fuelBillMutation = useMutation({
    mutationFn: createFuelBill,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["fuelBills"] });
    },
  });

  // Build logs for each Nepali day of the month
  const fullMonthLogs: AttendanceLog[] = useMemo(() => {
    const byDate = new Map(serverLogs.map((l) => [l.log_date, l] as const));
    const result: AttendanceLog[] = [];

    for (let nepaliDay = 1; nepaliDay <= daysInNepaliMonth; nepaliDay++) {
      // Convert Nepali date to AD
      const nepaliDateObj = new NepaliDate(currentNepaliYear, currentNepaliMonth, nepaliDay);
      const adDate = nepaliDateObj.toJsDate();
      const dateStr = formatDate(adDate.getFullYear(), adDate.getMonth(), adDate.getDate());
      
      const existing = byDate.get(dateStr);
      if (existing) {
        // If record exists in database, it's user-selected (NOT unselected)
        result.push({
          ...existing,
          isUnselected: false,
        });
      } else {
        // If record doesn't exist in database, it's truly unselected
        result.push({
          log_date: dateStr,
          status: "absent_holiday" as AttendanceStatus,
          extra_trip_income: 0,
          extra_tip_amount: 0,
          extra_tip_note: null,
          isUnselected: true,
        });
      }
    }

    return result;
  }, [serverLogs, daysInNepaliMonth, currentNepaliYear, currentNepaliMonth]);

  const summary = useMemo(
    () => calculateMonthlySummary(fullMonthLogs),
    [fullMonthLogs]
  );

  const tipsList = useMemo(() => {
    return fullMonthLogs
      .filter((log) => log.extra_tip_amount && log.extra_tip_amount > 0)
      .map((log) => ({
        date: log.log_date,
        note: log.extra_tip_note || "No destination",
        amount: log.extra_tip_amount || 0,
      }));
  }, [fullMonthLogs]);

  const kmList = useMemo(() => {
    return fullMonthLogs
      .filter((log) => log.km_total && log.km_total > 0)
      .map((log) => ({
        date: log.log_date,
        km_start: log.km_start || 0,
        km_end: log.km_end || 0,
        km_total: log.km_total || 0,
      }));
  }, [fullMonthLogs]);

  // Build a calendar-style grid: Sunday first, with leading/trailing blanks.
  // Get the day of week for the first day of the Nepali month
  const { firstDayOfWeek, calendarCells } = useMemo(() => {
    const firstNepaliDayOfMonth = new NepaliDate(currentNepaliYear, currentNepaliMonth, 1);
    const firstADDate = firstNepaliDayOfMonth.toJsDate();
    const firstDay = firstADDate.getDay(); // 0 (Sun) - 6 (Sat)

    const cells: (AttendanceLog | null)[] = [];

    // Leading empty cells before the 1st day of the month
    for (let i = 0; i < firstDay; i++) {
      cells.push(null);
    }

    // Actual days of the month
    for (const log of fullMonthLogs) {
      cells.push(log);
    }

    // Trailing empty cells to complete the last week row
    while (cells.length % 7 !== 0) {
      cells.push(null);
    }

    return { firstDayOfWeek: firstDay, calendarCells: cells };
  }, [fullMonthLogs, currentNepaliYear, currentNepaliMonth]);

  const handleStatusChange = (log_date: string, status: AttendanceStatus) => {
    // Check if the date is in the future
    const selectedDate = new Date(log_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    selectedDate.setHours(0, 0, 0, 0);
    
    if (selectedDate > today) {
      showToast(
        'You cannot mark attendance for future dates',
        'भविष्यको मिति चयन गर्न सकिँदैन'
      );
      return;
    }
    
    const current = fullMonthLogs.find((l) => l.log_date === log_date);
    if (!current) {
      console.error('Could not find log for date:', log_date);
      return;
    }
    
    // Toggle feature: if clicking the same status button, delete the entry
    if (!current.isUnselected && current.status === status) {
      deleteMutation.mutate(log_date);
      return;
    }
    
    // Create clean log entry without isUnselected flag
    const { isUnselected, ...cleanLog } = current;
    mutation.mutate({
      ...cleanLog,
      status,
      extra_trip_income:
        status === "present" ? current.extra_trip_income ?? 0 : 0,
    });
  };

  const handleExtraChange = (log_date: string, extra: number) => {
    const current = fullMonthLogs.find((l) => l.log_date === log_date)!;
    const { isUnselected, ...cleanLog } = current;
    mutation.mutate({
      ...cleanLog,
      status: "present",
      extra_trip_income: extra,
    });
  };

  const handleOpenTip = (log: AttendanceLog) => {
    // Check if the date is in the future
    const selectedDate = new Date(log.log_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    selectedDate.setHours(0, 0, 0, 0);
    
    if (selectedDate > today) {
      showToast(
        'You cannot add tips for future dates',
        'भविष्यको मिति चयन गर्न सकिँदैन'
      );
      return;
    }
    
    setTipModal({
      log_date: log.log_date,
      note: (log.extra_tip_note ?? "") as string,
      amount:
        log.extra_tip_amount != null && !Number.isNaN(log.extra_tip_amount)
          ? String(log.extra_tip_amount)
          : "",
    });
  };

  const handleTipSubmit = () => {
    if (!tipModal) return;
    const current = fullMonthLogs.find((l) => l.log_date === tipModal.log_date)!;
    const { isUnselected, ...cleanLog } = current;
    mutation.mutate({
      ...cleanLog,
      extra_tip_amount: tipModal.amount ? Number(tipModal.amount) : 0,
      extra_tip_note: tipModal.note || null,
    });
    setTipModal(null);
  };

  const handleTipCancel = () => {
    setTipModal(null);
  };

  const handleOpenKm = (log: AttendanceLog) => {
    // Check if the date is in the future
    const selectedDate = new Date(log.log_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    selectedDate.setHours(0, 0, 0, 0);
    
    if (selectedDate > today) {
      showToast(
        'You cannot add KM for future dates',
        'भविष्यको मिति चयन गर्न सकिँदैन'
      );
      return;
    }
    
    setKmModal({
      log_date: log.log_date,
      km_start: log.km_start != null && !Number.isNaN(log.km_start)
        ? String(log.km_start)
        : "",
      km_end: log.km_end != null && !Number.isNaN(log.km_end)
        ? String(log.km_end)
        : "",
    });
  };

  const handleKmSubmit = () => {
    if (!kmModal) return;
    
    const startKm = kmModal.km_start ? Number(kmModal.km_start) : 0;
    const endKm = kmModal.km_end ? Number(kmModal.km_end) : 0;
    const totalKm = endKm > startKm ? endKm - startKm : 0;
    
    const current = fullMonthLogs.find((l) => l.log_date === kmModal.log_date)!;
    const { isUnselected, ...cleanLog } = current;
    mutation.mutate({
      ...cleanLog,
      km_start: startKm || null,
      km_end: endKm || null,
      km_total: totalKm || null,
    });
    setKmModal(null);
  };

  const handleKmCancel = () => {
    setKmModal(null);
  };

  const handleOpenFuelBill = () => {
    // Get the last bill's end_date or default to "2026-01-15"
    const lastBillEndDate = fuelBills.length > 0 ? fuelBills[0].end_date : "2026-01-15";
    
    // Calculate next day after last bill
    const lastDate = new Date(lastBillEndDate);
    lastDate.setDate(lastDate.getDate() + 1);
    const startDate = lastDate.toISOString().slice(0, 10);
    
    // Default end date is today
    const today = new Date();
    const endDate = today.toISOString().slice(0, 10);
    
    setFuelBillModal({
      start_date: startDate,
      end_date: endDate,
      actual_liters: "",
    });
  };

  const handleFuelBillSubmit = () => {
    if (!fuelBillModal) return;
    
    // Calculate total KM between start and end dates
    const start = new Date(fuelBillModal.start_date);
    const end = new Date(fuelBillModal.end_date);
    
    let totalKm = 0;
    fullMonthLogs.forEach(log => {
      const logDate = new Date(log.log_date);
      if (logDate >= start && logDate <= end && log.km_total) {
        totalKm += log.km_total;
      }
    });
    
    // Also check other months if needed
    // For now, we'll need to fetch all attendance logs in the date range
    // Let's calculate expected liters
    const expectedLiters = totalKm / 7.5;
    
    fuelBillMutation.mutate({
      start_date: fuelBillModal.start_date,
      end_date: fuelBillModal.end_date,
      total_km: totalKm,
      expected_liters: Number(expectedLiters.toFixed(2)),
      actual_liters: fuelBillModal.actual_liters ? Number(fuelBillModal.actual_liters) : null,
    });
    
    setFuelBillModal(null);
  };

  const handleFuelBillCancel = () => {
    setFuelBillModal(null);
  };

  // Calculate KM for fuel bill modal
  const fuelBillCalculatedKm = useMemo(() => {
    if (!fuelBillModal) return { totalKm: 0, expectedLiters: 0 };
    
    const start = new Date(fuelBillModal.start_date);
    const end = new Date(fuelBillModal.end_date);
    
    let totalKm = 0;
    fullMonthLogs.forEach(log => {
      const logDate = new Date(log.log_date);
      if (logDate >= start && logDate <= end && log.km_total) {
        totalKm += log.km_total;
      }
    });
    
    const expectedLiters = totalKm / 7.5;
    
    return {
      totalKm,
      expectedLiters: Number(expectedLiters.toFixed(2)),
    };
  }, [fuelBillModal, fullMonthLogs]);

  const handleDownloadPDF = () => {
    try {
      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.getWidth();
      
      // Add title - centered
      doc.setFontSize(18);
      doc.setFont("helvetica", "bold");
      doc.text("Monthly Details Sheet", pageWidth / 2, 15, { align: "center" });
      
      // Add Nepali month and year - centered
      doc.setFontSize(14);
      doc.setFont("helvetica", "normal");
      const nepaliMonthNameEnglish = NEPALI_MONTHS_ENGLISH[currentNepaliMonth];
      const monthYearText = nepaliMonthNameEnglish + " " + String(currentNepaliYear);
      doc.text(monthYearText, pageWidth / 2, 24, { align: "center" });
      
      // Vehicle number
      doc.setFontSize(11);
      doc.text("Ga 2 Pa 4066", pageWidth / 2, 31, { align: "center" });
      
      let yPos = 42;
      
      // Filter only up to today's date
      const todayDate = new Date();
      todayDate.setHours(0, 0, 0, 0);
      
      const logsUpToToday = fullMonthLogs.filter(log => {
        if (log.isUnselected) return false;
        const logDate = new Date(log.log_date);
        logDate.setHours(0, 0, 0, 0);
        return logDate <= todayDate;
      });
      
      // Calculate summary
      const summaryUpToToday = calculateMonthlySummary(logsUpToToday);
      
      // Group dates by status
      const presentDates: number[] = [];
      const absentDates: number[] = [];
      const replaceDates: number[] = [];
      const tipDates: number[] = [];
      
      logsUpToToday.forEach(log => {
        const adDate = new Date(log.log_date);
        const nepaliDate = new NepaliDate(adDate);
        const nepaliDay = nepaliDate.getDate();
        
        if (log.status === "present") {
          presentDates.push(nepaliDay);
        } else if (log.status === "absent_holiday") {
          absentDates.push(nepaliDay);
        } else if (log.status === "absent_replacement") {
          replaceDates.push(nepaliDay);
        }
        
        if ((log.extra_tip_amount && log.extra_tip_amount > 0) || (log.extra_trip_income && log.extra_trip_income > 0)) {
          if (!tipDates.includes(nepaliDay)) tipDates.push(nepaliDay);
        }
      });
      
      // Sort dates
      presentDates.sort((a, b) => a - b);
      absentDates.sort((a, b) => a - b);
      replaceDates.sort((a, b) => a - b);
      tipDates.sort((a, b) => a - b);
      
      // Date Lists Section
      doc.setFontSize(10);
      doc.setFont("helvetica", "normal");
      
      // Present Days
      const presentDatesStr = presentDates.length > 0 ? presentDates.join(", ") : "None";
      const presentText = "Total Present Days = " + presentDatesStr + " (Total Days: " + String(presentDates.length) + ")";
      const presentLines = doc.splitTextToSize(presentText, pageWidth - 28);
      doc.text(presentLines, 14, yPos);
      yPos += presentLines.length * 5;
      
      // Absent Days
      const absentDatesStr = absentDates.length > 0 ? absentDates.join(", ") : "None";
      const absentText = "Absent = " + absentDatesStr + " (" + String(absentDates.length) + ")";
      const absentLines = doc.splitTextToSize(absentText, pageWidth - 28);
      doc.text(absentLines, 14, yPos);
      yPos += absentLines.length * 5;
      
      // Replace Days
      const replaceDatesStr = replaceDates.length > 0 ? replaceDates.join(", ") : "None";
      const replaceText = "Replace = " + replaceDatesStr + " (" + String(replaceDates.length) + ")";
      const replaceLines = doc.splitTextToSize(replaceText, pageWidth - 28);
      doc.text(replaceLines, 14, yPos);
      yPos += replaceLines.length * 5;
      
      // Extra Tips Days
      const tipDatesStr = tipDates.length > 0 ? tipDates.join(", ") : "None";
      const tipsText = "Extra tips = " + tipDatesStr;
      const tipsLines = doc.splitTextToSize(tipsText, pageWidth - 28);
      doc.text(tipsLines, 14, yPos);
      yPos += tipsLines.length * 5 + 8;
      
      // Earning Sheet Title
      doc.setFont("helvetica", "bold");
      doc.setFontSize(12);
      doc.text("Earning Sheet", 14, yPos);
      yPos += 8;
      
      // Create Earning Table with formulas
      const presentIncome = summaryUpToToday.totalPresentDays * DAILY_WAGE;
      const presentFormula = String(summaryUpToToday.totalPresentDays) + " × " + String(DAILY_WAGE);
      const replaceFormula = String(summaryUpToToday.totalReplacementDays) + " × " + String(REPLACEMENT_DEDUCTION);
      const totalEarning = presentIncome - summaryUpToToday.totalDeductions;
      
      // Count total holiday days from logs
      const totalHolidayDays = logsUpToToday.filter(log => log.status === 'absent_holiday').length;
      
      const tableData = [
        [
          'Present Days',
          String(summaryUpToToday.totalPresentDays),
          presentFormula,
          'Rs ' + String(presentIncome)
        ],
        [
          'Absent Days',
          String(totalHolidayDays),
          '-',
          '-'
        ],
        [
          'Replace Days',
          String(summaryUpToToday.totalReplacementDays),
          replaceFormula,
          'Rs ' + String(summaryUpToToday.totalDeductions)
        ],
        [
          '',
          '',
          'Total Earning',
          'Rs ' + String(totalEarning)
        ]
      ];
      
      autoTable(doc, {
        startY: yPos,
        head: [['', 'Total Days', 'Earning', 'Total']],
        body: tableData,
        theme: 'grid',
        styles: { 
          fontSize: 10,
          cellPadding: 3,
          halign: 'center'
        },
        headStyles: { 
          fillColor: [59, 130, 246],
          textColor: 255,
          fontStyle: 'bold'
        },
        bodyStyles: {
          lineWidth: 0.5,
          lineColor: [0, 0, 0]
        },
        columnStyles: {
          0: { halign: 'left', cellWidth: 40 },
          1: { halign: 'center', cellWidth: 30 },
          2: { halign: 'left', cellWidth: 50 },
          3: { halign: 'right', cellWidth: 40 }
        },
        alternateRowStyles: { fillColor: [245, 245, 245] }
      });
      
      // Get position after table
      const tableEndY = (doc as any).lastAutoTable.finalY || yPos;
      yPos = tableEndY + 12;
      
      // Extra Tips Section
      doc.setFont("helvetica", "bold");
      doc.setFontSize(12);
      doc.text("Extra Tips", 14, yPos);
      yPos += 7;
      
      doc.setFont("helvetica", "normal");
      doc.setFontSize(10);
      
      // Get all tips and calculate total
      const tipsData = logsUpToToday.filter(log => 
        log.extra_tip_amount && log.extra_tip_amount > 0
      );
      
      let calculatedTipsTotal = 0;
      
      if (tipsData.length > 0) {
        tipsData.forEach((tip, index) => {
          const adDate = new Date(tip.log_date);
          const nepaliDate = new NepaliDate(adDate);
          
          // Format dates
          const nepaliDateStr = String(nepaliDate.getDate()) + " " + 
                                NEPALI_MONTHS_ENGLISH[nepaliDate.getMonth()] + " " + 
                                String(nepaliDate.getYear());
          const adDateStr = String(adDate.getDate()) + " " + 
                           adDate.toLocaleString('en-US', { month: 'short' }) + " " + 
                           String(adDate.getFullYear());
          
          const destination = tip.extra_tip_note || "No destination";
          const amount = tip.extra_tip_amount || 0;
          calculatedTipsTotal += amount;
          
          const tipLine = String(index + 1) + ". " + destination + 
                         " (" + nepaliDateStr + " / " + adDateStr + ")   Rs " + 
                         String(amount);
          
          const tipLines = doc.splitTextToSize(tipLine, pageWidth - 28);
          doc.text(tipLines, 14, yPos);
          yPos += tipLines.length * 5;
        });
        
        yPos += 5;
        
        // Total Tips Amount
        doc.setFont("helvetica", "bold");
        doc.text("Total Tips Amount: Rs " + String(calculatedTipsTotal), 14, yPos);
      } else {
        doc.text("No extra tips recorded", 14, yPos);
        yPos += 5;
      }
      
      // Final calculation note
      yPos += 10;
      doc.setFont("helvetica", "normal");
      doc.setFontSize(9);
      doc.text("Calculated by earning from total present days - Replace Days", 14, yPos);
      
      yPos += 8;
      doc.setFont("helvetica", "bold");
      doc.setFontSize(14);
      const finalTotal = totalEarning + calculatedTipsTotal + summaryUpToToday.totalExtraIncome;
      doc.text("Net Income: Rs " + String(finalTotal), 14, yPos);
      
      // Footer
      doc.setFontSize(8);
      doc.setFont("helvetica", "normal");
      doc.setTextColor(128);
      const footerY = doc.internal.pageSize.getHeight() - 10;
      doc.text("Generated: " + new Date().toISOString().slice(0, 10), 14, footerY);
      doc.text("Vehicle Attendance System", pageWidth / 2, footerY, { align: "center" });
      
      // Generate filename
      const filename = "Attendance_" + nepaliMonthNameEnglish + "_" + String(currentNepaliYear) + ".pdf";
      doc.save(filename);
    } catch (error) {
      console.error("PDF generation error:", error);
      alert("Error generating PDF: " + (error as Error).message);
    }
  };

  const handlePrevMonth = () => {
    let newMonth = currentNepaliMonth - 1;
    let newYear = currentNepaliYear;
    
    if (newMonth < 0) {
      newMonth = 11; // Chaitra (last month)
      newYear = newYear - 1;
    }
    
    setCurrentNepaliMonth(newMonth);
    setCurrentNepaliYear(newYear);
  };

  const handleNextMonth = () => {
    let newMonth = currentNepaliMonth + 1;
    let newYear = currentNepaliYear;
    
    if (newMonth > 11) {
      newMonth = 0; // Baisakh (first month)
      newYear = newYear + 1;
    }
    
    setCurrentNepaliMonth(newMonth);
    setCurrentNepaliYear(newYear);
  };

  const handleToday = () => {
    const today = new NepaliDate();
    setCurrentNepaliYear(today.getYear());
    setCurrentNepaliMonth(today.getMonth());
  };

  // Get corresponding English month/year for display
  const firstDayBS = new NepaliDate(currentNepaliYear, currentNepaliMonth, 1);
  const firstDayAD = firstDayBS.toJsDate();
  const englishMonthName = firstDayAD.toLocaleString("default", { month: "long" });
  const englishYear = firstDayAD.getFullYear();

  return (
    <div className="min-h-screen bg-gray-50">
      <main className="w-full max-w-6xl mx-auto px-6 py-6 pb-12">
        <header className="mb-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            Vehicle Attendance & Earnings
          </h1>
          
          {/* Month Display and Navigation */}
          <div className="flex items-center justify-between bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg px-6 py-4 shadow-lg">
            <button
              type="button"
              onClick={handlePrevMonth}
              className="px-4 py-2 text-sm font-semibold bg-white/20 hover:bg-white/30 rounded-lg transition-colors"
            >
              ← Previous
            </button>
            
            <div className="text-center">
              <div className="text-3xl font-bold mb-1 font-mukta">
                {NEPALI_MONTHS[currentNepaliMonth]} {toNepaliNumber(currentNepaliYear)}
              </div>
              <div className="text-sm opacity-90">
                {englishMonthName} {englishYear}
              </div>
            </div>
            
            <button
              type="button"
              onClick={handleNextMonth}
              className="px-4 py-2 text-sm font-semibold bg-white/20 hover:bg-white/30 rounded-lg transition-colors"
            >
              Next →
            </button>
          </div>
          
          <div className="mt-3 text-center">
            <button
              type="button"
              onClick={handleToday}
              className="px-4 py-1.5 text-sm font-medium text-blue-700 bg-blue-50 border border-blue-300 rounded-lg hover:bg-blue-100"
            >
              Go to Today
            </button>
          </div>
        </header>

        <section className="mb-4 rounded-lg bg-white p-3 shadow-sm">
          <h2 className="text-sm font-semibold text-gray-800 mb-2">
            Monthly Summary
          </h2>
          {isLoading ? (
            <p className="text-xs text-gray-500">Loading attendance...</p>
          ) : (
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="flex flex-col">
                <span className="text-gray-500">Present Days</span>
                <span className="font-semibold">{summary.totalPresentDays}</span>
              </div>
              <div className="flex flex-col">
                <span className="text-gray-500">Extra Tips (Rs.)</span>
                <span className="font-semibold">
                  {summary.totalExtraTips.toLocaleString("en-IN")}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-gray-500">Replacement Days</span>
                <span className="font-semibold text-red-600">
                  {summary.totalReplacementDays}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-gray-500">Total KM Run</span>
                <span className="font-semibold text-purple-600">
                  {summary.totalKm.toLocaleString("en-IN")} km
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-gray-500">Extra Trips (Rs.)</span>
                <span className="font-semibold">
                  {summary.totalExtraIncome.toLocaleString("en-IN")}
                </span>
              </div>
              <div className="flex flex-col">
                <span className="text-gray-500">Deductions (Rs.)</span>
                <span className="font-semibold text-red-600">
                  -{summary.totalDeductions.toLocaleString("en-IN")}
                </span>
              </div>
              <div className="col-span-2 h-px bg-gray-100 my-1" />
              <div className="col-span-2 flex justify-between items-center">
                <span className="text-gray-700 font-semibold">Net Income (Rs.)</span>
                <span className="text-lg font-bold text-green-700">
                  {summary.netIncome.toLocaleString("en-IN")}
                </span>
              </div>
            </div>
          )}
        </section>

        <section className="rounded-lg bg-white p-2 shadow-sm">
          <div className="grid grid-cols-7 text-center text-[10px] font-semibold text-gray-600 mb-1">
            <span>Sun</span>
            <span>Mon</span>
            <span>Tue</span>
            <span>Wed</span>
            <span>Thu</span>
            <span>Fri</span>
            <span>Sat</span>
          </div>

          <div className="grid grid-cols-7 gap-1">
            {calendarCells.map((cell, index) => {
              if (!cell) {
                return (
                  <div
                    key={index}
                    className="min-h-[90px] rounded-md border border-gray-100 bg-gray-50"
                  />
                );
              }

              // Get current date in Nepal timezone (UTC+5:45)
              const nepalTimeStr = new Date().toLocaleString('en-US', { 
                timeZone: 'Asia/Kathmandu',
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
              });
              const [month, day, year] = nepalTimeStr.split('/');
              const todayNepalStr = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
              
              // Check if this cell's date is today
              const isToday = cell.log_date === todayNepalStr;

              // Check if this day has missing data (before today)
              const isPastDate = cell.log_date < todayNepalStr;
              const hasMissingData = isPastDate && (
                cell.isUnselected || 
                (cell.status === 'present' && !cell.km_total)
              );

              // Get English date for display
              const cellDate = new Date(cell.log_date);
              const englishDay = cellDate.getDate();
              
              // Get Nepali date for this specific day
              const nepaliDateObj = new NepaliDate(cellDate);
              const nepaliDay = nepaliDateObj.getDate();

              return (
                <DayCard
                  key={cell.log_date}
                  dateLabel={String(englishDay)}
                  nepaliDateLabel={toNepaliNumber(nepaliDay)}
                  log={cell}
                  isSaving={mutation.isPending || deleteMutation.isPending}
                  isToday={isToday}
                  hasMissingData={hasMissingData}
                  onChangeStatus={(status) =>
                    handleStatusChange(cell.log_date, status)
                  }
                  onChangeExtra={(extra) =>
                    handleExtraChange(cell.log_date, extra)
                  }
                  onOpenTip={() => handleOpenTip(cell)}
                  onOpenKm={() => handleOpenKm(cell)}
                />
              );
            })}
          </div>
        </section>

        {tipModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="w-full max-w-sm rounded-lg bg-white p-4 shadow-lg">
              <h3 className="mb-2 text-base font-semibold text-gray-900">
                Extra Tip Details
              </h3>
              <p className="mb-3 text-xs text-gray-600">
                Note where this tip came from and how much you expect.
              </p>
              <div className="mb-2 flex flex-col gap-1">
                <label className="text-xs text-gray-700">Where was your tip?</label>
                <input
                  type="text"
                  value={tipModal.note}
                  onChange={(e) =>
                    setTipModal((prev) =>
                      prev
                        ? { ...prev, note: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                  placeholder="e.g. Evening market return, special trip"
                />
              </div>
              <div className="mb-3 flex flex-col gap-1">
                <label className="text-xs text-gray-700">
                  Expected tip amount (Rs.)
                </label>
                <input
                  type="number"
                  min={0}
                  value={tipModal.amount}
                  onChange={(e) =>
                    setTipModal((prev) =>
                      prev
                        ? { ...prev, amount: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                  placeholder="e.g. 500"
                />
              </div>
              <div className="flex justify-end gap-2 text-sm">
                <button
                  type="button"
                  onClick={handleTipCancel}
                  className="rounded border border-gray-300 px-3 py-1 text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleTipSubmit}
                  className="rounded bg-blue-600 px-3 py-1 font-semibold text-white hover:bg-blue-700"
                >
                  Save tip
                </button>
              </div>
            </div>
          </div>
        )}

        {kmModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="w-full max-w-sm rounded-lg bg-white p-4 shadow-lg">
              <h3 className="mb-2 text-base font-semibold text-gray-900">
                Kilometer Details
              </h3>
              <p className="mb-3 text-xs text-gray-600">
                Enter the starting and ending kilometer readings for the day.
              </p>
              <div className="mb-2 flex flex-col gap-1">
                <label className="text-xs text-gray-700">Starting KM</label>
                <input
                  type="number"
                  min={0}
                  value={kmModal.km_start}
                  onChange={(e) =>
                    setKmModal((prev) =>
                      prev
                        ? { ...prev, km_start: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-purple-500"
                  placeholder="e.g. 12300"
                />
              </div>
              <div className="mb-3 flex flex-col gap-1">
                <label className="text-xs text-gray-700">
                  Ending KM
                </label>
                <input
                  type="number"
                  min={0}
                  value={kmModal.km_end}
                  onChange={(e) =>
                    setKmModal((prev) =>
                      prev
                        ? { ...prev, km_end: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-purple-500"
                  placeholder="e.g. 12350"
                />
              </div>
              {kmModal.km_start && kmModal.km_end && Number(kmModal.km_end) > Number(kmModal.km_start) && (
                <div className="mb-3 rounded bg-purple-50 p-2 text-center">
                  <span className="text-xs text-gray-600">Total KM: </span>
                  <span className="text-sm font-bold text-purple-600">
                    {Number(kmModal.km_end) - Number(kmModal.km_start)} km
                  </span>
                </div>
              )}
              <div className="flex justify-end gap-2 text-sm">
                <button
                  type="button"
                  onClick={handleKmCancel}
                  className="rounded border border-gray-300 px-3 py-1 text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleKmSubmit}
                  className="rounded bg-purple-600 px-3 py-1 font-semibold text-white hover:bg-purple-700"
                >
                  Save KM
                </button>
              </div>
            </div>
          </div>
        )}

        {fuelBillModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
            <div className="w-full max-w-md rounded-lg bg-white p-6 shadow-lg">
              <h3 className="mb-3 text-lg font-bold text-gray-900">
                ⛽ Generate Fuel Bill
              </h3>
              <p className="mb-4 text-sm text-gray-600">
                Calculate fuel consumption based on kilometers run.
              </p>
              
              <div className="mb-3 flex flex-col gap-1">
                <label className="text-sm font-medium text-gray-700">Last Bill Date (Auto-set)</label>
                <input
                  type="date"
                  value={fuelBillModal.start_date}
                  readOnly
                  className="w-full rounded border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-600 cursor-not-allowed"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Automatically set based on previous bill
                </p>
              </div>

              <div className="mb-3 flex flex-col gap-1">
                <label className="text-sm font-medium text-gray-700">Bill End Date</label>
                <input
                  type="date"
                  value={fuelBillModal.end_date}
                  onChange={(e) =>
                    setFuelBillModal((prev) =>
                      prev
                        ? { ...prev, end_date: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500"
                />
              </div>

              {/* Calculation Display */}
              <div className="mb-4 rounded-lg bg-orange-50 p-4 border border-orange-200">
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <span className="text-gray-600">Period:</span>
                    <p className="font-semibold text-gray-800 mt-1">
                      {new Date(fuelBillModal.start_date).toLocaleDateString()} - {new Date(fuelBillModal.end_date).toLocaleDateString()}
                    </p>
                  </div>
                  <div>
                    <span className="text-gray-600">Total KM:</span>
                    <p className="font-bold text-purple-600 text-lg mt-1">
                      {fuelBillCalculatedKm.totalKm.toLocaleString()} km
                    </p>
                  </div>
                  <div className="col-span-2">
                    <span className="text-gray-600">Expected Fuel (÷ 7.5):</span>
                    <p className="font-bold text-orange-600 text-2xl mt-1">
                      {fuelBillCalculatedKm.expectedLiters.toLocaleString()} Liters
                    </p>
                  </div>
                </div>
              </div>

              <div className="mb-4 flex flex-col gap-1">
                <label className="text-sm font-medium text-gray-700">
                  Actual Fuel Given (Optional)
                </label>
                <input
                  type="number"
                  min={0}
                  step="0.01"
                  value={fuelBillModal.actual_liters}
                  onChange={(e) =>
                    setFuelBillModal((prev) =>
                      prev
                        ? { ...prev, actual_liters: e.target.value }
                        : prev
                    )
                  }
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="e.g. 45.5"
                />
                <p className="text-xs text-gray-500 mt-1">
                  Enter the actual liters provided by the company
                </p>
              </div>

              <div className="flex justify-end gap-3">
                <button
                  type="button"
                  onClick={handleFuelBillCancel}
                  className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleFuelBillSubmit}
                  className="rounded-lg bg-orange-600 px-4 py-2 text-sm font-semibold text-white hover:bg-orange-700"
                >
                  💾 Save Fuel Bill
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Tips List */}
        {tipsList.length > 0 && (
          <section className="mt-4 bg-white rounded-lg p-6 shadow-md">
            <h3 className="text-lg font-bold mb-4 text-gray-800">
              Tips Record / टिप रेकर्ड
            </h3>
            <div className="space-y-2">
              {tipsList.map((tip) => {
                const adDate = new Date(tip.date);
                const nepaliDate = new NepaliDate(adDate);
                const nepaliDateStr = `${NEPALI_MONTHS[nepaliDate.getMonth()]} ${toNepaliNumber(nepaliDate.getDate())}, ${toNepaliNumber(nepaliDate.getYear())}`;
                
                return (
                  <div
                    key={tip.date}
                    className="flex justify-between items-center p-3 bg-gray-50 rounded-lg border border-gray-200"
                  >
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold text-gray-700 font-mukta">
                          {nepaliDateStr}
                        </span>
                        <span className="text-xs text-gray-500">
                          ({tip.date})
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">
                        {tip.note}
                      </p>
                    </div>
                    <div className="text-right ml-4">
                      <span className="text-sm font-bold text-green-600">
                        Rs. {tip.amount.toLocaleString()}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {/* KM List */}
        {kmList.length > 0 && (
          <section className="mt-4 bg-white rounded-lg p-6 shadow-md">
            <h3 className="text-lg font-bold mb-4 text-gray-800">
              Kilometer Record / किलोमिटर रेकर्ड
            </h3>
            <div className="space-y-2">
              {kmList.map((km) => {
                const adDate = new Date(km.date);
                const nepaliDate = new NepaliDate(adDate);
                const nepaliDateStr = `${NEPALI_MONTHS[nepaliDate.getMonth()]} ${toNepaliNumber(nepaliDate.getDate())}, ${toNepaliNumber(nepaliDate.getYear())}`;
                
                return (
                  <div
                    key={km.date}
                    className="flex justify-between items-center p-3 bg-gray-50 rounded-lg border border-gray-200"
                  >
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold text-gray-700 font-mukta">
                          {nepaliDateStr}
                        </span>
                        <span className="text-xs text-gray-500">
                          ({km.date})
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">
                        Start: {km.km_start.toLocaleString()} km → End: {km.km_end.toLocaleString()} km
                      </p>
                    </div>
                    <div className="text-right ml-4">
                      <span className="text-sm font-bold text-purple-600">
                        {km.km_total.toLocaleString()} km
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        )}

        {/* Fuel Bill Records */}
        {fuelBills.length > 0 && (
          <section className="mt-4 bg-white rounded-lg p-6 shadow-md">
            <h3 className="text-lg font-bold mb-4 text-gray-800">
              Fuel Bill Records / ईंधन बिल रेकर्ड
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="px-3 py-2 text-left font-semibold text-gray-700">Period</th>
                    <th className="px-3 py-2 text-right font-semibold text-gray-700">Total KM</th>
                    <th className="px-3 py-2 text-right font-semibold text-gray-700">Expected Liters</th>
                    <th className="px-3 py-2 text-right font-semibold text-gray-700">Actual Liters</th>
                  </tr>
                </thead>
                <tbody>
                  {fuelBills.map((bill, index) => (
                    <tr key={index} className="border-b border-gray-200 hover:bg-gray-50">
                      <td className="px-3 py-3 text-gray-700">
                        {bill.start_date} → {bill.end_date}
                      </td>
                      <td className="px-3 py-3 text-right font-medium text-purple-600">
                        {bill.total_km.toLocaleString()} km
                      </td>
                      <td className="px-3 py-3 text-right font-medium text-blue-600">
                        {bill.expected_liters.toLocaleString()} L
                      </td>
                      <td className="px-3 py-3 text-right font-medium text-green-600">
                        {bill.actual_liters ? `${bill.actual_liters.toLocaleString()} L` : '-'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* Generate Fuel Bill Button */}
        <div className="mt-6 flex justify-center gap-4">
          <button
            onClick={handleOpenFuelBill}
            className="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold shadow-md"
          >
            ⛽ Generate Fuel Bill
          </button>
        </div>

        {/* PDF Download Button */}
        <div className="mt-6 flex justify-center">
          <button
            onClick={handleDownloadPDF}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold shadow-md"
          >
            📄 Download PDF Report (Up to Today)
          </button>
        </div>
      </main>

      {/* Toast Notification */}
      {toast.show && (
        <div className="fixed top-4 right-4 z-50 animate-slide-in">
          <div className="bg-red-600 text-white px-6 py-4 rounded-lg shadow-2xl max-w-md">
            <div className="flex items-start gap-3">
              <svg className="w-6 h-6 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
              <div>
                <p className="font-bold text-lg mb-1">Invalid Date Selection</p>
                <p className="font-mukta text-base mb-2">{toast.nepaliMessage}</p>
                <p className="text-sm opacity-90">{toast.message}</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
