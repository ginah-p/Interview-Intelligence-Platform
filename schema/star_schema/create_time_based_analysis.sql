-- Time based trend analysis

CREATE OR REPLACE VIEW vw_monthly_interview_trends AS
SELECT
    dt.year,
    dt.month,
    dt.month_name,
    COUNT(DISTINCT f.interview_round_id) as total_interviews,
    COUNT(f.event_key) as total_questions_asked,
    AVG(f.difficulty_rating) as average_difficulty_rating,
    SUM(CASE WHEN f.result = 'passed ' THEN 1 ELSE 0 END) as passed_rounds,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END)/
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate
    FROM fact_interview_events f
    JOIN dim_time dt ON f.date_key = dt.date_key
    GROUP BY dt.year, dt.month, dt.month_name
    ORDER BY dt.year, dt.month;
