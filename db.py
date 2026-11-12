import sqlite3
import bcrypt
import os
import re

DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vedaguru.db")

def extract_lat_lng(address_str, lat=0.0, lng=0.0):
    try:
        if lat is not None and lng is not None:
            f_lat, f_lng = float(lat), float(lng)
            if f_lat != 0.0 or f_lng != 0.0:
                return f_lat, f_lng
    except:
        pass
    if not address_str:
        return 18.5204, 73.8567
    match = re.search(r'Map:\s*([0-9\.\-]+)°?[N|S]?,\s*([0-9\.\-]+)°?[E|W]?', address_str)
    if match:
        try:
            return float(match.group(1)), float(match.group(2))
        except:
            pass
    return 18.5204, 73.8567

def get_connection():
    return sqlite3.connect(DB_FILE, check_same_thread=False)

def init_db():
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            default_region TEXT DEFAULT 'General/Standard',
            preferred_language TEXT DEFAULT 'English',
            account_type TEXT DEFAULT 'User'
        )
    ''')
    
    c.execute('''
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            module_name TEXT NOT NULL,
            query_details TEXT NOT NULL,
            response_text TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    c.execute('''
        CREATE TABLE IF NOT EXISTS yajmans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purohit_username TEXT NOT NULL,
            client_name TEXT NOT NULL,
            contact_number TEXT NOT NULL,
            pooja_date TEXT NOT NULL,
            pooja_type TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    c.execute('''
        CREATE TABLE IF NOT EXISTS community_vidhi (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            author_username TEXT NOT NULL,
            title TEXT NOT NULL,
            region TEXT NOT NULL,
            vidhi_text TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    c.execute('''
        CREATE TABLE IF NOT EXISTS user_bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_username TEXT NOT NULL,
            pooja_type TEXT NOT NULL,
            pooja_date TEXT NOT NULL,
            status TEXT DEFAULT 'Pending',
            purohit_username TEXT,
            contact_number TEXT,
            address TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Migration for existing DB
    try:
        c.execute('ALTER TABLE users ADD COLUMN preferred_language TEXT DEFAULT "English"')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE users ADD COLUMN account_type TEXT DEFAULT "User"')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN contact_number TEXT DEFAULT "Not Provided"')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN address TEXT DEFAULT "Not Provided"')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN rating INTEGER DEFAULT 0')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN feedback TEXT DEFAULT ""')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE yajmans ADD COLUMN address TEXT DEFAULT "Not Provided"')
    except sqlite3.OperationalError:
        pass

    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN latitude REAL DEFAULT 0.0')
    except sqlite3.OperationalError:
        pass

    try:
        c.execute('ALTER TABLE user_bookings ADD COLUMN longitude REAL DEFAULT 0.0')
    except sqlite3.OperationalError:
        pass

    try:
        c.execute('ALTER TABLE yajmans ADD COLUMN latitude REAL DEFAULT 0.0')
    except sqlite3.OperationalError:
        pass

    try:
        c.execute('ALTER TABLE yajmans ADD COLUMN longitude REAL DEFAULT 0.0')
    except sqlite3.OperationalError:
        pass

    try:
        c.execute('ALTER TABLE users ADD COLUMN security_question TEXT DEFAULT ""')
    except sqlite3.OperationalError:
        pass
        
    try:
        c.execute('ALTER TABLE users ADD COLUMN security_answer_hash TEXT DEFAULT ""')
    except sqlite3.OperationalError:
        pass
        
    c.execute('''
        CREATE TABLE IF NOT EXISTS chat_memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            bot_type TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
        
    c.execute('''
        CREATE TABLE IF NOT EXISTS purohit_availability (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purohit_username TEXT NOT NULL,
            blocked_date TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS yagya_boards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_username TEXT NOT NULL,
            title TEXT NOT NULL,
            event_date TEXT NOT NULL,
            description TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS yagya_collaborators (
            board_id INTEGER NOT NULL,
            collaborator_username TEXT NOT NULL,
            PRIMARY KEY (board_id, collaborator_username)
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS yagya_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            board_id INTEGER NOT NULL,
            task_desc TEXT NOT NULL,
            assignee_username TEXT,
            status TEXT DEFAULT 'Pending'
        )
    ''')

    conn.commit()
    conn.close()

def register_user(username, password, default_region, preferred_language="English", account_type="User", security_question="", security_answer=""):
    conn = get_connection()
    c = conn.cursor()
    
    # Check if user exists
    c.execute('SELECT username FROM users WHERE username = ?', (username,))
    if c.fetchone():
        conn.close()
        return False, "Username already exists."
        
    # Hash password
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    
    sec_answer_hash = ""
    if security_answer and security_answer.strip():
        ans_salt = bcrypt.gensalt()
        sec_answer_hash = bcrypt.hashpw(security_answer.strip().lower().encode('utf-8'), ans_salt).decode('utf-8')
    
    try:
        c.execute('''
            INSERT INTO users (username, password_hash, default_region, preferred_language, account_type, security_question, security_answer_hash)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (username, hashed.decode('utf-8'), default_region, preferred_language, account_type, security_question.strip(), sec_answer_hash))
        conn.commit()
        return True, "User registered successfully."
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def get_user_for_recovery(username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT username, security_question, security_answer_hash, default_region, account_type FROM users WHERE username = ?', (username,))
    row = c.fetchone()
    conn.close()
    if row:
        sec_q = row[1] if row[1] else ""
        sec_a_hash = row[2] if row[2] else ""
        return {
            'username': row[0],
            'security_question': sec_q,
            'has_security_question': bool(sec_q and sec_a_hash),
            'default_region': row[3],
            'account_type': row[4]
        }
    return None

def reset_user_password(username, new_password, security_answer="", verify_region=None, verify_role=None, new_security_question="", new_security_answer=""):
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT security_question, security_answer_hash, default_region, account_type FROM users WHERE username = ?', (username,))
    row = c.fetchone()
    if not row:
        conn.close()
        return False, "User not found."
    
    sec_q = row[0] if row[0] else ""
    sec_a_hash = row[1] if row[1] else ""
    db_region = row[2]
    db_role = row[3]
    
    # Check verification
    if sec_q and sec_a_hash:
        if not security_answer or not security_answer.strip():
            conn.close()
            return False, "Please provide the security answer."
        if not bcrypt.checkpw(security_answer.strip().lower().encode('utf-8'), sec_a_hash.encode('utf-8')):
            conn.close()
            return False, "Incorrect security answer. Please try again."
    else:
        # Fallback verification for legacy accounts
        if verify_region is not None and db_region != verify_region:
            conn.close()
            return False, "Selected region tradition does not match your registered account."
        if verify_role is not None and db_role != verify_role:
            conn.close()
            return False, "Selected account role does not match your registered account."
            
    # Hash new password
    salt = bcrypt.gensalt()
    new_hashed = bcrypt.hashpw(new_password.encode('utf-8'), salt).decode('utf-8')
    
    try:
        if new_security_question and new_security_answer:
            ans_salt = bcrypt.gensalt()
            new_ans_hash = bcrypt.hashpw(new_security_answer.strip().lower().encode('utf-8'), ans_salt).decode('utf-8')
            c.execute('''
                UPDATE users 
                SET password_hash = ?, security_question = ?, security_answer_hash = ?
                WHERE username = ?
            ''', (new_hashed, new_security_question.strip(), new_ans_hash, username))
        else:
            c.execute('UPDATE users SET password_hash = ? WHERE username = ?', (new_hashed, username))
            
        conn.commit()
        return True, "Password reset successfully! You can now log in."
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def verify_login(username, password):
    conn = get_connection()
    c = conn.cursor()
    
    c.execute('SELECT password_hash, default_region, preferred_language, account_type FROM users WHERE username = ?', (username,))
    row = c.fetchone()
    conn.close()
    
    if row:
        stored_hash = row[0].encode('utf-8')
        default_region = row[1]
        preferred_language = row[2] if len(row) > 2 else "English"
        account_type = row[3] if len(row) > 3 else "User"
        
        if bcrypt.checkpw(password.encode('utf-8'), stored_hash):
            return True, default_region, preferred_language, account_type
            
    return False, None, None, None

def update_profile(username, new_region, new_language):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('UPDATE users SET default_region = ?, preferred_language = ? WHERE username = ?', (new_region, new_language, username))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def log_history(username, module_name, query_details, response_text):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO history (username, module_name, query_details, response_text)
            VALUES (?, ?, ?, ?)
        ''', (username, module_name, query_details, response_text))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_user_history(username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT module_name, query_details, response_text, timestamp 
        FROM history 
        WHERE username = ? 
        ORDER BY timestamp DESC
    ''', (username,))
    
    rows = c.fetchall()
    conn.close()
    
    history_list = []
    for r in rows:
        history_list.append({
            'module_name': r[0],
            'query_details': r[1],
            'response_text': r[2],
            'timestamp': r[3]
        })
    return history_list

def get_all_users():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT id, username, password_hash, default_region, preferred_language, account_type FROM users ORDER BY id ASC')
    rows = c.fetchall()
    conn.close()
    
    users = []
    for r in rows:
        users.append({
            'ID': str(r[0]), # Convert to string for better alignment in Streamlit
            'Username': r[1],
            'Role': r[5] if len(r) > 5 else "User",
            'Encrypted Password': r[2][:20] + "...", # Truncate hash for display
            'Region': r[3],
            'Language': r[4]
        })
    return users

def get_all_purohits():
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT username FROM users WHERE account_type = 'Purohit'")
    rows = c.fetchall()
    conn.close()
    return [r[0] for r in rows]

def add_client(purohit_username, client_name, contact_number, pooja_date, pooja_type, address="Not Provided", latitude=0.0, longitude=0.0):
    conn = get_connection()
    c = conn.cursor()
    lat, lng = extract_lat_lng(address, latitude, longitude)
    try:
        c.execute('''
            INSERT INTO yajmans (purohit_username, client_name, contact_number, pooja_date, pooja_type, address, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (purohit_username, client_name, contact_number, pooja_date, pooja_type, address, lat, lng))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_clients(purohit_username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT id, client_name, contact_number, pooja_date, pooja_type, address, latitude, longitude 
        FROM yajmans 
        WHERE purohit_username = ? 
        ORDER BY pooja_date ASC
    ''', (purohit_username,))
    
    rows = c.fetchall()
    conn.close()
    
    clients = []
    for r in rows:
        addr = r[5] if len(r) > 5 and r[5] else "Not Provided"
        raw_lat = r[6] if len(r) > 6 and r[6] is not None else 0.0
        raw_lng = r[7] if len(r) > 7 and r[7] is not None else 0.0
        lat, lng = extract_lat_lng(addr, raw_lat, raw_lng)
        clients.append({
            'ID': r[0],
            'id': r[0],
            'Client Name': r[1],
            'client_name': r[1],
            'User': r[1],
            'user_username': r[1],
            'Contact': r[2],
            'contact_number': r[2],
            'Pooja Date': r[3],
            'pooja_date': r[3],
            'Pooja Type': r[4],
            'pooja_type': r[4],
            'Address': addr,
            'address': addr,
            'latitude': lat,
            'longitude': lng,
            'lat': lat,
            'lng': lng,
        })
    return clients

def delete_client(client_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM yajmans WHERE id = ?', (client_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def add_community_vidhi(author_username, title, region, vidhi_text):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO community_vidhi (author_username, title, region, vidhi_text)
            VALUES (?, ?, ?, ?)
        ''', (author_username, title, region, vidhi_text))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_all_community_vidhi():
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT id, author_username, title, region, vidhi_text, timestamp 
        FROM community_vidhi 
        ORDER BY timestamp DESC
    ''')
    
    rows = c.fetchall()
    conn.close()
    
    vidhis = []
    for r in rows:
        vidhis.append({
            'ID': r[0],
            'Author': r[1],
            'Title': r[2],
            'Region': r[3],
            'Vidhi Text': r[4],
            'Timestamp': r[5]
        })
    return vidhis

def delete_community_vidhi(vidhi_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM community_vidhi WHERE id = ?', (vidhi_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def add_user_booking(user_username, pooja_type, pooja_date, contact_number, address, purohit_username="", latitude=0.0, longitude=0.0):
    conn = get_connection()
    c = conn.cursor()
    lat, lng = extract_lat_lng(address, latitude, longitude)
    try:
        c.execute('''
            INSERT INTO user_bookings (user_username, pooja_type, pooja_date, contact_number, address, purohit_username, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (user_username, pooja_type, pooja_date, contact_number, address, purohit_username, lat, lng))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_user_bookings(user_username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT id, pooja_type, pooja_date, status, purohit_username, contact_number, address, rating, feedback, latitude, longitude 
        FROM user_bookings 
        WHERE user_username = ? 
        ORDER BY timestamp DESC
    ''', (user_username,))
    rows = c.fetchall()
    conn.close()
    
    bookings = []
    for r in rows:
        addr = r[6] if len(r) > 6 and r[6] else "Not Provided"
        raw_lat = r[9] if len(r) > 9 and r[9] is not None else 0.0
        raw_lng = r[10] if len(r) > 10 and r[10] is not None else 0.0
        lat, lng = extract_lat_lng(addr, raw_lat, raw_lng)
        bookings.append({
            'ID': r[0],
            'id': r[0],
            'Pooja Type': r[1],
            'pooja_type': r[1],
            'Pooja Date': r[2],
            'pooja_date': r[2],
            'Status': r[3],
            'status': r[3],
            'Purohit': r[4] if r[4] else "Not Assigned",
            'purohit_username': r[4] if r[4] else "",
            'Contact': r[5] if len(r) > 5 and r[5] else "Not Provided",
            'contact_number': r[5] if len(r) > 5 and r[5] else "",
            'Address': addr,
            'address': addr,
            'Rating': r[7] if len(r) > 7 and r[7] is not None else 0,
            'rating': r[7] if len(r) > 7 and r[7] is not None else 0,
            'Feedback': r[8] if len(r) > 8 and r[8] else "",
            'feedback': r[8] if len(r) > 8 and r[8] else "",
            'latitude': lat,
            'longitude': lng,
            'lat': lat,
            'lng': lng,
        })
    return bookings

def get_all_pending_bookings(purohit_username=None):
    conn = get_connection()
    c = conn.cursor()
    if purohit_username:
        c.execute('''
            SELECT id, user_username, pooja_type, pooja_date, status, contact_number, address, latitude, longitude 
            FROM user_bookings 
            WHERE (status = 'Pending' AND (purohit_username IS NULL OR purohit_username = '')) 
               OR (status = 'Pending' AND purohit_username = ?)
            ORDER BY timestamp DESC
        ''', (purohit_username,))
    else:
        c.execute('''
            SELECT id, user_username, pooja_type, pooja_date, status, contact_number, address, latitude, longitude 
            FROM user_bookings 
            WHERE status = 'Pending' AND (purohit_username IS NULL OR purohit_username = '')
            ORDER BY timestamp DESC
        ''')
    rows = c.fetchall()
    conn.close()
    
    bookings = []
    for r in rows:
        addr = r[6] if len(r) > 6 and r[6] else "Not Provided"
        raw_lat = r[7] if len(r) > 7 and r[7] is not None else 0.0
        raw_lng = r[8] if len(r) > 8 and r[8] is not None else 0.0
        lat, lng = extract_lat_lng(addr, raw_lat, raw_lng)
        bookings.append({
            'ID': r[0],
            'id': r[0],
            'User': r[1],
            'user_username': r[1],
            'client_name': r[1],
            'Pooja Type': r[2],
            'pooja_type': r[2],
            'Pooja Date': r[3],
            'pooja_date': r[3],
            'Status': r[4],
            'status': r[4],
            'Contact': r[5] if len(r) > 5 and r[5] else "Not Provided",
            'contact_number': r[5] if len(r) > 5 and r[5] else "",
            'Address': addr,
            'address': addr,
            'latitude': lat,
            'longitude': lng,
            'lat': lat,
            'lng': lng,
        })
    return bookings

def accept_booking(booking_id, purohit_username):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('SELECT user_username, contact_number, pooja_date, pooja_type, address, latitude, longitude FROM user_bookings WHERE id = ?', (booking_id,))
        row = c.fetchone()
        if row:
            u_user, u_contact, u_date, u_type, u_addr, u_lat, u_lng = row
            # Add to yajmans if not already present
            c.execute('SELECT id FROM yajmans WHERE purohit_username = ? AND client_name = ? AND pooja_date = ?', (purohit_username, u_user, u_date))
            if not c.fetchone():
                c.execute('''
                    INSERT INTO yajmans (purohit_username, client_name, contact_number, pooja_date, pooja_type, address, latitude, longitude)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ''', (purohit_username, u_user, u_contact or "Not Provided", u_date, u_type, u_addr or "Not Provided", u_lat or 0.0, u_lng or 0.0))
        c.execute('''
            UPDATE user_bookings 
            SET status = 'Confirmed', purohit_username = ? 
            WHERE id = ?
        ''', (purohit_username, booking_id))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_purohit_bookings(purohit_username, status=None):
    conn = get_connection()
    c = conn.cursor()
    if status:
        c.execute('''
            SELECT id, user_username, pooja_type, pooja_date, status, contact_number, address, rating, feedback, latitude, longitude
            FROM user_bookings
            WHERE purohit_username = ? AND status = ?
            ORDER BY timestamp DESC
        ''', (purohit_username, status))
    else:
        c.execute('''
            SELECT id, user_username, pooja_type, pooja_date, status, contact_number, address, rating, feedback, latitude, longitude
            FROM user_bookings
            WHERE purohit_username = ?
            ORDER BY timestamp DESC
        ''', (purohit_username,))
    rows = c.fetchall()
    conn.close()
    
    bookings = []
    for r in rows:
        addr = r[6] if len(r) > 6 and r[6] else "Not Provided"
        raw_lat = r[9] if len(r) > 9 and r[9] is not None else 0.0
        raw_lng = r[10] if len(r) > 10 and r[10] is not None else 0.0
        lat, lng = extract_lat_lng(addr, raw_lat, raw_lng)
        bookings.append({
            'ID': r[0],
            'id': r[0],
            'User': r[1],
            'user_username': r[1],
            'client_name': r[1],
            'Pooja Type': r[2],
            'pooja_type': r[2],
            'Pooja Date': r[3],
            'pooja_date': r[3],
            'Status': r[4],
            'status': r[4],
            'Contact': r[5] if len(r) > 5 and r[5] else "Not Provided",
            'contact_number': r[5] if len(r) > 5 and r[5] else "",
            'Address': addr,
            'address': addr,
            'Rating': r[7] if len(r) > 7 and r[7] is not None else 0,
            'rating': r[7] if len(r) > 7 and r[7] is not None else 0,
            'Feedback': r[8] if len(r) > 8 and r[8] else "",
            'feedback': r[8] if len(r) > 8 and r[8] else "",
            'latitude': lat,
            'longitude': lng,
            'lat': lat,
            'lng': lng,
        })
    return bookings

def cancel_booking(booking_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM user_bookings WHERE id = ?', (booking_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def complete_booking(booking_id, rating, feedback):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            UPDATE user_bookings 
            SET status = 'Completed', rating = ?, feedback = ? 
            WHERE id = ?
        ''', (rating, feedback, booking_id))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_purohit_reviews(purohit_username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT pooja_type, pooja_date, user_username, rating, feedback
        FROM user_bookings
        WHERE purohit_username = ? AND status = 'Completed' AND rating > 0
        ORDER BY timestamp DESC
    ''', (purohit_username,))
    rows = c.fetchall()
    conn.close()
    
    reviews = []
    for r in rows:
        reviews.append({
            'Pooja Type': r[0],
            'Pooja Date': r[1],
            'User': r[2],
            'Rating': r[3],
            'Feedback': r[4]
        })
    return reviews

# --- Analytics Functions ---

def get_analytics_summary():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT COUNT(*) FROM users')
    total_users = c.fetchone()[0]
    
    c.execute('SELECT COUNT(*) FROM history')
    total_queries = c.fetchone()[0]
    
    c.execute('SELECT COUNT(*) FROM yajmans')
    total_yajmans = c.fetchone()[0]
    conn.close()
    
    return {
        "Total Users": total_users,
        "Total Queries": total_queries,
        "Total Yajmans": total_yajmans
    }

def get_module_usage_stats():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT module_name, COUNT(*) FROM history GROUP BY module_name')
    rows = c.fetchall()
    conn.close()
    return {row[0]: row[1] for row in rows}

def get_user_role_stats():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT account_type, COUNT(*) FROM users GROUP BY account_type')
    rows = c.fetchall()
    conn.close()
    return {row[0] if row[0] else 'User': row[1] for row in rows}

def get_region_stats():
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT default_region, COUNT(*) FROM users GROUP BY default_region')
    rows = c.fetchall()
    conn.close()
    return {row[0]: row[1] for row in rows}

def save_chat_message(username, bot_type, role, content):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO chat_memory (username, bot_type, role, content)
            VALUES (?, ?, ?, ?)
        ''', (username, bot_type, role, content))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_chat_history(username, bot_type):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT role, content, timestamp 
        FROM chat_memory 
        WHERE username = ? AND bot_type = ? 
        ORDER BY timestamp ASC
    ''', (username, bot_type))
    rows = c.fetchall()
    conn.close()
    
    history = []
    for r in rows:
        history.append({
            "role": r[0],
            "content": r[1],
            "timestamp": str(r[2]) if len(r) > 2 and r[2] else ""
        })
    return history

def clear_chat_history(username, bot_type):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM chat_memory WHERE username = ? AND bot_type = ?', (username, bot_type))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def add_blocked_date(purohit_username, blocked_date):
    conn = get_connection()
    c = conn.cursor()
    # Check if already blocked
    c.execute('SELECT id FROM purohit_availability WHERE purohit_username = ? AND blocked_date = ?', (purohit_username, blocked_date))
    if c.fetchone():
        conn.close()
        return False, "Date is already blocked."
        
    try:
        c.execute('''
            INSERT INTO purohit_availability (purohit_username, blocked_date)
            VALUES (?, ?)
        ''', (purohit_username, blocked_date))
        conn.commit()
        return True, "Date blocked successfully."
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def get_blocked_dates(purohit_username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT id, blocked_date 
        FROM purohit_availability 
        WHERE purohit_username = ? 
        ORDER BY blocked_date ASC
    ''', (purohit_username,))
    rows = c.fetchall()
    conn.close()
    
    dates = []
    for r in rows:
        dates.append({
            'ID': r[0],
            'Date': r[1]
        })
    return dates

def remove_blocked_date(block_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM purohit_availability WHERE id = ?', (block_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def check_purohit_availability(purohit_username, date_str):
    conn = get_connection()
    c = conn.cursor()
    
    # Check if explicitly blocked
    c.execute('SELECT id FROM purohit_availability WHERE purohit_username = ? AND blocked_date = ?', (purohit_username, date_str))
    if c.fetchone():
        conn.close()
        return False
        
    # Check if already has a confirmed pooja on that date
    c.execute('SELECT id FROM yajmans WHERE purohit_username = ? AND pooja_date = ?', (purohit_username, date_str))
    if c.fetchone():
        conn.close()
        return False
        
    conn.close()
    return True

def create_yagya_board(owner_username, title, event_date, description):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO yagya_boards (owner_username, title, event_date, description)
            VALUES (?, ?, ?, ?)
        ''', (owner_username, title, event_date, description))
        board_id = c.lastrowid
        conn.commit()
        return True, board_id
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def get_user_yagya_boards(username):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT DISTINCT b.id, b.owner_username, b.title, b.event_date, b.description 
        FROM yagya_boards b
        LEFT JOIN yagya_collaborators c ON b.id = c.board_id
        WHERE b.owner_username = ? OR c.collaborator_username = ?
        ORDER BY b.event_date DESC
    ''', (username, username))
    rows = c.fetchall()
    conn.close()
    
    boards = []
    for r in rows:
        boards.append({
            'ID': r[0],
            'Owner': r[1],
            'Title': r[2],
            'Date': r[3],
            'Description': r[4]
        })
    return boards

def delete_yagya_board(board_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM yagya_boards WHERE id = ?', (board_id,))
        c.execute('DELETE FROM yagya_collaborators WHERE board_id = ?', (board_id,))
        c.execute('DELETE FROM yagya_tasks WHERE board_id = ?', (board_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def add_collaborator(board_id, collaborator_username):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO yagya_collaborators (board_id, collaborator_username)
            VALUES (?, ?)
        ''', (board_id, collaborator_username))
        conn.commit()
        return True, "Collaborator added."
    except sqlite3.IntegrityError:
        return False, "User is already a collaborator."
    except Exception as e:
        return False, str(e)
    finally:
        conn.close()

def get_board_collaborators(board_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute('SELECT collaborator_username FROM yagya_collaborators WHERE board_id = ?', (board_id,))
    rows = c.fetchall()
    conn.close()
    return [r[0] for r in rows]

def remove_collaborator(board_id, collaborator_username):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM yagya_collaborators WHERE board_id = ? AND collaborator_username = ?', (board_id, collaborator_username))
        c.execute("UPDATE yagya_tasks SET assignee_username = 'Unassigned' WHERE board_id = ? AND assignee_username = ?", (board_id, collaborator_username))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def add_yagya_task(board_id, task_desc, assignee_username):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('''
            INSERT INTO yagya_tasks (board_id, task_desc, assignee_username)
            VALUES (?, ?, ?)
        ''', (board_id, task_desc, assignee_username))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def get_board_tasks(board_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute('''
        SELECT id, task_desc, assignee_username, status 
        FROM yagya_tasks 
        WHERE board_id = ?
    ''', (board_id,))
    rows = c.fetchall()
    conn.close()
    
    tasks = []
    for r in rows:
        tasks.append({
            'ID': r[0],
            'Task': r[1],
            'Assignee': r[2] if r[2] else 'Unassigned',
            'Status': r[3]
        })
    return tasks

def update_task_status(task_id, new_status):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('UPDATE yagya_tasks SET status = ? WHERE id = ?', (new_status, task_id))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()

def delete_task(task_id):
    conn = get_connection()
    c = conn.cursor()
    try:
        c.execute('DELETE FROM yagya_tasks WHERE id = ?', (task_id,))
        conn.commit()
        return True
    except:
        return False
    finally:
        conn.close()
