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
          value: Json
        }
        Insert: {
          description?: string | null
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          description?: string | null
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      embeddings: {
        Row: {
          created_at: string
          embedding: string
          id: string
          source_text: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          embedding: string
          id?: string
          source_text: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          embedding?: string
          id?: string
          source_text?: string
          updated_at?: string
        }
        Relationships: []
      }
      game_answers: {
        Row: {
          answer: Database["public"]["Enums"]["answer_value"]
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
          answer: Database["public"]["Enums"]["answer_value"]
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
          answer?: Database["public"]["Enums"]["answer_value"]
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
            foreignKeyName: "game_answers_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places_with_geometry"
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
            referencedRelation: "traits"
            referencedColumns: ["id"]
          },
        ]
      }
      game_sessions: {
        Row: {
          created_at: string
          description: string
          embedding_id: string | null
          id: string
          language_code: string
          next_turn: Json | null
          pending_review: boolean
          place_id: string | null
          status: Database["public"]["Enums"]["game_session_status"]
          updated_at: string
          user_id: string | null
          was_correct: boolean | null
        }
        Insert: {
          created_at?: string
          description: string
          embedding_id?: string | null
          id?: string
          language_code?: string
          next_turn?: Json | null
          pending_review?: boolean
          place_id?: string | null
          status?: Database["public"]["Enums"]["game_session_status"]
          updated_at?: string
          user_id?: string | null
          was_correct?: boolean | null
        }
        Update: {
          created_at?: string
          description?: string
          embedding_id?: string | null
          id?: string
          language_code?: string
          next_turn?: Json | null
          pending_review?: boolean
          place_id?: string | null
          status?: Database["public"]["Enums"]["game_session_status"]
          updated_at?: string
          user_id?: string | null
          was_correct?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "game_sessions_embedding_id_fkey"
            columns: ["embedding_id"]
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
          {
            foreignKeyName: "game_sessions_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places_with_geometry"
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
      place_traits: {
        Row: {
          created_at: string
          place_id: string
          trait_id: string
        }
        Insert: {
          created_at?: string
          place_id: string
          trait_id: string
        }
        Update: {
          created_at?: string
          place_id?: string
          trait_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "place_traits_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "place_traits_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places_with_geometry"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "place_traits_trait_id_fkey"
            columns: ["trait_id"]
            isOneToOne: false
            referencedRelation: "traits"
            referencedColumns: ["id"]
          },
        ]
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
          pending_review: boolean
          times_encountered: number
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
          pending_review?: boolean
          times_encountered?: number
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
          pending_review?: boolean
          times_encountered?: number
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
      traits: {
        Row: {
          clause: string
          created_at: string
          embedding_id: string | null
          id: string
        }
        Insert: {
          clause: string
          created_at?: string
          embedding_id?: string | null
          id: string
        }
        Update: {
          clause?: string
          created_at?: string
          embedding_id?: string | null
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "traits_embedding_id_fkey"
            columns: ["embedding_id"]
            isOneToOne: false
            referencedRelation: "embeddings"
            referencedColumns: ["id"]
          },
        ]
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
          {
            foreignKeyName: "game_sessions_place_id_fkey"
            columns: ["correct_place_id"]
            isOneToOne: false
            referencedRelation: "places_with_geometry"
            referencedColumns: ["id"]
          },
        ]
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
      places_with_geometry: {
        Row: {
          geometry: Json | null
          id: string | null
          lat: number | null
          lng: number | null
          name: string | null
          times_encountered: number | null
        }
        Insert: {
          geometry?: never
          id?: string | null
          lat?: number | null
          lng?: number | null
          name?: string | null
          times_encountered?: number | null
        }
        Update: {
          geometry?: never
          id?: string | null
          lat?: number | null
          lng?: number | null
          name?: string | null
          times_encountered?: number | null
        }
        Relationships: []
      }
      user_stats: {
        Row: {
          avg_turns_to_win: number | null
          games_played: number | null
          games_won: number | null
          last_played_at: string | null
          places_added: number | null
          win_rate: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      play_turn: {
        Args: {
          p_answer: Database["public"]["Enums"]["answer_value"]
          p_session_id: string
        }
        Returns: undefined
      }
      start_game: {
        Args: { p_description: string; p_language_code?: string }
        Returns: string
      }
      submit_place: {
        Args: { p_osm_id: string; p_session_id: string }
        Returns: undefined
      }
    }
    Enums: {
      answer_value: "yes" | "no" | "not_sure"
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
      answer_value: ["yes", "no", "not_sure"],
      game_session_status: ["active", "won", "ended", "needs_submission"],
      geographic_level: ["continent", "region", "country"],
      question_type: ["geographic", "semantic"],
    },
  },
} as const

