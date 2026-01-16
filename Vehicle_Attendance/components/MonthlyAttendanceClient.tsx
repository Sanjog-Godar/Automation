"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { AttendanceLog, AttendanceStatus } from "@/lib/attendance";
import { calculateMonthlySummary, DAILY_WAGE, REPLACEMENT_DEDUCTION } from "@/lib/attendance";
import NepaliDate from "nepali-date-converter";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

const API_BASE = "/api/attendance"; // Next.js App Router API route

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

interface DayCardProps {
  dateLabel: string;
  nepaliDateLabel: string;
  log: AttendanceLog & { isUnselected?: boolean };
  onChangeStatus: (status: AttendanceStatus) => void;
  onChangeExtra: (extra: number) => void;
   onOpenTip: () => void;
  isSaving: boolean;
}

function DayCard({
  dateLabel,
  nepaliDateLabel,
  log,
  onChangeStatus,
  onChangeExtra,
  onOpenTip,
  isSaving,
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

  return (
    <div className="border rounded-lg p-2 flex flex-col justify-between bg-white shadow-sm min-h-[110px]">
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

      {isPresent && !isUnselected ? (
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

      <button
        type="button"
        onClick={onOpenTip}
        className="mt-1 self-end rounded-full border border-blue-500 px-2 py-0.5 text-[10px] font-medium text-blue-600 hover:bg-blue-50"
      >
        Extra Tip
      </button>

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

  const handleDownloadPDF = () => {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();
    
    // Add title
    doc.setFontSize(18);
    doc.setFont("helvetica", "bold");
    doc.text("Vehicle Attendance Report", pageWidth / 2, 15, { align: "center" });
    
    // Add Nepali month and year
    doc.setFontSize(12);
    doc.setFont("helvetica", "normal");
    const nepaliMonthName = NEPALI_MONTHS[currentNepaliMonth];
    const monthYearText = `${nepaliMonthName} ${currentNepaliYear}`;
    doc.text(monthYearText, pageWidth / 2, 25, { align: "center" });
    
    // Add generation date
    doc.setFontSize(10);
    const today = new Date();
    const todayNepali = new NepaliDate(today);
    const generatedText = `Generated: ${todayNepali.format('YYYY-MM-DD')} BS (${today.toISOString().slice(0, 10)} AD)`;
    doc.text(generatedText, pageWidth / 2, 32, { align: "center" });
    
    // Filter only up to today's date
    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);
    
    const logsUpToToday = fullMonthLogs.filter(log => {
      const logDate = new Date(log.log_date);
      logDate.setHours(0, 0, 0, 0);
      return logDate <= todayDate;
    });
    
    // Calculate summary for logs up to today
    const summaryUpToToday = calculateMonthlySummary(logsUpToToday);
    
    // Create attendance table data
    const tableData = logsUpToToday.map(log => {
      // Get Nepali date from AD date
      const adDate = new Date(log.log_date);
      const nepaliDate = new NepaliDate(adDate);
      const nepaliDateStr = `${nepaliDate.getYear()}-${String(nepaliDate.getMonth() + 1).padStart(2, '0')}-${String(nepaliDate.getDate()).padStart(2, '0')}`;
      
      const status = log.isUnselected
        ? "—"
        : log.status === "present"
        ? "Present"
        : log.status === "absent_holiday"
        ? "Holiday"
        : "Replace";
      
      const extraTrip = log.extra_trip_income || 0;
      const tip = log.extra_tip_amount || 0;
      const tipNote = log.extra_tip_note || "";
      
      return [
        log.log_date,
        nepaliDateStr,
        status,
        extraTrip > 0 ? `Rs. ${extraTrip}` : "—",
        tip > 0 ? `Rs. ${tip}` : "—",
        tipNote || "—"
      ];
    });
    
    // Add attendance table
    autoTable(doc, {
      startY: 38,
      head: [['Date (AD)', 'Date (BS)', 'Status', 'Extra Trip', 'Tip', 'Tip Note']],
      body: tableData,
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: [59, 130, 246], textColor: 255, fontStyle: 'bold' },
      alternateRowStyles: { fillColor: [245, 245, 245] },
      columnStyles: {
        0: { cellWidth: 25 },
        1: { cellWidth: 25 },
        2: { cellWidth: 20 },
        3: { cellWidth: 25 },
        4: { cellWidth: 20 },
        5: { cellWidth: 'auto' },
      },
    });
    
    // Get final Y position after table
    const finalY = (doc as any).lastAutoTable.finalY || 38;
    
    // Add summary section
    doc.setFontSize(14);
    doc.setFont("helvetica", "bold");
    doc.text("Monthly Summary (Up to Today)", 14, finalY + 10);
    
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    
    const summaryLines = [
      `Present Days: ${summaryUpToToday.totalPresentDays}`,
      `Holiday Days: ${summaryUpToToday.totalHolidayDays}`,
      `Replacement Days: ${summaryUpToToday.totalReplacementDays}`,
      ``,
      `Daily Wage: Rs. ${DAILY_WAGE.toLocaleString()}`,
      `Present Income: Rs. ${summaryUpToToday.presentIncome.toLocaleString()}`,
      `Extra Trip Income: Rs. ${summaryUpToToday.extraTripIncome.toLocaleString()}`,
      `Total Tips: Rs. ${summaryUpToToday.totalTips.toLocaleString()}`,
      `Replacement Deduction: -Rs. ${summaryUpToToday.replacementDeduction.toLocaleString()}`,
      ``,
      `Net Income: Rs. ${summaryUpToToday.netIncome.toLocaleString()}`,
    ];
    
    let currentY = finalY + 15;
    summaryLines.forEach(line => {
      if (line === '') {
        currentY += 2;
      } else if (line.startsWith('Net Income')) {
        doc.setFont("helvetica", "bold");
        doc.setFontSize(12);
        doc.text(line, 14, currentY);
        doc.setFont("helvetica", "normal");
        doc.setFontSize(10);
        currentY += 7;
      } else {
        doc.text(line, 14, currentY);
        currentY += 5;
      }
    });
    
    // Add footer
    doc.setFontSize(8);
    doc.setTextColor(128);
    const footerY = doc.internal.pageSize.getHeight() - 10;
    doc.text("Vehicle Attendance Tracking System", pageWidth / 2, footerY, { align: "center" });
    
    // Generate filename with Nepali month and year
    const filename = `Attendance_${nepaliMonthName}_${currentNepaliYear}.pdf`;
    doc.save(filename);
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

          {!isLoading && tipsList.length > 0 && (
            <div className="mt-3 pt-3 border-t border-gray-200">
              <h3 className="text-sm font-semibold text-gray-800 mb-2">
                Extra Tips Details
              </h3>
              <div className="space-y-1.5">
                {tipsList.map((tip, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between text-xs bg-blue-50 rounded px-2 py-1.5"
                  >
                    <div className="flex-1">
                      <div className="font-medium text-gray-800">{tip.note}</div>
                      <div className="text-gray-500 text-[10px]">
                        {new Date(tip.date).toLocaleDateString("en-US", {
                          month: "short",
                          day: "numeric",
                        })}
                      </div>
                    </div>
                    <div className="font-semibold text-blue-700">
                      Rs. {tip.amount.toLocaleString("en-IN")}
                    </div>
                  </div>
                ))}
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
                  isSaving={mutation.isPending}
                  onChangeStatus={(status) =>
                    handleStatusChange(cell.log_date, status)
                  }
                  onChangeExtra={(extra) =>
                    handleExtraChange(cell.log_date, extra)
                  }
                  onOpenTip={() => handleOpenTip(cell)}
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
