-- Initial schema for {{PROJECT_NAME}}
-- This is a template migration file

-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- Create a simple users table (if not using Supabase Auth)
-- Note: Supabase Auth provides auth.users table automatically
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique,
  full_name text,
  avatar_url text,
  website text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Create policies
create policy "Public profiles are viewable by everyone." on profiles
  for select using ( true );

create policy "Users can insert their own profile." on profiles
  for insert with check ( auth.uid() = id );

create policy "Users can update own profile." on profiles
  for update using ( auth.uid() = id );

-- Create updated_at trigger
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_profiles_updated
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();
