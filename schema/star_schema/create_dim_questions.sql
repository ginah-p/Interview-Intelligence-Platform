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