# Tasks: Add Geographic Regions

- [x] Create geographic_regions table: id uuid PK, name text NOT NULL, level text NOT NULL, geom geometry NOT NULL, created_at
- [x] Constraints: CHECK level in allowed set; NOT NULL geom
- [x] Indexes: GIST on geom; index on level
- [x] RLS: read-open; writes restricted to service_role
- [x] Comments
