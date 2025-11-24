-- Drop tables if they exist (in reverse order due to foreign keys)
DROP TABLE IF EXISTS fact_interview_events CASCADE;
DROP TABLE IF EXISTS dim_questions CASCADE;
DROP TABLE IF EXISTS dim_round_types CASCADE;
DROP TABLE IF EXISTS dim_topics CASCADE;
DROP TABLE IF EXISTS dim_time CASCADE;
DROP TABLE IF EXISTS dim_companies CASCADE;