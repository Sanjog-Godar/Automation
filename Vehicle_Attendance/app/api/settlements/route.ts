import { NextRequest, NextResponse } from 'next/server';
import { supabaseServerClient } from '@/lib/supabaseClient';

export async function GET(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const { searchParams } = new URL(req.url);
    const yearStr = searchParams.get('year');
    const monthIndexStr = searchParams.get('month_index');

    if (!yearStr || monthIndexStr === null) {
      return NextResponse.json({ error: 'year and month_index query params are required' }, { status: 400 });
    }

    const year = Number(yearStr);
    const monthIndex = Number(monthIndexStr);

    if (isNaN(year) || isNaN(monthIndex) || monthIndex < 0 || monthIndex > 11) {
      return NextResponse.json({ error: 'Invalid year or month_index' }, { status: 400 });
    }

    // Previous month computation
    const prevMonthIndex = monthIndex === 0 ? 11 : monthIndex - 1;
    const prevYear = monthIndex === 0 ? year - 1 : year;

    // Fetch both current month and previous month settlements in parallel
    const [currentRes, prevRes] = await Promise.all([
      supabase
        .from('monthly_settlements')
        .select('*')
        .eq('bs_year', year)
        .eq('bs_month_index', monthIndex)
        .maybeSingle(),
      supabase
        .from('monthly_settlements')
        .select('*')
        .eq('bs_year', prevYear)
        .eq('bs_month_index', prevMonthIndex)
        .maybeSingle(),
    ]);

    if (currentRes.error) {
      console.error('Supabase fetch settlement error', currentRes.error);
      return NextResponse.json({ error: currentRes.error.message }, { status: 500 });
    }

    return NextResponse.json({
      data: currentRes.data ?? null,
      previous: prevRes.data ?? null,
    }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in GET /api/settlements', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const body = await req.json();
    const {
      bs_year,
      bs_month_index,
      expected_amount,
      bank_received_amount,
      payment_date,
      note,
    } = body;

    if (bs_year === undefined || bs_month_index === undefined) {
      return NextResponse.json({ error: 'bs_year and bs_month_index are required' }, { status: 400 });
    }

    const expected = Number(expected_amount ?? 0);
    const received = Number(bank_received_amount ?? 0);

    let settlement_status = 'unsettled';
    if (received >= expected && received > 0) {
      settlement_status = 'settled';
    } else if (received > 0 && received < expected) {
      settlement_status = 'partial';
    }

    const { data, error } = await supabase
      .from('monthly_settlements')
      .upsert(
        {
          bs_year,
          bs_month_index,
          expected_amount: expected,
          bank_received_amount: received,
          settlement_status,
          payment_date: payment_date || null,
          note: note ? String(note).trim() : null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'bs_year,bs_month_index' }
      )
      .select()
      .single();

    if (error) {
      console.error('Supabase upsert settlement error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in POST /api/settlements', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

