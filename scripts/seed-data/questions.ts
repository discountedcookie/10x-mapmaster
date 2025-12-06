/**
 * Seed data for questions.
 * Used by generate-test-seed.ts to create SQL seed files with embeddings.
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
