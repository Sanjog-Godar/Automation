-- Table: attendance_logs

create table if not exists public.attendance_logs (
  log_date date primary key,
  status text not null check (status in ('present', 'absent_holiday', 'absent_replacement')),
  extra_trip_income numeric not null default 0,
  extra_tip_amount numeric not null default 0,
  extra_tip_note text
);

-- Optional: enable Row Level Security and policies as per your needs.
