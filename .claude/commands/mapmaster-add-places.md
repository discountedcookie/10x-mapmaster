# MapMaster Add Places - Supervised Workflow

Add new places to the MapMaster database using a supervisor-agent pattern. You (Claude) supervise a
Zen agent that executes the enrichment and insertion workflow.

## Workflow Pattern

**Supervisor (You):** Select places, provide instructions, verify results
**Zen Agent:** Execute enrichment script, handle INSERT queries, report back

## Prerequisites

- Production environment variables in `.env.prod`
- Supabase edge function `generate-embedding` deployed
- Local database running (`npx supabase start`)
- Modified `scripts/add-new-place.ts` that outputs INSERT queries

## Instructions

### Phase 1: Setup & Selection

 1. **Start Zen agent session:**
    ```
    Use mcp__zen__clink with cli_name: "gemini"
    ```

 2. **Have Zen agent initialize:**
    ```
    Instruct: "Run serena initial_instructions and report when ready"
    Wait for: "Ready to proceed"
    ```

 3. **Make sure Zen agent is working with a local database:**
    ```
    Ask it to get database url with supabase mcp
    ```

 3. **Select places to add:**
    - Choose diverse types (natural feature, city, building, etc.)
    - Use real, verifiable places with good Wikipedia coverage
    - Example selection:
      - Natural: Lake Bled, Slovenia
      - City: Dubrovnik, Croatia
      - Building: Neuschwanstein Castle, Germany

 ### Phase 2: Add Each Place (Repeat for each)

 **Step 1: Instruct Zen Agent**

 Send to Zen agent via `mcp__zen__clink` with `continuation_id`:

 ```
 Task: Add [PLACE_TYPE] - [PLACE_NAME], [COUNTRY]

 Process:
 1. Run the add-place script with production environment:
    set -a && source .env.prod && set +a && npx tsx scripts/add-new-place.ts "[PLACE_NAME]"

 2. Copy the INSERT query from script output (between === lines)

 3. Execute INSERT via Supabase MCP: mcp__supabase__execute_sql

 4. Verify the place was added:
    SELECT id, name, lat, lng,
           descriptors->>'type' as type,
           descriptors->>'class' as class,
           embedding_text
    FROM places
    WHERE name LIKE '%[PLACE_NAME]%';

 5. Report results: Place ID, coordinates, type/class, embedding text, status
 ```

 **Step 2: Monitor Zen Agent**

 - Zen agent will execute all steps autonomously
 - Typical duration: 2-5 minutes per place
 - Zen agent uses: Nominatim, Open-Elevation, Overpass, Wikipedia APIs
 - Zen agent generates: 384-dimensional embedding via production edge function

 **Step 3: Verify Response**

 Expect from Zen agent:
 ```
 Place ID: [UUID]
 Coordinates: [lat], [lng]
 Type/Class: [type], [class]
 Embedding Text: [summary]
 Status: Success/Failed
 ```

 ### Phase 3: Verification

 After all places added, verify with SQL:

 ```sql
 -- Check all newly added places
 SELECT
   id,
   name,
   lat,
   lng,
   descriptors->>'type' as type,
   descriptors->>'class' as class,
   descriptors->>'country' as country,
   LENGTH(embedding_text) as embedding_text_length,
   octet_length(embedding::text) as embedding_size,
   created_at
 FROM places
 WHERE created_at > NOW() - INTERVAL '1 hour'
 ORDER BY created_at DESC;
 ```

 **Validation Checklist:**
 - ✅ Each place has unique UUID
 - ✅ Coordinates are valid (lat: -90 to 90, lng: -180 to 180)
 - ✅ Type/class populated from Nominatim
 - ✅ Embedding is ~4.7KB (384 dimensions)
 - ✅ Embedding text is descriptive
 - ✅ Created_at timestamp is recent

 ### Phase 4: Test Game Discovery

 Test that new places can be found by the game:

 ```sql
 -- Create test session with embedding for one of the new places
 INSERT INTO game_sessions (user_id, description, description_embedding, created_at)
 VALUES (
   'e5335fd5-348d-4047-9a9e-241e49bc01b8',
   '[Description matching one of your new places]',
   '[embedding from production edge function]'::vector(384),
   NOW()
 )
 RETURNING id;

 -- Check if new place appears in candidates
 SELECT * FROM get_candidates('[session_id]')
 WHERE name LIKE '%[NEW_PLACE_NAME]%';
 ```

 **Expected:**
 - New place appears in candidates with reasonable confidence (>0.6)
 - Semantic similarity reflects description match
 - Spatial confidence calculated correctly

 ### Phase 5: Report Results

 Create summary report:

 ```markdown
 ## MapMaster Place Addition - Results

 **Session Duration:** [X] minutes
 **Places Added:** [N]/[N] successful

 ### Added Places

 1. **[Place Name]**
    - ID: [UUID]
    - Type: [type/class]
    - Location: [city, country] ([lat], [lng])
    - Enrichment: [elevation/height if applicable]
    - Wikipedia: [yes/no]
    - Embedding Quality: [good/fair/needs review]

 [Repeat for each place]

 ### Game Discovery Test

 - Tested with: "[test description]"
 - New place found: [yes/no]
 - Confidence score: [0.XX]
 - Rank: [#N of 20 candidates]

 ### Issues Encountered

 [List any issues, API failures, or anomalies]

 ### Recommendations

 [Any suggestions for improving the workflow or data quality]
 ```

 ## Enrichment Details

 The `scripts/add-new-place.ts` script performs:

 1. **Nominatim Query** (Rate limit: 1 req/sec)
    - Returns: lat, lng, type, class, address, extratags
    - May return ambiguous results (e.g., guest house instead of famous palace)

 2. **Open-Elevation API**
    - Returns: elevation in meters
    - Stored in: `descriptors->>'elevation_meters'`

 3. **Overpass API**
    - Returns: building height if available
    - Stored in: `descriptors->>'height_meters'`

 4. **Wikipedia API**
    - Returns: article summary if Wikidata ID present
    - Stored in: `descriptors->>'wikipedia_summary'`

 5. **Embedding Generation**
    - Calls: Production Supabase edge function
    - Input: Generated text from enrichment
    - Output: 384-dimensional vector
    - Format: `[0.123, -0.456, ...]`

 6. **INSERT Query Generation**
    - Combines all data
    - Escapes SQL strings (single quotes → '')
    - Creates PostGIS geometry: `ST_SetSRID(ST_MakePoint(lng, lat), 4326)`
    - Casts embedding: `'[...]'::vector(384)`

 ## Error Handling

 **Common Issues:**

 1. **Nominatim returns wrong place**
    - Solution: Use more specific name (e.g., "Pena Palace Sintra Portugal")
    - Future: UI should show results list for user selection

 2. **Edge function timeout**
    - Retry after 2 seconds
    - Check production deployment status

 3. **Wikipedia summary not found**
    - Expected for places without Wikidata ID
    - Not a blocker, enrichment continues

 4. **Duplicate place name**
    - Check existing places first:
      ```sql
      SELECT name, lat, lng FROM places WHERE name ILIKE '%[name]%';
      ```

 5. **Zen agent connection issues**
    - Check stderr for "Connection failed for 'supabase'"
    - This is expected warning, doesn't affect functionality

 ## Performance Notes

 **Timing per place:**
 - Nominatim query: 1-3 seconds
 - Open-Elevation: 1-2 seconds
 - Overpass: 2-5 seconds
 - Wikipedia: 1-3 seconds
 - Embedding generation: 2-4 seconds
 - **Total: 7-17 seconds** (plus rate limiting)

 **Zen agent overhead:**
 - Session initialization: 10-15 seconds
 - Per-task overhead: 5-10 seconds
 - Token usage: ~20-30K tokens per place

 ## Production Considerations

 **DO NOT use this workflow on production database!**

 ## Technical Notes

 - Zen agent has access to all Supabase MCP tools
 - Zen agent uses Serena for code understanding
 - Continuation IDs preserve conversation context
 - Temp tables are session-scoped, auto-cleaned on disconnect

 ## Success Criteria

 A successful addition session:
 1. ✅ All selected places added without errors
 2. ✅ Each place has complete enrichment data
 3. ✅ Embeddings are valid 384-dimensional vectors
 4. ✅ Game can discover new places with descriptions
 5. ✅ No duplicate places created
 6. ✅ Coordinates validated (on actual location)

 ---

 **Example Usage:**

 ```
 User: /mapmaster-add-places
 Agent: Starting supervised place addition workflow...
 Agent: [Selects 3 diverse places]
 Agent: [Starts Zen session]
 Agent: [Guides Zen through each addition]
 Agent: [Verifies all 3 places]
 Agent: [Reports comprehensive results]
 ```

 Good luck adding places to MapMaster! 🗺️