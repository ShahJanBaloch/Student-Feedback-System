-- Add HOD as a separate role. Use it in later migrations after this commits.
alter type public.app_role add value if not exists 'hod';
