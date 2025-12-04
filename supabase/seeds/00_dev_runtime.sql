-- Runtime configuration for LOCAL DEVELOPMENT ONLY
-- For production: set these via Supabase dashboard SQL editor or migrations
-- Uses host.docker.internal for Postgres-to-EdgeFunction calls (Docker networking)
-- These are the standard Supabase local dev keys (publicly documented)

INSERT INTO game_logic.config (key, value, description) VALUES
('runtime.supabase_url', '"http://host.docker.internal:54321"'::jsonb, 'Supabase API URL (Docker internal)'),
('runtime.supabase_anon_key', '"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"'::jsonb, 'Supabase anon key (local dev)'),
('runtime.supabase_service_role_key', '"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"'::jsonb, 'Supabase service role key (local dev)');
