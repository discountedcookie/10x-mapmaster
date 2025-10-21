-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Add embedding and learning columns to places table
ALTER TABLE places ADD COLUMN embedding vector(384);
ALTER TABLE places ADD COLUMN game_count INTEGER NOT NULL DEFAULT 0;

-- Add embedding and effectiveness columns to questions table
ALTER TABLE questions ADD COLUMN embedding vector(384);
ALTER TABLE questions ADD COLUMN times_asked INTEGER NOT NULL DEFAULT 0;
ALTER TABLE questions ADD COLUMN effectiveness_score DOUBLE PRECISION NOT NULL DEFAULT 0.5;

-- Add description and embedding columns to game_sessions table
ALTER TABLE game_sessions ADD COLUMN description TEXT;
ALTER TABLE game_sessions ADD COLUMN description_embedding vector(384);
ALTER TABLE game_sessions ADD COLUMN question_count INTEGER NOT NULL DEFAULT 0;

-- Create vector similarity search function for places
CREATE OR REPLACE FUNCTION match_places(
  query_embedding vector(384),
  match_threshold float DEFAULT 0.3,
  match_count int DEFAULT 20
)
RETURNS TABLE (
  id uuid,
  name text,
  lat double precision,
  lng double precision,
  descriptors jsonb,
  game_count int,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    places.id,
    places.name,
    places.lat,
    places.lng,
    places.descriptors,
    places.game_count,
    1 - (places.embedding <=> query_embedding) as similarity
  FROM places
  WHERE places.embedding IS NOT NULL
    AND 1 - (places.embedding <=> query_embedding) > match_threshold
  ORDER BY places.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Create vector similarity search function for questions
CREATE OR REPLACE FUNCTION match_questions(
  query_embedding vector(384),
  match_count int DEFAULT 10
)
RETURNS TABLE (
  id uuid,
  text text,
  times_asked int,
  effectiveness_score double precision,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    questions.id,
    questions.text,
    questions.times_asked,
    questions.effectiveness_score,
    1 - (questions.embedding <=> query_embedding) as similarity
  FROM questions
  WHERE questions.embedding IS NOT NULL
  ORDER BY questions.effectiveness_score DESC, questions.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Create HNSW indexes for performance (cosine distance)
CREATE INDEX places_embedding_idx ON places USING hnsw (embedding vector_cosine_ops);
CREATE INDEX questions_embedding_idx ON questions USING hnsw (embedding vector_cosine_ops);

-- Add index on game_count for learning queries
CREATE INDEX idx_places_game_count ON places(game_count);

-- Add index on effectiveness_score for question selection
CREATE INDEX idx_questions_effectiveness ON questions(effectiveness_score DESC);

-- Update RLS policy for places to allow updates to embedding and game_count
-- (Policy already exists for authenticated users to update, just documenting)

-- Function to update question effectiveness score
CREATE OR REPLACE FUNCTION update_question_effectiveness(
  question_id_param uuid,
  new_effectiveness float
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE questions
  SET 
    effectiveness_score = (effectiveness_score + new_effectiveness) / 2.0,
    times_asked = times_asked + 1
  WHERE id = question_id_param;
END;
$$;

-- Function to update place embedding with weighted average
CREATE OR REPLACE FUNCTION update_place_embedding(
  place_id_param uuid,
  new_embedding vector(384),
  learning_rate float DEFAULT 0.3
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_embedding vector(384);
  current_count int;
  weight float;
BEGIN
  SELECT embedding, game_count INTO current_embedding, current_count
  FROM places
  WHERE id = place_id_param;

  -- If no existing embedding, just use the new one
  IF current_embedding IS NULL THEN
    UPDATE places
    SET 
      embedding = new_embedding,
      game_count = game_count + 1
    WHERE id = place_id_param;
    RETURN;
  END IF;

  -- Calculate weight based on game count (less weight to new data as count increases)
  weight := learning_rate / (1.0 + current_count * 0.1);
  
  -- Weighted average: old_embedding * (1 - weight) + new_embedding * weight
  UPDATE places
  SET 
    embedding = (
      SELECT array_agg(
        (1.0 - weight) * old_val + weight * new_val
      )::vector(384)
      FROM unnest(current_embedding::float[], new_embedding::float[]) AS t(old_val, new_val)
    ),
    game_count = game_count + 1
  WHERE id = place_id_param;
END;
$$;




