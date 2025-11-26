# Supabase Edge Functions

## Overview

This directory contains Supabase Edge Functions for the 10x-Mapmaster application. All functions use Deno runtime and follow consistent patterns for error handling and logging.

## Environment Variables

### Required for Local Development

- `OLLAMA_HOST`: Ollama server URL (default: `http://host.docker.internal:11434`)

### Required for Production

- `OLLAMA_HOST`: Ollama server URL (must be configured in Supabase dashboard)

## Functions

### 1. generate-embedding

Generates text embeddings using Ollama's `mxbai-embed-large` model.

**Purpose**: Convert text into 1024-dimensional vectors for semantic similarity.

**Endpoint**: `POST /functions/v1/generate-embedding`

**Authentication**: None (public function)

**Request Body**:

```json
{
  "text": "Eiffel Tower in Paris"
}
```

**Response**:

```json
{
  "embedding": [0.1234, -0.5678, ...] // 1024 dimensions
}
```

**Error Responses**:

- `400`: Missing or invalid text field
- `405`: Method not allowed (only POST supported)
- `500`: Ollama API error or embedding generation failure

**Example**:

```bash
curl -X POST 'http://127.0.0.1:54321/functions/v1/generate-embedding' \
  --header 'Content-Type: application/json' \
  --data '{"text": "Eiffel Tower"}'
```

### 2. call-llm

Calls Large Language Model via Ollama for text generation.

**Purpose**: Generate questions, analyze places, and provide AI responses.

**Endpoint**: `POST /functions/v1/call-llm`

**Authentication**: None (public function)

**Request Body**:

```json
{
  "prompt": "Generate a geographic question about Paris",
  "model": "llama3.2",
  "format": "json", // optional
  "options": {
    // optional
    "temperature": 0.7,
    "max_tokens": 500
  }
}
```

**Response**:

```json
{
  "response": "What famous iron tower is located in Paris, France?"
}
```

**Error Responses**:

- `400`: Missing or invalid prompt field
- `405`: Method not allowed (only POST supported)
- `500`: Ollama API error or LLM generation failure

**Example**:

```bash
curl -X POST 'http://127.0.0.1:54321/functions/v1/call-llm' \
  --header 'Content-Type: application/json' \
  --data '{"prompt": "What is the capital of France?", "model": "llama3.2"}'
```

### 3. place-enrichment

Enriches place data using Nominatim API with trait extraction.

**Purpose**: Get detailed place information and extract game-relevant traits.

**Endpoint**: `POST /functions/v1/place-enrichment`

**Authentication**: None (public function)

**Request Body**:

```json
{
  "query": "Eiffel Tower", // or "name"
  "language": "en", // optional, default: "en"
  "limit": 1 // optional, default: 1
}
```

**Response**:

```json
{
  "place": {
    "lat": 48.8584,
    "lng": 2.2945,
    "display_name": "Tour Eiffel, Paris, France",
    "english_name": "Eiffel Tower",
    "type": "tourism",
    "class": "tourism",
    "boundingbox": ["48.8583", "48.8585", "2.2944", "2.2946"],
    "address": { "country": "France", "city": "Paris" },
    "extratags": { "height": "330", "building": "tower" },
    "osm_type": "way",
    "osm_id": 1570375
  },
  "traits": [
    {
      "id": "height:over_300m",
      "category": "height",
      "clause": "Over 300m tall",
      "sourceKey": "height",
      "value": "330",
      "metadata": { "meters": 330 }
    }
  ]
}
```

**Error Responses**:

- `400`: Missing query/name field or invalid JSON
- `404`: No results found
- `405`: Method not allowed (only POST supported)
- `502`: Nominatim API error
- `500`: Server error

**Example**:

```bash
curl -X POST 'http://127.0.0.1:54321/functions/v1/place-enrichment' \
  --header 'Content-Type: application/json' \
  --data '{"query": "Eiffel Tower"}'
```

### 4. search-place

Searches for places using Nominatim API.

**Purpose**: Simple place search for frontend autocomplete and selection.

**Endpoint**: `GET /functions/v1/search-place`

**Authentication**: None (public function)

**Parameters**:

- `q` (query string): Search query for place names

**Response**:

```json
{
  "query": "Eiffel Tower",
  "results": [
    {
      "name": "Tour Eiffel, 5, Avenue Anatole France, Quartier du Gros-Caillou, 7e Arrondissement, Paris, Île-de-France, France métropolitaine, 75007, France",
      "lat": 48.858370099999996,
      "lng": 2.2944813,
      "osm_id": 1570375,
      "type": "tourism"
    }
  ]
}
```

**Error Responses**:

- `400`: Missing or invalid query parameter
- `405`: Method not allowed (only GET supported)
- `500`: Server error or Nominatim API failure

**Example**:

```bash
curl -X GET 'http://127.0.0.1:54321/functions/v1/search-place?q=Eiffel%20Tower'
```

## Setup

### Local Development

1. **Install Deno** (if not already installed):

```bash
curl -fsSL https://deno.land/x/install/install.sh | sh
```

2. **Start Ollama** (required for embedding and LLM functions):

```bash
# Pull required models
ollama pull mxbai-embed-large
ollama pull llama3.2

# Start Ollama server
ollama serve
```

3. **Start Supabase** with functions:

```bash
# Start Supabase (exclude built-in vector extension)
supabase start -x vector

# Serve functions locally
supabase functions serve
```

4. **Test Functions**:

```bash
# Test embedding generation
curl -X POST 'http://127.0.0.1:54321/functions/v1/generate-embedding' \
  --header 'Content-Type: application/json' \
  --data '{"text": "test"}'

# Test LLM call
curl -X POST 'http://127.0.0.1:54321/functions/v1/call-llm' \
  --header 'Content-Type: application/json' \
  --data '{"prompt": "Hello", "model": "llama3.2"}'
```

### Production Deployment

1. **Configure Environment Variables** in Supabase Dashboard:
   - Go to Project Settings → Edge Functions
   - Add `OLLAMA_HOST` with your Ollama server URL

2. **Deploy Functions**:

```bash
# Deploy all functions
supabase functions deploy

# Deploy specific function
supabase functions deploy generate-embedding
supabase functions deploy call-llm
supabase functions deploy place-enrichment
supabase functions deploy search-place
```

## Development Notes

### Code Patterns

- All functions use consistent `Deno.serve()` pattern
- Unified error handling with proper HTTP status codes
- Comprehensive logging with ✓/✗ prefixes for easy debugging
- JSON responses with consistent structure
- Input validation with descriptive error messages

### Shared Utilities

- `_shared/enrichment.ts`: Place enrichment and Nominatim integration
- `_shared/traits.ts`: Trait extraction and categorization logic
- `types/nominatim-ts.d.ts`: Type definitions for Nominatim API

### Testing

- Functions can be tested locally using curl or Postman
- All endpoints return structured error responses for debugging
- Console logging provides detailed execution traces

### Dependencies

- `ollama@0.5.9`: For embedding and LLM generation
- `nominatim-ts`: For OpenStreetMap data integration
- `jsr:@supabase/functions-js`: Edge runtime types

### Rate Limiting & Usage

- Nominatim API has usage limits - consider caching results
- Ollama performance depends on model size and hardware
- Functions are stateless - each request is independent
