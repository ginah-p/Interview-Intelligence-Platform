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
