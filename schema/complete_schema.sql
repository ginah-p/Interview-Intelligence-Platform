-- ============================================
-- COMPLETE WORKING SCHEMA FOR INTERVIEW ANALYTICS
-- Drop and recreate all tables in correct order
-- ============================================

-- Drop tables if they exist (in reverse order due to foreign keys)
DROP TABLE IF EXISTS fact_interview_events CASCADE;
DROP TABLE IF EXISTS dim_questions CASCADE;
DROP TABLE IF EXISTS dim_round_types CASCADE;
DROP TABLE IF EXISTS dim_topics CASCADE;
DROP TABLE IF EXISTS dim_time CASCADE;
DROP TABLE IF EXISTS dim_companies CASCADE;

-- ============================================
-- DIMENSION TABLES
-- ============================================

-- Dimension: Companies
CREATE TABLE dim_companies (
    company_key SERIAL PRIMARY KEY,
    company_id VARCHAR(50) UNIQUE NOT NULL,
    company_name VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    company_size VARCHAR(50),
    location VARCHAR(100),
    is_product_based BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Time
CREATE TABLE dim_time (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_of_week INTEGER,
    day_name VARCHAR(10),
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month INTEGER,
    month_name VARCHAR(10),
    quarter INTEGER,
    year INTEGER,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN DEFAULT FALSE
);

-- Dimension: Topics (Hierarchical)
CREATE TABLE dim_topics (
    topic_key SERIAL PRIMARY KEY,
    topic_id VARCHAR(50) UNIQUE NOT NULL,
    topic_name VARCHAR(100) NOT NULL,
    parent_topic_key INTEGER,
    topic_level INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_topic_key) REFERENCES dim_topics(topic_key)
);

-- Dimension: Round Types
CREATE TABLE dim_round_types (
    round_type_key SERIAL PRIMARY KEY,
    round_type_id VARCHAR(50) UNIQUE NOT NULL,
    round_type_name VARCHAR(100) NOT NULL,
    round_sequence INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- Dimension: Questions
CREATE TABLE dim_questions (
    question_key SERIAL PRIMARY KEY,
    question_id VARCHAR(100) UNIQUE NOT NULL,
    question_text TEXT NOT NULL,
    topic_key INTEGER NOT NULL,
    difficulty VARCHAR(20),
    source VARCHAR(50),
    source_url TEXT,
    frequency_asked INTEGER DEFAULT 1,
    avg_difficulty_rating DECIMAL(3,2),
    is_current BOOLEAN DEFAULT TRUE,
    effective_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_key) REFERENCES dim_topics(topic_key)
);

-- ============================================
-- FACT TABLE
-- ============================================

CREATE TABLE fact_interview_events (
    event_key SERIAL PRIMARY KEY,
    company_key INTEGER NOT NULL,
    date_key INTEGER NOT NULL,
    round_type_key INTEGER NOT NULL,
    question_key INTEGER NOT NULL,
    interview_round_id VARCHAR(100),
    duration_minutes INTEGER,
    result VARCHAR(20),
    difficulty_rating INTEGER CHECK (difficulty_rating BETWEEN 1 AND 5),
    answer_quality_rating INTEGER CHECK (answer_quality_rating BETWEEN 1 AND 5),
    preparation_time_hours DECIMAL(5,2),
    was_prepared BOOLEAN DEFAULT FALSE,
    needed_hint BOOLEAN DEFAULT FALSE,
    completed_in_time BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_key) REFERENCES dim_companies(company_key),
    FOREIGN KEY (date_key) REFERENCES dim_time(date_key),
    FOREIGN KEY (round_type_key) REFERENCES dim_round_types(round_type_key),
    FOREIGN KEY (question_key) REFERENCES dim_questions(question_key)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Dimension indexes
CREATE INDEX idx_companies_name ON dim_companies(company_name);
CREATE INDEX idx_companies_industry ON dim_companies(industry);
CREATE INDEX idx_time_full_date ON dim_time(full_date);
CREATE INDEX idx_time_year_month ON dim_time(year, month);
CREATE INDEX idx_topics_parent ON dim_topics(parent_topic_key);
CREATE INDEX idx_topics_level ON dim_topics(topic_level);
CREATE INDEX idx_questions_topic ON dim_questions(topic_key);
CREATE INDEX idx_questions_difficulty ON dim_questions(difficulty);

-- Fact table indexes
CREATE INDEX idx_fact_company ON fact_interview_events(company_key);
CREATE INDEX idx_fact_date ON fact_interview_events(date_key);
CREATE INDEX idx_fact_round_type ON fact_interview_events(round_type_key);
CREATE INDEX idx_fact_question ON fact_interview_events(question_key);
CREATE INDEX idx_fact_result ON fact_interview_events(result);
CREATE INDEX idx_fact_round_id ON fact_interview_events(interview_round_id);
CREATE INDEX idx_fact_company_date ON fact_interview_events(company_key, date_key);
CREATE INDEX idx_fact_date_result ON fact_interview_events(date_key, result);

-- ============================================
-- VIEWS FOR ANALYTICS
-- ============================================

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

CREATE OR REPLACE VIEW vw_monthly_interview_trends AS
SELECT 
    dt.year,
    dt.month,
    dt.month_name,
    COUNT(DISTINCT f.interview_round_id) as total_interviews,
    COUNT(f.event_key) as total_questions,
    AVG(f.difficulty_rating) as avg_difficulty,
    SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) as passed_rounds,
    ROUND(100.0 * SUM(CASE WHEN f.result = 'passed' THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(DISTINCT f.interview_round_id), 0), 2) as success_rate
FROM fact_interview_events f
JOIN dim_time dt ON f.date_key = dt.date_key
GROUP BY dt.year, dt.month, dt.month_name
ORDER BY dt.year, dt.month;
