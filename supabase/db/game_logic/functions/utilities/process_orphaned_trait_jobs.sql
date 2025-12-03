-- Function: process_orphaned_trait_jobs
-- Category: utilities
-- Purpose: Backup processor for orphaned trait extraction queue messages
-- Called by pg_cron every 60 seconds to process messages that weren't handled by the primary async path
CREATE OR REPLACE FUNCTION "game_logic"."process_orphaned_trait_jobs" ()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, game_logic, extensions, pgmq
AS $$
DECLARE
  v_message RECORD;
  v_processed INTEGER := 0;
  v_place_id UUID;
BEGIN
  -- Read up to 5 messages with 300 second visibility timeout
  -- Using 5 minutes to prevent race condition with 60-second cron interval
  -- Messages become visible again if not processed within timeout
  FOR v_message IN
    SELECT * FROM pgmq.read('trait_extraction', 300, 5)
  LOOP
    BEGIN
      -- Extract place_id from message
      v_place_id := (v_message.message->>'place_id')::UUID;
      
      IF v_place_id IS NOT NULL THEN
        -- Process the trait extraction
        PERFORM game_logic.update_place_traits(v_place_id);
        
        -- Archive the message (keeps history)
        PERFORM pgmq.archive('trait_extraction', v_message.msg_id);
        
        v_processed := v_processed + 1;
        
        RAISE LOG 'process_orphaned_trait_jobs: Processed place_id %, msg_id %', 
          v_place_id, v_message.msg_id;
      ELSE
        -- Invalid message, delete it
        PERFORM pgmq.delete('trait_extraction', v_message.msg_id);
        RAISE WARNING 'process_orphaned_trait_jobs: Invalid message deleted, msg_id %', 
          v_message.msg_id;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log error but continue processing other messages
      -- Message will become visible again after timeout for retry
      RAISE WARNING 'process_orphaned_trait_jobs: Failed to process msg_id %, error: %', 
        v_message.msg_id, SQLERRM;
    END;
  END LOOP;
  
  RETURN v_processed;
END;
$$;


ALTER FUNCTION "game_logic"."process_orphaned_trait_jobs" () OWNER TO "postgres";


COMMENT ON FUNCTION "game_logic"."process_orphaned_trait_jobs" () IS 'Backup processor for orphaned trait extraction jobs.

Called by pg_cron every 60 seconds to handle messages that:
1. Failed immediate processing via pg_net
2. Were enqueued but edge function was unavailable
3. Need retry after previous failure

Reads up to 5 messages per run with 60s visibility timeout.
Successfully processed messages are archived for history.
Failed messages remain in queue for retry.

Returns: Number of messages successfully processed.';
