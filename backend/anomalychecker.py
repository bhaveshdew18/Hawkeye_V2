import psycopg2
from datetime import datetime, timedelta

def get_db_connection():
    return psycopg2.connect(
        host="localhost",
        database="touristsafety",
        user="youruser",
        password="yourpassword"
    )

def find_anomalies():
    conn = get_db_connection()
    cur = conn.cursor()
    time_threshold = datetime.now() - timedelta(hours=2)
    
    query = """
    SELECT tourist_id, MAX(timestamp) as last_seen
    FROM locations
    GROUP BY tourist_id
    HAVING MAX(timestamp) < %s;
    """
    
    cur.execute(query, (time_threshold,))
    anomalous_users = cur.fetchall()
    
    if anomalous_users:
        for user in anomalous_users:
            tourist_id, last_seen = user
            print(f"⚠️ Low-priority alert: Tourist {tourist_id} has not checked in since {last_seen}.")
    else:
        print("✅ No anomalies found.")
        
    cur.close()
    conn.close()

if __name__ == "__main__":
    print(f"Running anomaly check at {datetime.now()}...")
    find_anomalies()