-- This migration will be populated with actual embedding vectors after running the seed script
-- The embeddings will be generated using the generate-embedding Edge Function
-- and inserted via a one-time Node.js script

-- For now, this serves as a placeholder to maintain migration order
-- Actual embeddings will be added by running: npm run seed:embeddings

-- NOTE: This approach allows us to:
-- 1. Keep migrations in order
-- 2. Generate embeddings dynamically (not hardcoded in SQL)
-- 3. Reuse the same embedding logic that the app will use

-- Placeholder comment to track that seed embeddings should be generated
-- Run: npm run seed:embeddings after applying this migration




