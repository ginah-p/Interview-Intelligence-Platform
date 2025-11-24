"""
Seed data population scripts for Interview Analytics Data Warehouse
Populates dimension and fact tables with sample data 
"""

import psycopg2
from datetime import datetime, timedelta
import random

# Database connection parameter
DB_CONFIG = {
    'dbname': 'interview_analytics',
    'user': 'postgres',  
    'password': 'postgres123',  
    'host': 'localhost',
    'port': 5432  
}

def get_connection():
    """Create database connection"""
    return psycopg2.connect(**DB_CONFIG)
'postgres123'
def populate_dim_time(conn, start_date, end_date):
    """
    Populate time dimension with date range
    This is crucial for time-based analytics
    """
    cursor = conn.cursor()
    
    current_date = start_date
    
    while current_date <= end_date:
        date_key = int(current_date.strftime('%Y%m%d'))
        day_of_week = current_date.isoweekday()
        day_name = current_date.strftime('%A')
        is_weekend = day_of_week in [6, 7]  # Fixed: was day_of_the_week[6,7]
        
        cursor.execute("""
            INSERT INTO dim_time (
                date_key, full_date, day_of_week, day_name, 
                day_of_month, day_of_year, week_of_year,
                month, month_name, quarter, year, is_weekend
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (full_date) DO NOTHING
        """, (
            date_key,
            current_date,
            day_of_week,
            day_name,
            current_date.day,
            current_date.timetuple().tm_yday,
            current_date.isocalendar()[1],
            current_date.month,
            current_date.strftime('%B'),
            (current_date.month - 1) // 3 + 1,
            current_date.year,
            is_weekend
        ))
        
        current_date += timedelta(days=1)
        
    conn.commit()
    print(f"✓ Populated dim_time from {start_date} to {end_date}")

# Fixed: This function is now at the correct indentation level
def populate_dim_companies(conn):
    """Populate companies dimensions with sample data"""
    cursor = conn.cursor()
    
    companies = [
        ('GOOG', 'Google', 'Technology', 'Enterprise', 'Bangalore', True),
        ('MSFT', 'Microsoft', 'Technology', 'Enterprise', 'Hyderabad', True),
        ('AMZN', 'Amazon', 'E-commerce', 'Enterprise', 'Bangalore', True),
        ('FLIP', 'Flipkart', 'E-commerce', 'Large', 'Bangalore', True),
        ('PAYT', 'PayTM', 'Fintech', 'Large', 'Noida', True),
        ('ZETA', 'Zeta', 'Fintech', 'Medium', 'Bangalore', True),
        ('SURL', 'Swiggy', 'Food Tech', 'Large', 'Bangalore', True),
        ('UBER', 'Uber', 'Transportation', 'Enterprise', 'Bangalore', True),
        ('TCS', 'TCS', 'IT Services', 'Enterprise', 'Multiple', False),
        ('INFO', 'Infosys', 'IT Services', 'Enterprise', 'Bangalore', False),
    ]
    
    for company in companies:
        cursor.execute("""
            INSERT INTO dim_companies (
                company_id, company_name, industry,
                company_size, location, is_product_based
            ) VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (company_id) DO NOTHING
        """, company)
    
    conn.commit()
    print(f'✓ Populated dim_companies with {len(companies)} companies')

