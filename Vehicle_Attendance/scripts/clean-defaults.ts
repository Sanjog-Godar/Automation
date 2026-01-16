import { config } from 'dotenv';
import { resolve } from 'path';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
config({ path: resolve(process.cwd(), '.env.local') });

// Clean up default/unmodified entries from the database
async function cleanDefaults() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Supabase environment variables are not set');
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false },
  });
  
  console.log('Cleaning default unmodified entries...');
  
  // Delete all entries that are default (absent_holiday with all zeros and no note)
  const { error, count } = await supabase
    .from('attendance_logs')
    .delete({ count: 'exact' })
    .eq('status', 'absent_holiday')
    .eq('extra_trip_income', 0)
    .eq('extra_tip_amount', 0)
    .is('extra_tip_note', null);
  
  if (error) {
    console.error('Error cleaning defaults:', error);
    throw error;
  }
  
  console.log(`✅ Successfully deleted ${count} default entries!`);
  console.log('Only user-modified entries remain in the database.');
}

cleanDefaults()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
