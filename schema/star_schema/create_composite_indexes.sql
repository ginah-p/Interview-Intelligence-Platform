-- Composite indexes for common query patterns

CREATE INDEX idx_fact_company_date ON fact_interview_events(company_key, date_key);
CREATE INDEX  idx_fact_date_result ON fact_interview_events(date_key, result);