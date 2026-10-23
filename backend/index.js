const express = require('express');
const cors = require('cors');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;
const adminToken = process.env.ADMIN_TOKEN;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Database setup
const db = new sqlite3.Database('./emails.db', (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database.');
    db.run(`CREATE TABLE IF NOT EXISTS waitlist (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
  }
});

/**
 * @api {post} /api/waitlist Submit name & email
 */
app.post('/api/waitlist', (req, res) => {
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email are required.' });
  }

  const normalizedName = String(name).trim();
  const normalizedEmail = String(email).trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!normalizedName || !emailRegex.test(normalizedEmail)) {
    return res.status(400).json({ error: 'Please provide a valid name and email.' });
  }

  const sql = `INSERT INTO waitlist (name, email) VALUES (?, ?)`;
  const params = [normalizedName, normalizedEmail];

  db.run(sql, params, function (err) {
    if (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        return res.status(409).json({ error: 'You are already on the waitlist!' });
      }
      return res.status(500).json({ error: err.message });
    }
    res.json({
      message: 'Success',
      data: { id: this.lastID, name: normalizedName, email: normalizedEmail },
    });
  });
});

/**
 * @api {get} /admin View signups in table
 */
app.get('/admin', (req, res) => {
  const providedToken = req.get('x-admin-token') || req.query.token;
  if (!adminToken || providedToken !== adminToken) {
    return res.status(403).send('Forbidden');
  }

  const sql = "SELECT * FROM waitlist ORDER BY created_at DESC";
  db.all(sql, [], (err, rows) => {
    if (err) return res.status(400).send(err.message);

    const escapeHtml = (value) => String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');

    let html = `<html><body style="background:#080808; color:white; font-family:monospace; padding:40px;">`;
    html += `<h1 style="color:#F0FF00">KEEL WAITLIST (Total: ${rows.length})</h1>`;
    html += `<table border="1" style="width:100%; border-collapse:collapse; border-color:#333;">`;
    html += `<tr><th>ID</th><th>NAME</th><th>EMAIL</th><th>DATE</th></tr>`;
    rows.forEach(r => {
      html += `<tr><td style="padding:10px;">${escapeHtml(r.id)}</td><td>${escapeHtml(r.name)}</td><td>${escapeHtml(r.email)}</td><td>${escapeHtml(r.created_at)}</td></tr>`;
    });
    html += `</table></body></html>`;
    res.send(html);
  });
});

// Start server
app.listen(port, () => {
  console.log(`Backend server running on http://localhost:${port}`);
});
