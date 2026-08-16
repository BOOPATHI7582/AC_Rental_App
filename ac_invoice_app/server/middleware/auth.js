const jwt = require('jsonwebtoken');

/// Verifies the "Authorization: Bearer <token>" header and attaches
/// req.userId for downstream routes. Rejects with 401 if missing/invalid.
module.exports = function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing auth token' });

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = payload.userId;
    req.role = payload.role || 'user';
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};
