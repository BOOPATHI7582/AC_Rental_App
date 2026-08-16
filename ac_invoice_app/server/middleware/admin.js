/// Must run after requireAuth (needs req.role set). Rejects with 403 if the
/// logged-in user isn't an admin.
module.exports = function requireAdmin(req, res, next) {
  if (req.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access only' });
  }
  next();
};
