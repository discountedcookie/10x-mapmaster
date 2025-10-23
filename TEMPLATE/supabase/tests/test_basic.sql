-- Basic database tests
-- These tests verify that the initial schema works correctly

begin;
select plan(1);

-- Test that profiles table exists and has correct structure
select has_table('public', 'profiles', 'profiles table should exist');

-- Add more tests here as your schema grows
-- Example:
-- select has_column('public', 'profiles', 'id', 'profiles should have id column');
-- select col_is_pk('public', 'profiles', 'id', 'id should be primary key');

select * from finish();
rollback;
