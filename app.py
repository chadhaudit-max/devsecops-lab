# app.py
# Simple Flask app - intentionally has security issues for learning purposes

from flask import Flask, request, jsonify, render_template_string
import sqlite3
import os

app = Flask(__name__)

# ❌ Hardcoded secret key (Semgrep/Gitleaks will catch this)
app.secret_key = "supersecretkey123"

# ❌ Hardcoded fake API key (secrets scanner will catch this)
API_KEY = "sk-prod-abc123xyz456supersecret"

# ❌ Database stored in plaintext, no encryption
DB_FILE = "users.db"

def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT,
            password TEXT
        )
    """)
    # ❌ Passwords stored in plaintext
    cursor.execute("INSERT OR IGNORE INTO users VALUES (1, 'admin', 'admin123')")
    cursor.execute("INSERT OR IGNORE INTO users VALUES (2, 'udit', 'password')")
    conn.commit()
    conn.close()

@app.route("/")
def index():
    return render_template_string("""
        <h1>Login</h1>
        <form method="POST" action="/login">
            <input name="username" placeholder="Username"><br>
            <input name="password" type="password" placeholder="Password"><br>
            <button type="submit">Login</button>
        </form>
    """)

@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username")
    password = request.form.get("password")

    # ❌ SQL Injection vulnerability - user input directly in query
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    cursor.execute(query)
    user = cursor.fetchone()
    conn.close()

    if user:
        return render_template_string("""
            <h1>Welcome {{ name }}!</h1>
            <a href="/dashboard">Go to Dashboard</a>
        """, name=username)
    else:
        return "Invalid credentials", 401

@app.route("/dashboard")
def dashboard():
    # ❌ No authentication check - anyone can access this
    user = request.args.get("user", "guest")

    # ❌ XSS vulnerability - user input reflected without escaping
    return render_template_string(f"""
        <h1>Dashboard</h1>
        <p>Welcome back, {user}!</p>
        <p>You have admin access.</p>
    """)

@app.route("/api/users")
def get_users():
    # ❌ No auth, returns ALL users including passwords
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    conn.close()
    return jsonify(users)

@app.route("/api/search")
def search():
    term = request.args.get("q", "")

    # ❌ Another SQL injection
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute(f"SELECT username FROM users WHERE username LIKE '%{term}%'")
    results = cursor.fetchall()
    conn.close()

    return jsonify(results)

if __name__ == "__main__":
    init_db()
    # ❌ Debug mode ON in production - exposes interactive debugger
    app.run(debug=True, host="0.0.0.0", port=5000)
