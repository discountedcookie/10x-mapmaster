-- Add descriptor_text column for embedding generation
-- This will contain rich natural language description of the place
ALTER TABLE places ADD COLUMN IF NOT EXISTS descriptor_text TEXT;

-- Add comment explaining the descriptor_text column
COMMENT ON COLUMN places.descriptor_text IS 'Rich natural language description generated from descriptors JSONB. Used for embedding generation.';
