"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { AttendanceLog, AttendanceStatus } from "@/lib/attendance";
import { calculateMonthlySummary } from "@/lib/attendance";

const API_BASE = "/api/attendance"; // Next.js App Router API route

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
  log: AttendanceLog & { isUnselected?: boolean };
  onChangeStatus: (status: AttendanceStatus) => void;
  onChangeExtra: (extra: number) => void;
   onOpenTip: () => void;
  isSaving: boolean;
}

function DayCard({
  dateLabel,
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
     ? "bg-gray-200 text-gray-800"
     : "bg-red-600 text-white";

  return (
    <div className="border rounded-lg p-2 flex flex-col justify-between bg-white shadow-sm min-h-[110px]">
      <div className="flex items-center justify-between mb-1">
        <span className="text-sm font-semibold text-gray-800">{dateLabel}</span>
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
              ? "bg-orange-100 text-orange-700 border-orange-300"
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
              ? "bg-red-600 text-white border-red-600"
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

export function MonthlyAttendanceClient() {
  const queryClient = useQueryClient();
  const monthKey = getCurrentMonthKey();

  const [tipModal, setTipModal] = useState<
    | {
        log_date: string;
        note: string;
        amount: string;
      }
    | null
  >(null);

  const [year, monthStr] = monthKey.split("-");
  const yearNum = Number(year);
  const monthIndex = Number(monthStr) - 1; // 0-based

  const daysInMonth = new Date(yearNum, monthIndex + 1, 0).getDate();

  const { data: serverLogs = [], isLoading } = useQuery({
    queryKey: ["attendance", monthKey],
    queryFn: () => fetchMonthAttendance(monthKey),
  });

  const mutation = useMutation({
    mutationFn: upsertAttendance,
    onMutate: async (newLog: AttendanceLog) => {
      await queryClient.cancelQueries({ queryKey: ["attendance", monthKey] });
      const previous =
        (queryClient.getQueryData<AttendanceLog[]>(["attendance", monthKey]) ?? []);

      const updated = [
        ...previous.filter((l) => l.log_date !== newLog.log_date),
        newLog,
      ];

      queryClient.setQueryData(["attendance", monthKey], updated);

      return { previous };
    },
    onError: (_err, _newLog, context) => {
      if (context?.previous) {
        queryClient.setQueryData(["attendance", monthKey], context.previous);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["attendance", monthKey] });
    },
  });

  const fullMonthLogs: AttendanceLog[] = useMemo(() => {
    const byDate = new Map(serverLogs.map((l) => [l.log_date, l] as const));
    const result: AttendanceLog[] = [];

    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = formatDate(yearNum, monthIndex, day);
      const existing = byDate.get(dateStr);
      if (existing) {
        result.push(existing);
      } else {
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
  }, [serverLogs, daysInMonth, yearNum, monthIndex]);

  const summary = useMemo(
    () => calculateMonthlySummary(fullMonthLogs),
    [fullMonthLogs]
  );

  // Build a calendar-style grid: Sunday first, with leading/trailing blanks.
  const firstDayOfWeek = new Date(yearNum, monthIndex, 1).getDay(); // 0 (Sun) - 6 (Sat)

  const calendarCells: (AttendanceLog | null)[] = useMemo(() => {
    const cells: (AttendanceLog | null)[] = [];

    // Leading empty cells before the 1st day of the month
    for (let i = 0; i < firstDayOfWeek; i++) {
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

    return cells;
  }, [fullMonthLogs, firstDayOfWeek]);

  const handleStatusChange = (log_date: string, status: AttendanceStatus) => {
    const current = fullMonthLogs.find((l) => l.log_date === log_date)!;
    mutation.mutate({
      ...current,
      status,
      extra_trip_income:
        status === "present" ? current.extra_trip_income ?? 0 : 0,
    });
  };

  const handleExtraChange = (log_date: string, extra: number) => {
    const current = fullMonthLogs.find((l) => l.log_date === log_date)!;
    mutation.mutate({
      ...current,
      status: "present",
      extra_trip_income: extra,
    });
  };

  const handleOpenTip = (log: AttendanceLog) => {
    setTipModal({
      log_date: log.log_date,
      note: (log.extra_tip_note ?? "") as string,
      amount:
        log.extra_tip_amount != null && !Number.isNaN(log.extra_tip_amount)
          ? String(log.extra_tip_amount)
          : "",
    });
  };

  const handleSaveTip = () => {
    if (!tipModal) return;
    const current = fullMonthLogs.find((l) => l.log_date === tipModal.log_date);
    if (!current) return;

    const amountNumber = Number(tipModal.amount || 0);

    mutation.mutate({
      ...current,
      extra_tip_note: tipModal.note.trim() || null,
      extra_tip_amount: Number.isNaN(amountNumber) ? 0 : amountNumber,
    });

    setTipModal(null);
  };

  const monthName = new Date(yearNum, monthIndex, 1).toLocaleString("default", {
    month: "long",
  });

  return (
    <div className="min-h-screen bg-gray-50">
      <main className="w-full max-w-6xl mx-auto px-6 py-6 pb-12">
        <header className="mb-4">
          <h1 className="text-2xl font-bold text-gray-900">
            Vehicle Attendance & Earnings
          </h1>
          <p className="text-sm text-gray-600">
            {monthName} {yearNum}
          </p>
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

              const dayNumber = new Date(cell.log_date).getDate();

              return (
                <DayCard
                  key={cell.log_date}
                  dateLabel={String(dayNumber)}
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
                  onClick={() => setTipModal(null)}
                  className="rounded border border-gray-300 px-3 py-1 text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleSaveTip}
                  className="rounded bg-blue-600 px-3 py-1 font-semibold text-white hover:bg-blue-700"
                >
                  Save tip
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