def populate_dim_topics(conn):
    """Populate topics dimension with hierarchical structure"""
    cursor = conn.cursor()
    
    # Level 1: main categories
    categories = [
        ('DSA', 'Data Structures & Algorithms', None, 1),
        ('DBMS', 'Database Management Systems', None, 1),
        ('OS', 'Operating Systems', None, 1),
        ('NET', 'Computer Networks', None, 1),
        ('OOP', 'Object Oriented Programming', None, 1),
        ('SYS', 'System Design', None, 1),
    ]
    
    for topic in categories:
        cursor.execute("""
            INSERT INTO dim_topics (topic_id, topic_name, parent_topic_key, topic_level)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (topic_id) DO NOTHING
            RETURNING topic_key
        """, topic)
    
    conn.commit()
    
    # Level 2: subcategories (DSA breakdown)
    cursor.execute("SELECT topic_key FROM dim_topics WHERE topic_id = 'DSA'")  # Fixed: missing closing quote
    dsa_key = cursor.fetchone()[0]
    
    dsa_subcategories = [
        ('DSA-ARR', 'Arrays', dsa_key, 2),
        ('DSA-STR', 'Strings', dsa_key, 2),
        ('DSA-LL', 'Linked Lists', dsa_key, 2),
        ('DSA-TREE', 'Trees', dsa_key, 2),
        ('DSA-GRAPH', 'Graphs', dsa_key, 2),
        ('DSA-DP', 'Dynamic Programming', dsa_key, 2),
        ('DSA-GREEDY', 'Greedy Algorithms', dsa_key, 2),
        ('DSA-BS', 'Binary Search', dsa_key, 2),
    ]
    
    for topic in dsa_subcategories:
        cursor.execute("""
            INSERT INTO dim_topics (topic_id, topic_name, parent_topic_key, topic_level)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (topic_id) DO NOTHING
        """, topic)
    
    # Level 2: DBMS subcategories
    cursor.execute("SELECT topic_key FROM dim_topics WHERE topic_id = 'DBMS'")
    dbms_key = cursor.fetchone()[0]
    
    dbms_subcategories = [
        ('DBMS-SQL', 'SQL Queries', dbms_key, 2),  # Fixed: was 'SQl'
        ('DBMS-NORM', 'Normalization', dbms_key, 2),
        ('DBMS-INDEX', 'Indexing', dbms_key, 2),
        ('DBMS-TRANS', 'Transactions', dbms_key, 2),
    ]
    
    for topic in dbms_subcategories:
        cursor.execute("""
            INSERT INTO dim_topics (topic_id, topic_name, parent_topic_key, topic_level)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (topic_id) DO NOTHING
        """, topic)
    
    conn.commit()
    print('✓ Populated dim_topics with hierarchical structure')

def populate_dim_round_types(conn):
    """Populate round type dimensions"""
    cursor = conn.cursor()
    
    round_types = [
        ('OA', 'Online Assessment', 1, 'Initial coding test'),
        ('TECH1', 'Technical Round 1', 2, 'First technical interview'),
        ('TECH2', 'Technical Round 2', 3, 'Second technical interview'),
        ('TECH3', 'Technical Round 3', 4, 'Third technical interview (if any)'),
        ('MGR', 'Managerial Round', 5, 'Interview with hiring manager'),
        ('HR', 'HR Round', 6, 'Final HR discussion'),
    ]
    
    for rt in round_types:
        cursor.execute("""
            INSERT INTO dim_round_types (
                round_type_id, round_type_name,
                round_sequence, description
            ) VALUES (%s, %s, %s, %s)
            ON CONFLICT (round_type_id) DO NOTHING
        """, rt)
    
    conn.commit()
    print(f'✓ Populated dim_round_types with {len(round_types)} round types')

