/**
 * @deprecated This file is for documentation only.
 * Seed data is now managed in SQL migrations (supabase/migrations/000002_seed_data.sql)
 * Use the generate-questions-seed.ts script to generate embeddings for semantic questions.
 */
export const seedQuestions = [
  {
    text: 'Is it in Europe?',
    filter_type: 'europe',
  },
  {
    text: 'Is it a natural feature?',
    filter_type: 'natural',
  },
  {
    text: 'Is it in a major city?',
    filter_type: 'city',
  },
  {
    text: 'Is it a bridge or tower?',
    filter_type: 'structure',
  },
  {
    text: 'Is it in a capital city?',
    filter_type: 'capital',
  },
]
