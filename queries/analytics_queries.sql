
-- ADVANCED ANALYTICS QUERIES
-- Interview Intelligence Platform


-- Query 1: Most Frequently Asked Topics (Basic Aggregation)
-- Shows: GROUP BY, COUNT, JOIN, ORDER BY
SELECT 
    t.topic_name,
    COUNT(f.event_key) as times_asked,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
JOIN dim_topics t ON q.topic_key = t.topic_key
WHERE t.topic_level = 2
GROUP BY t.topic_name
ORDER BY times_asked DESC
LIMIT 10;

-- Query 2: Company Performance Analysis (Multiple Aggregations)
-- Shows: DISTINCT, CASE, Multiple aggregations
SELECT 
    c.company_name,
    c.industry,
    COUNT(DISTINCT f.interview_round_id) as total_rounds,
    COUNT(f.event_key) as total_questions,
    SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) as rounds_passed,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate_pct,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty
FROM fact_interview_events f
JOIN dim_companies c ON f.company_key = c.company_key
GROUP BY c.company_name, c.industry
ORDER BY success_rate_pct DESC;

-- Query 3: Monthly Trend Analysis (Time-Series)
-- Shows: Time-based grouping, trend analysis
SELECT 
    dt.year,
    dt.month_name,
    COUNT(DISTINCT f.interview_round_id) as interviews_given,
    COUNT(f.event_key) as questions_attempted,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_time dt ON f.date_key = dt.date_key
GROUP BY dt.year, dt.month, dt.month_name
ORDER BY dt.year, dt.month;

-- Query 4: Hierarchical Topic Analysis (Self-Join)
-- Shows: Self-referential joins, hierarchical data
SELECT 
    parent.topic_name as category,
    child.topic_name as subcategory,
    COUNT(f.event_key) as times_asked,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty,
    SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) as passed,
    SUM(CASE WHEN f.result = 'failed' THEN 1 ELSE 0 END) as failed,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
JOIN dim_topics child ON q.topic_key = child.topic_key
LEFT JOIN dim_topics parent ON child.parent_topic_key = parent.topic_key
WHERE child.topic_level = 2
GROUP BY parent.topic_name, child.topic_name
ORDER BY category, times_asked DESC;

-- Query 5: Preparation Impact Analysis (Comparative Analysis)
-- Shows: Comparative metrics, CASE in GROUP BY
SELECT 
    CASE WHEN f.was_prepared THEN 'Prepared' ELSE 'Not Prepared' END as preparation_status,
    COUNT(f.event_key) as total_questions,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(AVG(f.difficulty_rating), 2) as avg_perceived_difficulty,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as success_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN f.needed_hint THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as hint_needed_pct
FROM fact_interview_events f
GROUP BY f.was_prepared;

-- Query 6: Interview Round Performance (Pipeline Analysis)
-- Shows: Understanding of interview funnel
SELECT 
    rt.round_type_name,
    rt.round_sequence,
    COUNT(DISTINCT f.interview_round_id) as times_faced,
    ROUND(AVG(f.duration_minutes), 0) as avg_duration_mins,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_round_types rt ON f.round_type_key = rt.round_type_key
GROUP BY rt.round_type_name, rt.round_sequence
ORDER BY rt.round_sequence;

-- Query 7: Difficulty vs Performance Correlation
-- Shows: Pattern analysis, correlation
SELECT 
    q.difficulty,
    COUNT(f.event_key) as questions_asked,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(AVG(f.duration_minutes), 0) as avg_time_taken,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as success_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN f.needed_hint THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as hint_needed_pct
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
GROUP BY q.difficulty
ORDER BY 
    CASE q.difficulty 
        WHEN 'Easy' THEN 1 
        WHEN 'Medium' THEN 2 
        WHEN 'Hard' THEN 3 
    END;

-- Query 8: Weekend vs Weekday Performance (Behavioral Pattern)
-- Shows: Date dimension usage, behavioral analysis
SELECT 
    CASE WHEN dt.is_weekend THEN 'Weekend' ELSE 'Weekday' END as day_type,
    COUNT(DISTINCT f.interview_round_id) as interviews_given,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_time dt ON f.date_key = dt.date_key
GROUP BY dt.is_weekend;

-- Query 9: Question Source Analysis (Data Quality Check)
-- Shows: Data profiling, source tracking
SELECT 
    q.source,
    COUNT(DISTINCT q.question_key) as unique_questions,
    COUNT(f.event_key) as times_appeared,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as success_rate_pct
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
GROUP BY q.source
ORDER BY times_appeared DESC;

-- Query 10: Company Topic Preferences (Pattern Recognition)
-- Shows: HAVING clause, pattern identification
SELECT 
    c.company_name,
    t.topic_name,
    COUNT(f.event_key) as times_asked,
    ROUND(AVG(f.difficulty_rating), 2) as avg_difficulty
