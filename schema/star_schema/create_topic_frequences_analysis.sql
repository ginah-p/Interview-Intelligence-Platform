CREATE OR REPLACE VIEW vw_topic_frequency AS
SELECT 
    t.topic_name,
    t.topic_level,
    COUNT(f.event_key) as times_asked,
    AVG(f.difficulty_rating) as avg_difficulty,
    AVG(f.answer_quality_rating) as avg_answer_quality,
    SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) as times_passed,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(f.event_key), 0), 2) as success_rate
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
JOIN dim_topics t ON q.topic_key = t.topic_key
GROUP BY t.topic_name, t.topic_level
ORDER BY times_asked DESC;