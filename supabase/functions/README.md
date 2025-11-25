# Supabase Edge Functions

## Overview

This directory contains Supabase Edge Functions for the 10x-Mapmaster application.

## Functions

### search-place

A proxy function for searching places using the Nominatim API (OpenStreetMap).

**Purpose**: Provides geographic place search functionality while maintaining proper user agent attribution and authentication.

**Endpoint**: `GET /functions/v1/search-place`

**Authentication**: Required (Bearer token)

**Parameters**:

- `q` (query string): Search query for place names

**Request Example**:

```bash
curl -X GET 'http://127.0.0.1:54321/functions/v1/search-place?q=Eiffel%20Tower' \
  --header 'Authorization: Bearer YOUR_ANON_KEY'
```

**Response Example**:

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
- `401`: Missing or invalid authorization
- `405`: Method not allowed (only GET supported)
- `500`: Server error or Nominatim API failure

## Setup

### Local Development

1. Install Deno (if not already installed):

```bash
curl -fsSL https://deno.land/x/install/install.sh | sh
```

2. Start Supabase with functions:

```bash
npx supabase start
npx supabase functions serve
```

### Deployment

Deploy the function to production:

```bash
npx supabase functions deploy search-place
```

## Development Notes

- The function includes inline helper functions (previously shared across multiple functions)
- Uses proper User-Agent header for Nominatim API compliance
- Requires authentication for all requests
- Returns structured JSON responses with consistent error handling