FROM fact_interview_events f
JOIN dim_companies c ON f.company_key = c.company_key
JOIN dim_questions q ON f.question_key = q.question_key
JOIN dim_topics t ON q.topic_key = t.topic_key
WHERE t.topic_level = 2
GROUP BY c.company_name, t.topic_name
HAVING COUNT(f.event_key) >= 2
ORDER BY c.company_name, times_asked DESC;

-- Query 11: Rolling 7-Day Performance (Window Functions)
-- Shows: Window functions, moving averages
WITH daily_stats AS (
    SELECT 
        dt.full_date,
        COUNT(DISTINCT f.interview_round_id) as interviews,
        ROUND(AVG(f.answer_quality_rating), 2) as avg_quality,
        ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(*), 0), 2) as success_rate
    FROM fact_interview_events f
    JOIN dim_time dt ON f.date_key = dt.date_key
    GROUP BY dt.full_date
)
SELECT 
    full_date,
    interviews,
    avg_quality,
    success_rate,
    ROUND(AVG(avg_quality) OVER (
        ORDER BY full_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) as rolling_7day_quality,
    ROUND(AVG(success_rate) OVER (
        ORDER BY full_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) as rolling_7day_success_rate
FROM daily_stats
ORDER BY full_date DESC
LIMIT 30;

-- Query 12: Weak Topics Identification (Priority Scoring)
-- Shows: Complex scoring algorithm, actionable insights
SELECT 
    t.topic_name,
    COUNT(f.event_key) as times_attempted,
    ROUND(AVG(f.answer_quality_rating), 2) as avg_answer_quality,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as success_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN f.needed_hint THEN 1 ELSE 0 END) / 
          COUNT(*), 2) as hint_rate_pct,
    -- Priority score: lower is worse (needs more practice)
    ROUND(
        (AVG(f.answer_quality_rating) * 0.4) + 
        ((SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) * 0.006) -
        ((SUM(CASE WHEN f.needed_hint THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) * 0.004),
    2) as priority_score
FROM fact_interview_events f
JOIN dim_questions q ON f.question_key = q.question_key
JOIN dim_topics t ON q.topic_key = t.topic_key
WHERE t.topic_level = 2
GROUP BY t.topic_name
HAVING COUNT(f.event_key) >= 2
ORDER BY priority_score ASC
LIMIT 5;




-- Query 13: Top Performers by Quarter (Ranking with RANK)
-- Shows: RANK() window function, partitioning
SELECT 
    quarter,
    year,
    company_name,
    total_interviews,
    success_rate,
    quarter_rank
FROM (
    SELECT 
        dt.quarter,
        dt.year,
        c.company_name,
        COUNT(DISTINCT f.interview_round_id) as total_interviews,
        ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
              NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate,
        RANK() OVER (
            PARTITION BY dt.quarter, dt.year 
            ORDER BY COUNT(DISTINCT f.interview_round_id) DESC
        ) as quarter_rank
    FROM fact_interview_events f
    JOIN dim_companies c ON f.company_key = c.company_key
    JOIN dim_time dt ON f.date_key = dt.date_key
    GROUP BY dt.quarter, dt.year, c.company_name
) ranked
WHERE quarter_rank <= 3
ORDER BY year, quarter, quarter_rank;

-- Query 14: Questions Asked Together (Market Basket Analysis)
-- Shows: Self-join, pattern discovery
SELECT 
    q1.question_text as question_1,
    q2.question_text as question_2,
    COUNT(*) as times_together
FROM fact_interview_events f1
JOIN fact_interview_events f2 ON f1.interview_round_id = f2.interview_round_id
    AND f1.question_key < f2.question_key
JOIN dim_questions q1 ON f1.question_key = q1.question_key
JOIN dim_questions q2 ON f2.question_key = q2.question_key
GROUP BY q1.question_text, q2.question_text
HAVING COUNT(*) >= 2
ORDER BY times_together DESC
LIMIT 10;

-- Query 15: Performance Improvement Over Time (LAG function)
-- Shows: LAG window function, trend detection
WITH monthly_performance AS (
    SELECT 
        dt.year,
        dt.month,
        dt.month_name,
        ROUND(AVG(f.answer_quality_rating), 2) as avg_quality,
        ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
              COUNT(*), 2) as success_rate
    FROM fact_interview_events f
    JOIN dim_time dt ON f.date_key = dt.date_key
    GROUP BY dt.year, dt.month, dt.month_name
)
SELECT 
    year,
    month_name,
    avg_quality,
    success_rate,
    LAG(avg_quality) OVER (ORDER BY year, month) as prev_month_quality,
    ROUND(avg_quality - LAG(avg_quality) OVER (ORDER BY year, month), 2) as quality_improvement,
    LAG(success_rate) OVER (ORDER BY year, month) as prev_month_success_rate,
    ROUND(success_rate - LAG(success_rate) OVER (ORDER BY year, month), 2) as success_rate_improvement
FROM monthly_performance
ORDER BY year, month;
