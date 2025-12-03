-- Function: archive_trait_queue_by_place
-- Category: utilities
-- Purpose: Archive trait extraction queue messages for a given place_id
-- Called by edge function after successful trait extraction
CREATE OR REPLACE FUNCTION "game_logic"."archive_trait_queue_by_place" (
  p_place_id UUID
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game_logic, extensions, pgmq
AS $$
DECLARE
  v_archived INTEGER := 0;
  v_message RECORD;
BEGIN
  -- Read all messages for this place_id and archive them
  -- Using a short visibility timeout since we're archiving immediately
  FOR v_message IN
    SELECT msg_id, message 
    FROM pgmq.read('trait_extraction', 1, 100)
    WHERE message->>'place_id' = p_place_id::text
  LOOP
    PERFORM pgmq.archive('trait_extraction', v_message.msg_id);
    v_archived := v_archived + 1;
  END LOOP;
  
  RETURN v_archived;
END;
$$;


ALTER FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) OWNER TO "postgres";


-- Grant execute to service_role for edge function access
GRANT EXECUTE ON FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) TO service_role;


COMMENT ON FUNCTION "game_logic"."archive_trait_queue_by_place" (UUID) IS 'Archive trait extraction queue messages for a given place_id.

Called by the process-trait-extraction edge function after successful processing.
Archives (not deletes) messages to maintain history for debugging.

Parameters:
- p_place_id: UUID of the place whose messages should be archived

Returns: Number of messages archived.';
