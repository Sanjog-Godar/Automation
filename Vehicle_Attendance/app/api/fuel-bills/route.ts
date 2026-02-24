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

// GET - Fetch all fuel bills or last bill date
export async function GET(req: NextRequest) {
  const supabase = supabaseServerClient();
  const url = new URL(req.url);
  const type = url.searchParams.get('type');

  try {
    // If requesting last bill date only
    if (type === 'last-date') {
      const { data, error } = await supabase
        .from('last_fuel_bill_date')
        .select('last_bill_date')
        .eq('id', 1)
        .single();
      
      if (error) {
        console.error('Supabase fetch last bill date error', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
      }
      
      return NextResponse.json({ data }, { status: 200 });
    }

    // Fetch all fuel bills, ordered by end_date descending
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

// PATCH - Update fuel bill dates or last bill date
export async function PATCH(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    const body = await req.json();
    const { id, start_date, end_date, last_bill_date } = body;

    // If updating the last_fuel_bill_date table directly
    if (last_bill_date !== undefined) {
      const { data, error } = await supabase
        .from('last_fuel_bill_date')
        .update({ 
          last_bill_date,
          updated_at: new Date().toISOString()
        })
        .eq('id', 1)
        .select()
        .single();

      if (error) {
        console.error('Supabase update last bill date error', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
      }

      return NextResponse.json({ data }, { status: 200 });
    }

    // Otherwise, update a specific fuel bill
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

    // If end_date was updated, also update the last_fuel_bill_date table
    if (end_date) {
      const { error: updateError } = await supabase
        .from('last_fuel_bill_date')
        .update({ 
          last_bill_date: end_date,
          updated_at: new Date().toISOString()
        })
        .eq('id', 1);
      
      if (updateError) {
        console.error('Error updating last fuel bill date:', updateError);
      }
    }

    return NextResponse.json({ data }, { status: 200 });
  } catch (err: any) {
    console.error('Unexpected error in PATCH /api/fuel-bills', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
