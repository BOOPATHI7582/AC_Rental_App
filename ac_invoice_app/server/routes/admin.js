const express = require('express');

const User = require('../models/User');
const Invoice = require('../models/Invoice');
const requireAuth = require('../middleware/auth');
const requireAdmin = require('../middleware/admin');

const router = express.Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/users - every registered user (no password hashes)
router.get('/users', async (req, res) => {
  try {
    const users = await User.find({}, '-passwordHash').sort({ createdAt: -1 });
    res.json(
      users.map((u) => ({
        id: u._id,
        name: u.name,
        phone: u.phone,
        email: u.email,
        role: u.role,
        createdAt: u.createdAt,
      }))
    );
  } catch (e) {
    res.status(500).json({ error: 'Could not load users' });
  }
});

// GET /api/admin/invoices - every invoice from every user, newest first,
// with the owning user's name/email attached so the admin can see who
// created each one.
router.get('/invoices', async (req, res) => {
  try {
    const invoices = await Invoice.find({}).sort({ date: -1 }).populate('userId', 'name email');
    res.json(
      invoices.map((inv) => ({
        id: inv.clientInvoiceId,
        invoiceNo: inv.invoiceNo,
        date: inv.date,
        clientId: inv.clientId,
        clientName: inv.clientName,
        clientPhone: inv.clientPhone,
        clientGstin: inv.clientGstin,
        clientAddress: inv.clientAddress,
        clientState: inv.clientState,
        items: inv.items,
        receivedAmount: inv.receivedAmount,
        notes: inv.notes,
        rentalStartDate: inv.rentalStartDate,
        rentalEndDate: inv.rentalEndDate,
        createdByName: inv.userId && inv.userId.name,
        createdByEmail: inv.userId && inv.userId.email,
      }))
    );
  } catch (e) {
    res.status(500).json({ error: 'Could not load invoices' });
  }
});

// PUT /api/admin/users/:id/role - promote/demote a user. Body: { role: 'admin' | 'user' }
router.put('/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    if (role !== 'admin' && role !== 'user') {
      return res.status(400).json({ error: "role must be 'admin' or 'user'" });
    }
    if (req.params.id === req.userId) {
      return res.status(400).json({ error: 'You cannot change your own role here' });
    }

    const user = await User.findByIdAndUpdate(req.params.id, { role }, { new: true });
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({ id: user._id, name: user.name, email: user.email, role: user.role });
  } catch (e) {
    res.status(500).json({ error: 'Could not update user role' });
  }
});

// DELETE /api/admin/users/:id - removes the user and their invoices
router.delete('/users/:id', async (req, res) => {
  try {
    if (req.params.id === req.userId) {
      return res.status(400).json({ error: 'You cannot delete your own account here' });
    }

    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    await Invoice.deleteMany({ userId: req.params.id });
    res.json({ deleted: true });
  } catch (e) {
    res.status(500).json({ error: 'Could not delete user' });
  }
});

module.exports = router;
