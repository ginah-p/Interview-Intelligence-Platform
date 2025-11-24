CREATE OR REPLACE VIEW vw_company_interview_summary AS
SELECT 
    c.company_name,
    c.industry,
    COUNT(DISTINCT f.interview_round_id) as total_rounds,
    COUNT(f.event_key) as total_questions_asked,
    AVG(f.difficulty_rating) as avg_difficulty,
    SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) as rounds_passed,
    SUM(CASE WHEN f.result = 'failed' THEN 1 ELSE 0 END) as rounds_failed,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate
FROM fact_interview_events f
JOIN dim_companies c ON f.company_key = c.company_key
GROUP BY c.company_name, c.industry;