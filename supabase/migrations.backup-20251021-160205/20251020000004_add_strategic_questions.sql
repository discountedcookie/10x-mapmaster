-- Add more strategic questions for better semantic filtering
-- These questions are designed to leverage semantic similarity with enriched place descriptors

INSERT INTO questions (text, sequence, filter_type) VALUES
  ('Is it in Asia?', 6, 'asia'),
  ('Is it in North America?', 7, 'north_america'),
  ('Is it in South America?', 8, 'south_america'),
  ('Is it in Africa?', 9, 'africa'),
  ('Is it in Oceania?', 10, 'oceania'),
  ('Is it near an ocean or sea?', 11, 'ocean'),
  ('Is it near a river or lake?', 12, 'freshwater'),
  ('Is it very tall (over 200 meters)?', 13, 'tall'),
  ('Was it built in ancient times?', 14, 'ancient'),
  ('Was it built in medieval times?', 15, 'medieval'),
  ('Is it from the modern era (after 1800)?', 16, 'modern'),
  ('Is it a religious or spiritual site?', 17, 'religious'),
  ('Is it made primarily of stone?', 18, 'stone'),
  ('Is it made of metal or steel?', 19, 'metal'),
  ('Can you climb to the top of it?', 20, 'climbable');
