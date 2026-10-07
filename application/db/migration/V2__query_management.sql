ALTER TABLE queries ADD COLUMN id BIGINT GENERATED ALWAYS AS IDENTITY;
CREATE UNIQUE INDEX idx_queries_id ON queries(id);

-- Small, explicit demonstration dataset; no historical performance data is imported.
INSERT INTO queries(query, all_time_count, recent_score) VALUES
  ('kubernetes deployment', 30, 3),
  ('kubernetes service', 20, 2),
  ('terraform state', 15, 1),
  ('docker compose', 12, 1),
  ('git pull request', 10, 1);
