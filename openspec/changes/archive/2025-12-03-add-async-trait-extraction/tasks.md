# Tasks: add-async-trait-extraction

## 1. Database Schema

- [x] 1.1 Add pgmq extension to `supabase/db/schema/01_extensions.sql`
- [x] 1.2 Add queue initialization (`pgmq.create('trait_extraction')`) to extensions file
- [x] 1.3 Verify with `supabase db reset` - all components load successfully

## 2. Edge Function for Async Processing

- [x] 2.1 Create `supabase/functions/process-trait-extraction/index.ts`
- [x] 2.2 Implement generic async RPC invoker (takes `function_name` and `params`)
- [x] 2.3 Returns success/failure JSON, logs errors
- [x] 2.4 Verified edge function serves and handles requests correctly

## 3. Trigger Modification

- [x] 3.1 Update `enqueue_trait_extraction()` to call `pgmq.send()` for durability
- [x] 3.2 Fix `net.http_post()` call signature (positional params, jsonb body)
- [x] 3.3 Both triggers use async pattern

## 4. Backup Processor (pg_cron)

- [x] 4.1 Create `process_orphaned_trait_jobs()` function
- [x] 4.2 Add pg_cron job scheduled every minute
- [x] 4.3 Function reads queue with visibility timeout, processes, archives

## 5. Testing

- [x] 5.1 Verified trigger fires on game win (UPDATE with was_correct=TRUE)
- [x] 5.2 Verified queue message created (msg_id=1, place_id present)
- [x] 5.3 Verified UPDATE completes in 13.6ms (vs 5-15+ seconds before)
- [x] 5.4 Verified edge function serves and handles RPC calls
- [ ] 5.5 End-to-end test: play game via browser, verify no timeout

## 6. Cleanup

- [x] 6.1 Removed redundant `05_queues.sql` (merged into extensions)
