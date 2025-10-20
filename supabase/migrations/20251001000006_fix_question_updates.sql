-- Fix question updates by adding RLS policy for authenticated users
-- This allows the game to update times_asked counter

-- Add UPDATE policy for questions (authenticated users can update)
CREATE POLICY "Authenticated users can update questions"
  ON questions FOR UPDATE
  USING (auth.role() = 'authenticated');
