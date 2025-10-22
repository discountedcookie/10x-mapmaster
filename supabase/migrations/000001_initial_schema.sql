-- ============================================================================
-- 10x-mapmaster Database Schema
-- ============================================================================
-- Complete database schema including tables, extensions, RLS policies, and triggers
-- This migration must run before seed data and functions

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

-- Enable pgvector for embedding storage and similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable PostGIS for geographic/spatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Places table: Geographic locations with descriptors and embeddings
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  lat DOUBLE PRECISION,  -- NULL until enriched via script or user submission
  lng DOUBLE PRECISION,  -- NULL until enriched via script or user submission
  geom geometry(Point, 4326),  -- PostGIS point geometry for spatial queries (auto-synced from lat/lng)
  descriptors JSONB NOT NULL DEFAULT '{}'::jsonb,
  embedding vector(384),  -- gte-small embeddings (384 dimensions)
  game_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Questions table: Strategic yes/no questions for the guessing game
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text TEXT NOT NULL,
  question_type TEXT NOT NULL DEFAULT 'semantic' CHECK (question_type IN ('geographic', 'semantic')),
  geographic_region JSONB,  -- For geographic questions: bbox array [min_lng, min_lat, max_lng, max_lat]
  embedding vector(384),  -- gte-small embeddings (384 dimensions) - for semantic questions only
  times_asked INTEGER NOT NULL DEFAULT 0,
  effectiveness_score DOUBLE PRECISION NOT NULL DEFAULT 0.5,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Game sessions table: Player game sessions with their descriptions
CREATE TABLE game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  place_id UUID REFERENCES places(id) ON DELETE CASCADE, -- Nullable: set at game end
  was_correct BOOLEAN, -- Nullable: set at game end
  description TEXT,
  description_embedding vector(384),
  question_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Game answers table: Individual question-answer pairs during gameplay
CREATE TABLE game_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  answer BOOLEAN NOT NULL,
  candidates_after INTEGER NOT NULL,
  sequence_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Geographic indexes
CREATE INDEX idx_places_lat_lng ON places(lat, lng);
CREATE INDEX idx_places_geom ON places USING GIST (geom);

-- Vector similarity indexes (HNSW for fast approximate nearest neighbor search)
CREATE INDEX places_embedding_idx ON places USING hnsw (embedding vector_cosine_ops);
CREATE INDEX questions_embedding_idx ON questions USING hnsw (embedding vector_cosine_ops);

-- Game and learning indexes
CREATE INDEX idx_places_game_count ON places(game_count);
CREATE INDEX idx_questions_effectiveness ON questions(effectiveness_score DESC);

-- Session and answer indexes
CREATE INDEX idx_game_sessions_user_id ON game_sessions(user_id);
CREATE INDEX idx_game_sessions_created_at ON game_sessions(created_at DESC);
CREATE INDEX idx_game_answers_session_id ON game_answers(session_id);
CREATE INDEX idx_game_answers_sequence ON game_answers(sequence_number);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_answers ENABLE ROW LEVEL SECURITY;

-- Places: Public read, authenticated write
CREATE POLICY "Places are viewable by everyone"
  ON places FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert places"
  ON places FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update places"
  ON places FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Questions: Public read, authenticated update (for learning)
CREATE POLICY "Questions are viewable by everyone"
  ON questions FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can update questions"
  ON questions FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Game sessions: Users can only access their own sessions
CREATE POLICY "Users can view their own game sessions"
  ON game_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own game sessions"
  ON game_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Game answers: Users can only access answers for their own sessions
CREATE POLICY "Users can view their own game answers"
  ON game_answers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM game_sessions
      WHERE game_sessions.id = game_answers.session_id
      AND game_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own game answers"
  ON game_answers FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM game_sessions
      WHERE game_sessions.id = game_answers.session_id
      AND game_sessions.user_id = auth.uid()
    )
  );

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at for places
CREATE TRIGGER update_places_updated_at
  BEFORE UPDATE ON places
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically sync geometry with lat/lng
CREATE OR REPLACE FUNCTION update_geom_from_latlng()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create geometry if both lat and lng are present
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.geom = ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  ELSE
    NEW.geom = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to maintain geom column when lat/lng changes
CREATE TRIGGER sync_place_geom
  BEFORE INSERT OR UPDATE OF lat, lng ON places
  FOR EACH ROW
  EXECUTE FUNCTION update_geom_from_latlng();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE places IS 'Geographic locations with embeddings and descriptors for vector similarity search';
COMMENT ON TABLE questions IS 'Strategic yes/no questions for the guessing game. Geographic questions use PostGIS spatial queries, semantic questions use pgvector similarity matching.';
COMMENT ON TABLE game_sessions IS 'Player game sessions tracking descriptions and outcomes';
COMMENT ON TABLE game_answers IS 'Individual question-answer pairs during gameplay';

COMMENT ON COLUMN places.geom IS 'Geographic point for spatial queries. Automatically synced with lat/lng.';
COMMENT ON COLUMN places.embedding IS 'Vector embedding (gte-small, 384 dimensions) for semantic similarity search';
COMMENT ON COLUMN places.game_count IS 'Number of times this place has been played, used for learning rate calculation';
COMMENT ON COLUMN questions.question_type IS 'Type of filtering: geographic (PostGIS spatial) or semantic (pgvector similarity)';
COMMENT ON COLUMN questions.geographic_region IS 'For geographic questions: JSONB with bbox array [min_lng, min_lat, max_lng, max_lat]';
COMMENT ON COLUMN questions.embedding IS 'Vector embeddings for semantic questions only. Geographic questions use PostGIS and do not need embeddings.';
COMMENT ON COLUMN questions.effectiveness_score IS 'Effectiveness metric for question selection (0.0-1.0), updated through gameplay';
