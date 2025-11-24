-- Dimension: Round Types
CREATE TABLE dim_round_types (
    round_type_key SERIAL PRIMARY KEY,
    round_type_id VARCHAR(50) UNIQUE NOT NULL,
    round_type_name VARCHAR(100) NOT NULL,
    round_sequence INTEGER,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);