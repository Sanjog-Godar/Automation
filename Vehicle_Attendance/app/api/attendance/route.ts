import { NextRequest, NextResponse } from 'next/server';
import { supabaseServerClient } from '@/lib/supabaseClient';
import type { AttendanceStatus } from '@/lib/attendance';

interface UpsertBody {
  log_date: string; // YYYY-MM-DD
  status: AttendanceStatus;
  extra_trip_income?: number | null;
  extra_tip_amount?: number | null;
  extra_tip_note?: string | null;
  km_start?: number | null;
  km_end?: number | null;
  km_total?: number | null;
}

export async function POST(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const body = (await req.json()) as UpsertBody;
    const { log_date, status, extra_trip_income, extra_tip_amount, extra_tip_note, km_start, km_end, km_total } = body;

    if (!log_date || !status) {
      return NextResponse.json({ error: 'log_date and status are required' }, { status: 400 });
    }

    const { data, error } = await supabase
      .from('attendance_logs')
      .upsert(
        {
          log_date,
          status,
          extra_trip_income: extra_trip_income ?? 0,
          extra_tip_amount: extra_tip_amount ?? 0,
          extra_tip_note: extra_tip_note ?? null,
          km_start: km_start ?? null,
          km_end: km_end ?? null,
          km_total: km_total ?? null,
        },
        { onConflict: 'log_date' }
      )
      .select()
      .single();

    if (error) {
      console.error('Supabase upsert error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in POST /api/attendance', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// GET /api/attendance?month=YYYY-MM
export async function GET(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const { searchParams } = new URL(req.url);
    const month = searchParams.get('month'); // e.g. '2026-01'

    if (!month) {
      return NextResponse.json({ error: 'month query param (YYYY-MM) is required' }, { status: 400 });
    }

    const [yearStr, monthStr] = month.split('-');
    const year = Number(yearStr);
    const monthIndex = Number(monthStr) - 1; // 0-based

    if (!year || monthIndex < 0 || monthIndex > 11) {
      return NextResponse.json({ error: 'Invalid month format. Expected YYYY-MM' }, { status: 400 });
    }

    const monthStart = new Date(Date.UTC(year, monthIndex, 1));
    const monthEnd = new Date(Date.UTC(year, monthIndex + 1, 0));

    const monthStartStr = monthStart.toISOString().slice(0, 10); // YYYY-MM-DD
    const monthEndStr = monthEnd.toISOString().slice(0, 10);

    const { data, error } = await supabase
      .from('attendance_logs')
      .select('*')
      .gte('log_date', monthStartStr)
      .lte('log_date', monthEndStr)
      .order('log_date', { ascending: true });

    if (error) {
      console.error('Supabase fetch error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in GET /api/attendance', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE /api/attendance?log_date=YYYY-MM-DD
export async function DELETE(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const { searchParams } = new URL(req.url);
    const log_date = searchParams.get('log_date');

    if (!log_date) {
      return NextResponse.json({ error: 'log_date query param (YYYY-MM-DD) is required' }, { status: 400 });
    }

    const { error } = await supabase
      .from('attendance_logs')
      .delete()
      .eq('log_date', log_date);

    if (error) {
      console.error('Supabase delete error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in DELETE /api/attendance', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
