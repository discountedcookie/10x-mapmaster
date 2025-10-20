# Supabase Edge Functions

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

No additional environment variables needed - the function uses Supabase's built-in AI.

### Deployment

Deploy the function to production:
```bash
npx supabase functions deploy generate-embedding
```

No secrets required - uses Supabase AI with gte-small model (built-in).

## Testing

Test the function locally:
```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/generate-embedding' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"text":"Eiffel Tower in Paris"}'
```

## Functions

### generate-embedding

Generates a 384-dimensional embedding vector from text using Supabase AI's gte-small model.

**Request:**
```json
{
  "text": "A huge, hot city of palaces and busy markets"
}
```

**Response:**
```json
{
  "embedding": [0.1, 0.2, ..., 0.384]
}
```

**Environment Variables:**
- `SUPABASE_URL`: Automatically provided by Supabase
- `SUPABASE_ANON_KEY`: Automatically provided by Supabase

**Model Details:**
- Model: gte-small (384 dimensions)
- Built into Supabase, no external API calls
- Options: mean_pool=true, normalize=true

