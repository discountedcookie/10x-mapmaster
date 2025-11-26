export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      app_settings: {
        Row: {
          description: string | null
          key: string
          updated_at: string
          value: string
        }
        Insert: {
          description?: string | null
          key: string
          updated_at?: string
          value: string
        }
        Update: {
          description?: string | null
          key?: string
          updated_at?: string
          value?: string
        }
        Relationships: []
      }
      config: {
        Row: {
          description: string | null
          key: string
          updated_at: string
          value: string
        }
        Insert: {
          description?: string | null
          key: string
          updated_at?: string
          value: string
        }
        Update: {
          description?: string | null
          key?: string
          updated_at?: string
          value?: string
        }
        Relationships: []
      }
      embeddings: {
        Row: {
          created_at: string
          embedding: string
          id: string
          text: string
          text_hash: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          embedding: string
          id?: string
          text: string
          text_hash: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          embedding?: string
          id?: string
          text?: string
          text_hash?: string
          updated_at?: string
        }
        Relationships: []
      }
      game_answers: {
        Row: {
          answer: boolean
          candidates: Json | null
          created_at: string
          geographic_region_id: string | null
          id: string
          place_id: string | null
          question_text: string | null
          session_id: string
          trait_id: string | null
        }
        Insert: {
          answer: boolean
          candidates?: Json | null
          created_at?: string
          geographic_region_id?: string | null
          id?: string
          place_id?: string | null
          question_text?: string | null
          session_id: string
          trait_id?: string | null
        }
        Update: {
          answer?: boolean
          candidates?: Json | null
          created_at?: string
          geographic_region_id?: string | null
          id?: string
          place_id?: string | null
          question_text?: string | null
          session_id?: string
          trait_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "game_answers_geographic_region_id_fkey"
            columns: ["geographic_region_id"]
            isOneToOne: false
            referencedRelation: "geographic_regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_answers_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_answers_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "game_session_state"
            referencedColumns: ["session_id"]
          },
          {
            foreignKeyName: "game_answers_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "game_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_answers_trait_id_fkey"
            columns: ["trait_id"]
            isOneToOne: false
            referencedRelation: "place_traits"
            referencedColumns: ["id"]
          },
        ]
      }
      game_sessions: {
        Row: {
          affirmed_trait_embedding_id: string | null
          affirmed_trait_ids: string[]
          created_at: string
          denied_trait_embedding_id: string | null
          denied_trait_ids: string[]
          description: string
          description_embedding_id: string | null
          description_language_code: string
          id: string
          next_turn: Json | null
          pending_review: boolean
          place_id: string | null
          submitted_lat: number | null
          submitted_lng: number | null
          submitted_nominatim_id: string | null
          submitted_place_name: string | null
          user_id: string | null
          was_correct: boolean | null
        }
        Insert: {
          affirmed_trait_embedding_id?: string | null
          affirmed_trait_ids?: string[]
          created_at?: string
          denied_trait_embedding_id?: string | null
          denied_trait_ids?: string[]
          description: string
          description_embedding_id?: string | null
          description_language_code?: string
          id?: string
          next_turn?: Json | null
          pending_review?: boolean
          place_id?: string | null
          submitted_lat?: number | null
          submitted_lng?: number | null
          submitted_nominatim_id?: string | null
          submitted_place_name?: string | null
          user_id?: string | null
          was_correct?: boolean | null
        }
        Update: {
          affirmed_trait_embedding_id?: string | null
          affirmed_trait_ids?: string[]
          created_at?: string
          denied_trait_embedding_id?: string | null
          denied_trait_ids?: string[]
          description?: string
          description_embedding_id?: string | null
          description_language_code?: string
          id?: string
          next_turn?: Json | null
          pending_review?: boolean
          place_id?: string | null
          submitted_lat?: number | null
          submitted_lng?: number | null
          submitted_nominatim_id?: string | null
          submitted_place_name?: string | null
          user_id?: string | null
          was_correct?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "game_sessions_affirmed_trait_embedding_id_fkey"
            columns: ["affirmed_trait_embedding_id"]
            isOneToOne: false
            referencedRelation: "embeddings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_sessions_denied_trait_embedding_id_fkey"
            columns: ["denied_trait_embedding_id"]
            isOneToOne: false
            referencedRelation: "embeddings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_sessions_description_embedding_id_fkey"
            columns: ["description_embedding_id"]
            isOneToOne: false
            referencedRelation: "embeddings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "game_sessions_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      geographic_regions: {
        Row: {
          continent_id: string | null
          created_at: string
          geom: unknown
          id: string
          iso_code: string | null
          level: string
          name: string
        }
        Insert: {
          continent_id?: string | null
          created_at?: string
          geom: unknown
          id?: string
          iso_code?: string | null
          level: string
          name: string
        }
        Update: {
          continent_id?: string | null
          created_at?: string
          geom?: unknown
          id?: string
          iso_code?: string | null
          level?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "geographic_regions_continent_id_fkey"
            columns: ["continent_id"]
            isOneToOne: false
            referencedRelation: "geographic_regions"
            referencedColumns: ["id"]
          },
        ]
      }
      place_trait_links: {
        Row: {
          created_at: string
          place_id: string
          source_metadata: Json
          source_type: string
          trait_id: string
        }
        Insert: {
          created_at?: string
          place_id: string
          source_metadata?: Json
          source_type?: string
          trait_id: string
        }
        Update: {
          created_at?: string
          place_id?: string
          source_metadata?: Json
          source_type?: string
          trait_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "place_trait_links_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "place_trait_links_trait_id_fkey"
            columns: ["trait_id"]
            isOneToOne: false
            referencedRelation: "place_traits"
            referencedColumns: ["id"]
          },
        ]
      }
      place_traits: {
        Row: {
          category: string
          clause: string
          created_at: string
          id: string
        }
        Insert: {
          category: string
          clause: string
          created_at?: string
          id: string
        }
        Update: {
          category?: string
          clause?: string
          created_at?: string
          id?: string
        }
        Relationships: []
      }
      places: {
        Row: {
          created_at: string
          embedding_id: string | null
          geom: unknown
          id: string
          lat: number | null
          lng: number | null
          name: string
          osm_id: string
          times_encountered: number
          traits: string[]
          updated_at: string
        }
        Insert: {
          created_at?: string
          embedding_id?: string | null
          geom?: unknown
          id?: string
          lat?: number | null
          lng?: number | null
          name: string
          osm_id: string
          times_encountered?: number
          traits?: string[]
          updated_at?: string
        }
        Update: {
          created_at?: string
          embedding_id?: string | null
          geom?: unknown
          id?: string
          lat?: number | null
          lng?: number | null
          name?: string
          osm_id?: string
          times_encountered?: number
          traits?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "places_embedding_id_fkey"
            columns: ["embedding_id"]
            isOneToOne: false
            referencedRelation: "embeddings"
            referencedColumns: ["id"]
          },
        ]
      }
      question_stats: {
        Row: {
          created_at: string
          effectiveness_score: number
          geographic_region_id: string | null
          id: string
          question_type: Database["public"]["Enums"]["question_type"]
          times_asked: number
          trait_id: string | null
        }
        Insert: {
          created_at?: string
          effectiveness_score?: number
          geographic_region_id?: string | null
          id?: string
          question_type: Database["public"]["Enums"]["question_type"]
          times_asked?: number
          trait_id?: string | null
        }
        Update: {
          created_at?: string
          effectiveness_score?: number
          geographic_region_id?: string | null
          id?: string
          question_type?: Database["public"]["Enums"]["question_type"]
          times_asked?: number
          trait_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "question_stats_geographic_region_id_fkey"
            columns: ["geographic_region_id"]
            isOneToOne: false
            referencedRelation: "geographic_regions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "question_stats_trait_id_fkey"
            columns: ["trait_id"]
            isOneToOne: false
            referencedRelation: "place_traits"
            referencedColumns: ["id"]
          },
        ]
      }
      rate_limit_log: {
        Row: {
          action: string
          created_at: string
          id: string
          ip_address: unknown
          user_agent: string | null
          user_id: string
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          ip_address?: unknown
          user_agent?: string | null
          user_id: string
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          user_agent?: string | null
          user_id?: string
        }
        Relationships: []
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      game_session_state: {
        Row: {
          correct_place_id: string | null
          correct_place_lat: number | null
          correct_place_lng: number | null
          correct_place_name: string | null
          current_question_id: string | null
          current_question_text: string | null
          description: string | null
          next_turn: Json | null
          pending_guess_place_id: string | null
          pending_guess_place_name: string | null
          question_count: number | null
          session_id: string | null
          status: Database["public"]["Enums"]["game_session_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "game_sessions_place_id_fkey"
            columns: ["correct_place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      global_stats: {
        Row: {
          active_sessions: number | null
          avg_questions_per_session: number | null
          global_win_rate_percent: number | null
          sessions_last_24h: number | null
          sessions_last_30d: number | null
          sessions_last_7d: number | null
          sessions_lost: number | null
          sessions_submitted: number | null
          sessions_won: number | null
          top_places_guessed: Json | null
          total_embeddings: number | null
          total_places: number | null
          total_players: number | null
          total_sessions: number | null
          total_traits: number | null
          unique_users: number | null
        }
        Relationships: []
      }
      user_stats: {
        Row: {
          active_sessions: number | null
          avg_questions_per_session: number | null
          best_win_streak: number | null
          current_win_streak: number | null
          last_session_at: string | null
          last_win_at: string | null
          sessions_lost: number | null
          sessions_submitted: number | null
          sessions_won: number | null
          total_sessions: number | null
          win_rate_percent: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      add_place: {
        Args: {
          p_geojson?: Json
          p_lat?: number
          p_lng?: number
          p_name: string
          p_osm_id: string
          p_traits?: string[]
        }
        Returns: string
      }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      adjust_score: {
        Args: {
          p_answer: string
          p_base_weight?: number
          p_beta?: number
          p_current_score: number
          p_match_strength: number
          p_match_zone: string
        }
        Returns: number
      }
      apply_answer_to_session_state: {
        Args: {
          p_answer: boolean
          p_geographic_region_id: string
          p_session_id: string
          p_trait_id: string
        }
        Returns: undefined
      }
      apply_metadata_filter: {
        Args: { answer?: boolean; descriptors: Json; filter_config: Json }
        Returns: boolean
      }
      approve_pending_place: { Args: { p_place_id: string }; Returns: Json }
      build_guess_turn: {
        Args: { p_candidates: Json; p_top_candidate: Json }
        Returns: Json
      }
      build_question_turn: {
        Args: {
          p_candidates: Json
          p_geographic_region_id: string
          p_question_reasoning: string
          p_question_text: string
          p_question_type: Database["public"]["Enums"]["question_type"]
          p_trait_id: string
        }
        Returns: Json
      }
      calculate_confidence_metrics: {
        Args: { p_probabilities: number[] }
        Returns: {
          margin: number
          normalized_entropy: number
          top_prob: number
        }[]
      }
      calculate_split_quality: {
        Args: { p_matching_count: number; p_total_count: number }
        Returns: number
      }
      calculate_trait_match_strength: {
        Args: {
          p_partial_threshold?: number
          p_place_embedding: string
          p_strong_threshold?: number
          p_trait_embedding: string
        }
        Returns: {
          match_strength: number
          match_zone: string
        }[]
      }
      call_llm_api: {
        Args: { p_format?: string; p_prompt: string }
        Returns: string
      }
      decide_next_turn: {
        Args: { p_candidates: Json; p_session_id: string }
        Returns: {
          session_id: string
        }[]
      }
      deduplicate_places: {
        Args: never
        Returns: {
          duplicates_removed: number
          places_kept: number
        }[]
      }
      disablelongtransactions: { Args: never; Returns: string }
      dropgeometrycolumn:
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
      dropgeometrytable:
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
      enablelongtransactions: { Args: never; Returns: string }
      enrich_place: { Args: { p_place_id: string }; Returns: Json }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      filter_candidates_by_geography: {
        Args: { p_answer: string; p_candidates: Json; p_region_id: string }
        Returns: Json
      }
      filter_geographic_candidates: {
        Args: { p_session_id: string }
        Returns: {
          distance_from_bbox_center: number
          embedding_id: string
          geom: unknown
          id: string
          lat: number
          lng: number
          name: string
          traits: string[]
        }[]
      }
      filter_semantic_candidates: {
        Args: { p_place_ids: string[]; p_session_id: string }
        Returns: {
          affirmed_trait_similarity: number
          base_description_similarity: number
          denied_trait_similarity: number
          place_id: string
        }[]
      }
      generate_embedding: { Args: { p_text: string }; Returns: string }
      geo_region_for: { Args: { p_feature_value: string }; Returns: Json }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_active_prompt: { Args: never; Returns: string }
      get_candidates: {
        Args: { session_id_param: string }
        Returns: {
          candidates: Json
          count: number
        }[]
      }
      get_geographic_questions: {
        Args: { p_candidates: Json; p_limit?: number; p_session_id: string }
        Returns: {
          effectiveness_score: number
          information_gain: number
          no_count: number
          region_id: string
          region_level: string
          region_name: string
          times_asked: number
          yes_count: number
        }[]
      }
      get_initial_candidates: {
        Args: {
          p_description_embedding_id: string
          p_initial_threshold?: number
          p_max_candidates?: number
        }
        Returns: {
          lat: number
          lng: number
          place_id: string
          place_name: string
          raw_score: number
        }[]
      }
      get_llm_question: {
        Args: {
          p_available_questions: Json
          p_candidates: Json
          p_session_id: string
        }
        Returns: {
          geographic_region_id: string
          question_reasoning: string
          question_text: string
          question_type: Database["public"]["Enums"]["question_type"]
          trait_id: string
        }[]
      }
      get_max_turns: { Args: never; Returns: number }
      get_or_create_embedding: { Args: { p_text: string }; Returns: string }
      get_question: {
        Args: { p_candidates: Json; p_session_id: string }
        Returns: {
          geographic_region_id: string
          question_reasoning: string
          question_text: string
          question_type: Database["public"]["Enums"]["question_type"]
          trait_id: string
        }[]
      }
      get_semantic_questions: {
        Args: { p_limit?: number; p_session_id: string }
        Returns: {
          effectiveness_score: number
          times_asked: number
          trait_category: string
          trait_clause: string
          trait_id: string
        }[]
      }
      gettransactionid: { Args: never; Returns: unknown }
      handle_guess: {
        Args: { p_answer: boolean; p_session_record: Record<string, unknown> }
        Returns: undefined
      }
      handle_question: {
        Args: { p_answer: boolean; p_session_record: Record<string, unknown> }
        Returns: undefined
      }
      is_installed: {
        Args: { p_description: string; p_extname: string }
        Returns: boolean
      }
      longtransactionsenabled: { Args: never; Returns: boolean }
      maintenance_cleanup: { Args: never; Returns: undefined }
      maintenance_weekly: {
        Args: never
        Returns: {
          places_duplicates_removed: number
          places_kept: number
          questions_duplicates_removed: number
          questions_kept: number
        }[]
      }
      match_places: {
        Args: {
          constraint_text?: string
          filters?: Json
          match_count?: number
          match_threshold?: number
          query_embedding: string
        }
        Returns: {
          composite_confidence: number
          descriptors: Json
          id: string
          lat: number
          lng: number
          name: string
          semantic_similarity: number
          spatial_confidence: number
        }[]
      }
      play_turn: {
        Args: { p_answer: boolean; p_session_id: string }
        Returns: undefined
      }
      populate_geometry_columns:
        | { Args: { use_typmod?: boolean }; Returns: string }
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      record_game_answer: {
        Args: {
          p_answer: boolean
          p_candidates: Json
          p_geographic_region_id: string
          p_place_id: string
          p_question_text: string
          p_session_id: string
          p_trait_id: string
        }
        Returns: undefined
      }
      row_security_is_enabled: {
        Args: { p_description: string; p_schema: string; p_table: string }
        Returns: boolean
      }
      select_best_question: {
        Args: {
          p_candidates: Json
          p_geographic_preference_threshold?: number
          p_min_split_quality?: number
          p_session_id: string
        }
        Returns: {
          geographic_region_id: string
          question_text: string
          question_type: string
          split_quality: number
          trait_id: string
        }[]
      }
      should_guess: {
        Args: {
          p_entropy_threshold?: number
          p_margin_threshold?: number
          p_probabilities: number[]
          p_top_prob_threshold?: number
        }
        Returns: boolean
      }
      softmax_probabilities: {
        Args: { p_scores: number[]; p_temperature?: number }
        Returns: number[]
      }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_askml:
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geom: unknown }; Returns: number }
        | { Args: { geog: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      start_game:
        | {
            Args: { p_description: string; p_language_code: string }
            Returns: {
              session_id: string
            }[]
          }
        | {
            Args: { p_description: string }
            Returns: {
              session_id: string
            }[]
          }
      unlockrows: { Args: { "": string }; Returns: number }
      update_embedding: {
        Args: { p_id: string; p_new_text: string }
        Returns: undefined
      }
      update_place_embedding: {
        Args: {
          learning_rate?: number
          new_embedding: string
          place_id_param: string
        }
        Returns: undefined
      }
      update_question_effectiveness_batch: {
        Args: { session_id_param: string }
        Returns: undefined
      }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
      validate_user_input: {
        Args: { p_field_name?: string; p_input: string; p_max_length: number }
        Returns: string
      }
    }
    Enums: {
      game_session_status: "active" | "won" | "ended" | "needs_submission"
      geographic_level: "continent" | "region" | "country"
      question_type: "geographic" | "semantic"
    }
    CompositeTypes: {
      error_response: {
        error_code: string | null
        http_status: number | null
        details: Json | null
      }
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      game_session_status: ["active", "won", "ended", "needs_submission"],
      geographic_level: ["continent", "region", "country"],
      question_type: ["geographic", "semantic"],
    },
  },
} as const

