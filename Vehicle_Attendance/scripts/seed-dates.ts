import { config } from 'dotenv';
import { resolve } from 'path';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
config({ path: resolve(process.cwd(), '.env.local') });

// Seed the database with dates for the next 5 years
async function seedDates() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  
  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Supabase environment variables are not set');
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false },
  });
  
  const startDate = new Date();
  const endDate = new Date();
  endDate.setFullYear(endDate.getFullYear() + 5);
  
  console.log(`Seeding dates from ${startDate.toISOString()} to ${endDate.toISOString()}`);
  
  const dates: Array<{
    log_date: string;
    status: string;
    extra_trip_income: number;
    extra_tip_amount: number;
    extra_tip_note: null;
  }> = [];
  
  const currentDate = new Date(startDate);
  
  while (currentDate <= endDate) {
    const dateStr = currentDate.toISOString().split('T')[0]; // YYYY-MM-DD
    dates.push({
      log_date: dateStr,
      status: 'absent_holiday', // Default to holiday
      extra_trip_income: 0,
      extra_tip_amount: 0,
      extra_tip_note: null,
    });
    
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  console.log(`Generated ${dates.length} date entries`);
  
  // Insert in batches of 500 to avoid payload limits
  const batchSize = 500;
  let inserted = 0;
  
  for (let i = 0; i < dates.length; i += batchSize) {
    const batch = dates.slice(i, i + batchSize);
    
    const { error } = await supabase
      .from('attendance_logs')
      .upsert(batch, { onConflict: 'log_date' });
    
    if (error) {
      console.error(`Error inserting batch ${i / batchSize + 1}:`, error);
    } else {
      inserted += batch.length;
      console.log(`Inserted batch ${i / batchSize + 1}: ${inserted}/${dates.length} dates`);
    }
  }
  
  console.log(`✅ Successfully seeded ${inserted} dates!`);
}

seedDates()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error seeding dates:', error);
    process.exit(1);
  });
