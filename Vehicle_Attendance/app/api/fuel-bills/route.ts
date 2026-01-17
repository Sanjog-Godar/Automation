import { NextRequest, NextResponse } from 'next/server';
import { supabaseServerClient } from '@/lib/supabaseClient';

interface CreateFuelBillBody {
  start_date: string; // YYYY-MM-DD
  end_date: string; // YYYY-MM-DD
  total_km: number;
  expected_liters: number;
  actual_liters?: number | null;
}

// POST - Create a new fuel bill
export async function POST(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const body = (await req.json()) as CreateFuelBillBody;
    const { start_date, end_date, total_km, expected_liters, actual_liters } = body;

    if (!start_date || !end_date || total_km === undefined || expected_liters === undefined) {
      return NextResponse.json(
        { error: 'start_date, end_date, total_km, and expected_liters are required' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('fuel_bills')
      .insert({
        start_date,
        end_date,
        total_km,
        expected_liters,
        actual_liters: actual_liters ?? null,
      })
      .select()
      .single();

    if (error) {
      console.error('Supabase insert error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in POST /api/fuel-bills', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// GET - Fetch all fuel bills, ordered by end_date descending
export async function GET(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const { data, error } = await supabase
      .from('fuel_bills')
      .select('*')
      .order('end_date', { ascending: false });

    if (error) {
      console.error('Supabase fetch error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in GET /api/fuel-bills', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
