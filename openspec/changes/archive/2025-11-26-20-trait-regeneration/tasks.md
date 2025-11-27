# Tasks: Add Trait Regeneration

- [x] Implement regenerate_place_traits(place_id)
- [x] Fetch place data and approved session descriptions
- [x] Call LLM with JSON prompt for trait extraction
- [x] Delete old place_traits, insert new with ON CONFLICT
- [x] Regenerate place embedding via get_or_create_embedding
- [x] Error handling with logging (doesn't fail on parse errors)
