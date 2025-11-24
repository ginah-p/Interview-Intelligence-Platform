-- Dimension indexes
CREATE INDEX idx_companies_name ON dim_companies(company_name);
CREATE INDEX idx_companies_industry ON dim_companies(industry);
CREATE INDEX idx_time_full_date ON dim_time(full_date);
CREATE INDEX idx_time_year_month ON dim_time(year, month);
CREATE INDEX idx_topics_parent ON dim_topics(parent_topic_key);
CREATE INDEX idx_topics_level ON dim_topics(topic_level);
CREATE INDEX idx_questions_topic ON dim_questions(topic_key);
CREATE INDEX idx_questions_difficulty ON dim_questions(difficulty);
