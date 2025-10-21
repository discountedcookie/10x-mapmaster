-- ============================================================================
-- Seed Data: Places and Questions
-- ============================================================================
-- Initial seed data for testing and gameplay
-- Embeddings will be added in the next migration

-- ============================================================================
-- SEED PLACES (20 famous landmarks)
-- ============================================================================

INSERT INTO places (name, lat, lng, descriptors) VALUES
  ('Eiffel Tower', 48.8584, 2.2945, '{"country_code":"fr","type":"tower","class":"tourism","address":{"city":"Paris","country":"France"},"continent":"europe"}'::jsonb),
  ('Big Ben', 51.5007, -0.1246, '{"country_code":"gb","type":"tower","class":"tourism","address":{"city":"London","country":"United Kingdom"},"continent":"europe","is_capital_city":true}'::jsonb),
  ('Tower Bridge', 51.5055, -0.0754, '{"country_code":"gb","type":"bridge","class":"tourism","address":{"city":"London","country":"United Kingdom"},"continent":"europe","is_capital_city":true}'::jsonb),
  ('Colosseum', 41.8902, 12.4922, '{"country_code":"it","type":"monument","class":"tourism","address":{"city":"Rome","country":"Italy"},"continent":"europe","is_capital_city":true}'::jsonb),
  ('Sagrada Familia', 41.4036, 2.1744, '{"country_code":"es","type":"place_of_worship","class":"tourism","address":{"city":"Barcelona","country":"Spain"},"continent":"europe"}'::jsonb),
  ('Brandenburg Gate', 52.5163, 13.3777, '{"country_code":"de","type":"monument","class":"tourism","address":{"city":"Berlin","country":"Germany"},"continent":"europe","is_capital_city":true}'::jsonb),
  ('Acropolis', 37.9715, 23.7267, '{"country_code":"gr","type":"monument","class":"tourism","address":{"city":"Athens","country":"Greece"},"continent":"europe","is_capital_city":true}'::jsonb),
  ('Mount Everest', 27.9881, 86.9250, '{"country_code":"np","type":"peak","class":"natural","address":{"country":"Nepal"},"continent":"asia"}'::jsonb),
  ('Lake Geneva', 46.4534, 6.5615, '{"country_code":"ch","type":"lake","class":"natural","address":{"country":"Switzerland"},"continent":"europe"}'::jsonb),
  ('Mount Fuji', 35.3606, 138.7274, '{"country_code":"jp","type":"peak","class":"natural","address":{"country":"Japan"},"continent":"asia"}'::jsonb),
  ('Grand Canyon', 36.1069, -112.1129, '{"country_code":"us","type":"canyon","class":"natural","address":{"state":"Arizona","country":"United States"},"continent":"north_america"}'::jsonb),
  ('Niagara Falls', 43.0828, -79.0763, '{"country_code":"ca","type":"waterfall","class":"natural","address":{"country":"Canada"},"continent":"north_america"}'::jsonb),
  ('Statue of Liberty', 40.6892, -74.0445, '{"country_code":"us","type":"monument","class":"tourism","address":{"city":"New York","country":"United States"},"continent":"north_america"}'::jsonb),
  ('Sydney Opera House', -33.8568, 151.2153, '{"country_code":"au","type":"theatre","class":"tourism","address":{"city":"Sydney","country":"Australia"},"continent":"oceania"}'::jsonb),
  ('Taj Mahal', 27.1751, 78.0421, '{"country_code":"in","type":"monument","class":"tourism","address":{"city":"Agra","country":"India"},"continent":"asia"}'::jsonb),
  ('Great Wall of China', 40.4319, 116.5704, '{"country_code":"cn","type":"monument","class":"tourism","address":{"country":"China"},"continent":"asia"}'::jsonb),
  ('Machu Picchu', -13.1631, -72.5450, '{"country_code":"pe","type":"monument","class":"tourism","address":{"country":"Peru"},"continent":"south_america"}'::jsonb),
  ('Christ the Redeemer', -22.9519, -43.2105, '{"country_code":"br","type":"monument","class":"tourism","address":{"city":"Rio de Janeiro","country":"Brazil"},"continent":"south_america"}'::jsonb),
  ('Burj Khalifa', 25.1972, 55.2744, '{"country_code":"ae","type":"tower","class":"tourism","address":{"city":"Dubai","country":"United Arab Emirates"},"continent":"asia"}'::jsonb),
  ('Pyramids of Giza', 29.9792, 31.1342, '{"country_code":"eg","type":"monument","class":"tourism","address":{"city":"Cairo","country":"Egypt"},"continent":"africa","is_capital_city":true}'::jsonb);

-- ============================================================================
-- SEED QUESTIONS (20 strategic questions)
-- ============================================================================

INSERT INTO questions (text, sequence, filter_type) VALUES
  -- Continental questions
  ('Is it in Europe?', 1, 'europe'),
  ('Is it in Asia?', 2, 'asia'),
  ('Is it in North America?', 3, 'north_america'),
  ('Is it in South America?', 4, 'south_america'),
  ('Is it in Africa?', 5, 'africa'),
  ('Is it in Oceania?', 6, 'oceania'),

  -- Feature type questions
  ('Is it a natural feature?', 7, 'natural'),
  ('Is it in a major city?', 8, 'city'),
  ('Is it in a capital city?', 9, 'capital'),
  ('Is it a bridge or tower?', 10, 'structure'),

  -- Geographic features
  ('Is it near an ocean or sea?', 11, 'ocean'),
  ('Is it near a river or lake?', 12, 'freshwater'),
  ('Is it very tall (over 200 meters)?', 13, 'tall'),

  -- Historical period
  ('Was it built in ancient times?', 14, 'ancient'),
  ('Was it built in medieval times?', 15, 'medieval'),
  ('Is it from the modern era (after 1800)?', 16, 'modern'),

  -- Characteristics
  ('Is it a religious or spiritual site?', 17, 'religious'),
  ('Is it made primarily of stone?', 18, 'stone'),
  ('Is it made of metal or steel?', 19, 'metal'),
  ('Can you climb to the top of it?', 20, 'climbable');

-- Add continent field to places (will help with filtering)
-- Note: Some places manually set in INSERT statements above
