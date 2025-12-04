#!/bin/bash
# LLM Testing Script - uses psql for direct database access
# Usage:
#   ./scripts/test-llm.sh traits "Eiffel Tower"
#   ./scripts/test-llm.sh question "trait clause" "user description"
#   ./scripts/test-llm.sh region "Poland" "A royal castle"
#   ./scripts/test-llm.sh config
#   ./scripts/test-llm.sh set-config "llm.question.model" '"new-model"'

PSQL="psql postgresql://postgres:postgres@127.0.0.1:54322/postgres"

case "$1" in
  "traits")
    PLACE_NAME="$2"
    echo "🔍 Testing trait extraction for: $PLACE_NAME"
    echo ""
    
    # Find place and show current traits
    $PSQL -c "
      SELECT p.id, p.name, array_agg(t.clause) as current_traits
      FROM places p
      LEFT JOIN place_traits pt ON pt.place_id = p.id
      LEFT JOIN traits t ON t.id = pt.trait_id
      WHERE p.name ILIKE '%$PLACE_NAME%'
      GROUP BY p.id, p.name
      LIMIT 1;
    "
    
    echo ""
    echo "🤖 Running trait extraction (check NOTICE output above)..."
    echo ""
    
    # Get place ID and run extraction
    PLACE_ID=$($PSQL -t -c "SELECT id FROM places WHERE name ILIKE '%$PLACE_NAME%' LIMIT 1;" | tr -d ' \n')
    
    if [ -z "$PLACE_ID" ]; then
      echo "Place not found: $PLACE_NAME"
      exit 1
    fi
    
    $PSQL -c "SELECT game_logic.update_place_traits('$PLACE_ID'::uuid);"
    
    echo ""
    echo "✨ New traits:"
    $PSQL -c "
      SELECT t.clause
      FROM place_traits pt
      JOIN traits t ON t.id = pt.trait_id
      WHERE pt.place_id = '$PLACE_ID'::uuid
      ORDER BY t.clause;
    "
    ;;
    
  "question")
    TRAIT_CLAUSE="$2"
    DESCRIPTION="${3:-A famous landmark}"
    
    echo "🔍 Testing question generation for trait: \"$TRAIT_CLAUSE\""
    echo "   Description: \"$DESCRIPTION\""
    echo ""
    
    # Find trait
    TRAIT_ID=$($PSQL -t -c "SELECT id FROM traits WHERE clause ILIKE '%$TRAIT_CLAUSE%' LIMIT 1;" | tr -d ' \n')
    
    if [ -z "$TRAIT_ID" ]; then
      echo "Trait not found. Available traits matching '$TRAIT_CLAUSE':"
      $PSQL -c "SELECT clause FROM traits WHERE clause ILIKE '%${TRAIT_CLAUSE%% *}%' LIMIT 10;"
      exit 1
    fi
    
    echo "Found trait ID: $TRAIT_ID"
    echo ""
    
    echo "📝 Turn 1 question (extracts noun from description):"
    $PSQL -c "SELECT game_logic.generate_question_text('$TRAIT_ID'::uuid, NULL, 'en', '$DESCRIPTION', 1);"
    
    echo ""
    echo "📝 Turn 2+ question (uses 'it'):"
    $PSQL -c "SELECT game_logic.generate_question_text('$TRAIT_ID'::uuid, NULL, 'en', '$DESCRIPTION', 2);"
    ;;
    
  "region")
    REGION_NAME="$2"
    DESCRIPTION="${3:-A famous landmark}"
    
    echo "🔍 Testing region question for: \"$REGION_NAME\""
    echo "   Description: \"$DESCRIPTION\""
    echo ""
    
    # Find region
    REGION_ID=$($PSQL -t -c "SELECT id FROM game_logic.geographic_regions WHERE name ILIKE '%$REGION_NAME%' LIMIT 1;" | tr -d ' \n')
    
    if [ -z "$REGION_ID" ]; then
      echo "Region not found: $REGION_NAME"
      exit 1
    fi
    
    echo "Found region ID: $REGION_ID"
    echo ""
    
    echo "📝 Turn 1 question (extracts noun from description):"
    $PSQL -c "SELECT game_logic.generate_question_text(NULL, '$REGION_ID'::uuid, 'en', '$DESCRIPTION', 1);"
    
    echo ""
    echo "📝 Turn 2+ question (uses 'it'):"
    $PSQL -c "SELECT game_logic.generate_question_text(NULL, '$REGION_ID'::uuid, 'en', '$DESCRIPTION', 2);"
    ;;
    
  "config")
    echo "⚙️  LLM Configuration:"
    echo ""
    $PSQL -c "SELECT key, 
      CASE 
        WHEN length(value::text) > 100 THEN left(value::text, 97) || '...'
        ELSE value::text
      END as value
    FROM game_logic.config 
    WHERE key LIKE 'llm.%' 
    ORDER BY key;"
    ;;
    
  "set-config")
    KEY="$2"
    VALUE="$3"
    echo "Setting $KEY = $VALUE"
    $PSQL -c "UPDATE game_logic.config SET value = '$VALUE'::jsonb WHERE key = '$KEY';"
    echo "✅ Done"
    ;;
    
  "places")
    echo "📍 Available places with trait counts:"
    $PSQL -c "
      SELECT p.name, COUNT(pt.trait_id) as traits
      FROM places p
      LEFT JOIN place_traits pt ON pt.place_id = p.id
      GROUP BY p.id, p.name
      ORDER BY p.name;
    "
    ;;
    
  *)
    echo "LLM Testing Script"
    echo ""
    echo "Commands:"
    echo "  ./scripts/test-llm.sh places                          List places with trait counts"
    echo "  ./scripts/test-llm.sh config                          Show LLM configuration"
    echo "  ./scripts/test-llm.sh set-config <key> <json-value>   Update config"
    echo "  ./scripts/test-llm.sh traits <place_name>             Test trait extraction"
    echo "  ./scripts/test-llm.sh question <trait> [description]  Test question generation"
    echo "  ./scripts/test-llm.sh region <region> [description]   Test region question"
    echo ""
    echo "Examples:"
    echo "  ./scripts/test-llm.sh traits 'Centennial Hall'"
    echo "  ./scripts/test-llm.sh question '330 meters' 'A famous iron tower'"
    echo "  ./scripts/test-llm.sh region 'Poland' 'A royal castle in Warsaw'"
    echo "  ./scripts/test-llm.sh set-config llm.question.model '\"mistralai/mistral-7b-instruct:free\"'"
    ;;
esac
