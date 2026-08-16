const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/User');

const router = express.Router();

function adminEmails() {
  return (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
}

router.post('/register', async (req, res) => {
  try {
    const { name, phone, email, password } = req.body;
    if (!name || !email || !password || password.length < 6) {
      return res
        .status(400)
        .json({ error: 'Name, email, and a password of at least 6 characters are required' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const role = adminEmails().includes(email.toLowerCase()) ? 'admin' : 'user';
    const user = await User.create({
      name,
      phone: phone || '',
      email: email.toLowerCase(),
      passwordHash,
      role,
    });
    res.status(201).json({ userId: user._id });
  } catch (e) {
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email: (email || '').toLowerCase() });
    if (!user) return res.status(401).json({ error: 'Invalid email or password' });

    const ok = await bcrypt.compare(password || '', user.passwordHash);
    if (!ok) return res.status(401).json({ error: 'Invalid email or password' });

    const token = jwt.sign(
      { userId: user._id.toString(), role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );
    res.json({
      token,
      userId: user._id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
    });
  } catch (e) {
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

module.exports = router;