# Fixed: This function is now at the correct indentation level
def populate_dim_questions(conn):
    """Populate questions dimension with sample questions"""
    cursor = conn.cursor()
    
    # Get topic keys
    cursor.execute("SELECT topic_key, topic_id FROM dim_topics WHERE topic_level = 2")  # Fixed: was 'topic level'
    topic_map = {row[1]: row[0] for row in cursor.fetchall()}
    
    questions = [
        ('Q001', 'Find two numbers that add up to target', topic_map['DSA-ARR'], 'Easy', 'LeetCode'),
        ('Q002', 'Reverse a linked list', topic_map['DSA-LL'], 'Easy', 'LeetCode'),
        ('Q003', 'Lowest Common Ancestor in BST', topic_map['DSA-TREE'], 'Medium', 'LeetCode'),
        ('Q004', 'Implement LRU Cache', topic_map['DSA-ARR'], 'Hard', 'LeetCode'),
        ('Q005', 'Longest Common Subsequence', topic_map['DSA-DP'], 'Medium', 'LeetCode'),
        ('Q006', 'Detect cycle in directed graph', topic_map['DSA-GRAPH'], 'Medium', 'Manual'),
        ('Q007', 'Maximum subarray sum', topic_map['DSA-ARR'], 'Medium', 'LeetCode'),
        ('Q008', 'Valid Parentheses', topic_map['DSA-STR'], 'Easy', 'LeetCode'),
        ('Q009', 'Merge K sorted lists', topic_map['DSA-LL'], 'Hard', 'LeetCode'),
        ('Q010', 'Write SQL join query', topic_map['DBMS-SQL'], 'Medium', 'Manual'),
        ('Q011', 'Explain 3NF with example', topic_map['DBMS-NORM'], 'Medium', 'Manual'),
        ('Q012', 'When to use indexing?', topic_map['DBMS-INDEX'], 'Medium', 'Manual'),  
    ]
    
    for q in questions:
        cursor.execute("""
            INSERT INTO dim_questions (
                question_id, question_text, topic_key,
                difficulty, source
            ) VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (question_id) DO NOTHING
        """, q)
    
    conn.commit()
    print(f'✓ Populated dim_questions with {len(questions)} questions')

# Fixed: This function is now at the correct indentation level
def populate_fact_interview_events(conn):
    """Populate fact table with sample interview events"""
    cursor = conn.cursor()
    
    # Get dimension keys
    cursor.execute("SELECT company_key FROM dim_companies LIMIT 5")  # Fixed: was just 'company'
    company_keys = [row[0] for row in cursor.fetchall()]
      
    cursor.execute("SELECT date_key FROM dim_time WHERE full_date >= CURRENT_DATE - INTERVAL '60 days' ORDER BY full_date")
    date_keys = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT round_type_key FROM dim_round_types")
    round_type_keys = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT question_key FROM dim_questions")
    question_keys = [row[0] for row in cursor.fetchall()]
    
    # Generate sample interview events
    for i in range(50):
        company_key = random.choice(company_keys)
        date_key = random.choice(date_keys)
        round_type_key = random.choice(round_type_keys)
        question_key = random.choice(question_keys)
        interview_round_id = f"ROUND-{i // 3 + 1:03d}"  # 3 questions per round
        
        cursor.execute("""
            INSERT INTO fact_interview_events (
                company_key, date_key, round_type_key, question_key,
                interview_round_id, duration_minutes, result,
                difficulty_rating, answer_quality_rating,
                was_prepared, needed_hint
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            company_key,
            date_key,
            round_type_key,
            question_key,
            interview_round_id,
            random.randint(30, 90),
            random.choice(['passed', 'passed', 'failed']),  # 66% pass rate
            random.randint(2, 5),
            random.randint(2, 5),
            random.choice([True, False]),
            random.choice([True, False])
        ))
    
    conn.commit()
    print(f"✓ Populated fact_interview_events with 50 sample events")

def main():
    """Main execution function"""
    print("Starting data warehouse population...\n")
    
    conn = get_connection()
    
    try:
        # Populate dimensions first (order matters due to foreign keys!)
        start_date = datetime(2024, 1, 1)
        end_date = datetime(2025, 12, 31)
        populate_dim_time(conn, start_date, end_date)
        
        populate_dim_companies(conn) 
        populate_dim_topics(conn)
        populate_dim_round_types(conn)
        populate_dim_questions(conn) 
        
        # Populate fact table last
        populate_fact_interview_events(conn) 
        
        print("\n Data warehouse successfully populated!")
        print("\nNext steps:")
        print("1. Run sample queries to verify data")
        print("2. Check the pre-built views")
        print("3. Start building your analytics!")
        
    except Exception as e:
        print(f"\n Error: {e}")
        import traceback
        traceback.print_exc()
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    main()
