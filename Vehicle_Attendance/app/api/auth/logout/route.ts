import { NextRequest, NextResponse } from 'next/server';
import { supabaseServerClient } from '@/lib/supabaseClient';

export async function POST(req: NextRequest) {
  const supabase = supabaseServerClient();

  try {
    // Sign out from Supabase
    await supabase.auth.signOut();

    // Create response
    const response = NextResponse.json(
      { message: 'Logout successful' },
      { status: 200 }
    );

    // Clear cookies
    response.cookies.delete('sb-access-token');
    response.cookies.delete('sb-refresh-token');

    return response;
  } catch (err) {
    console.error('Logout error:', err);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
