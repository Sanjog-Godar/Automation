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

// PATCH - Update fuel bill dates
export async function PATCH(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const body = await req.json();
    const { id, start_date, end_date } = body;

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    // Build update object with only provided fields
    const updates: any = {};
    if (start_date) updates.start_date = start_date;
    if (end_date) updates.end_date = end_date;

    if (Object.keys(updates).length === 0) {
      return NextResponse.json(
        { error: 'At least one field (start_date or end_date) must be provided' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('fuel_bills')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Supabase update error', error);
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in PATCH /api/fuel-bills', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
