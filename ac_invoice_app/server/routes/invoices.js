const express = require('express');

const Invoice = require('../models/Invoice');
const requireAuth = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// GET /api/invoices - every invoice belonging to the logged-in user
router.get('/', async (req, res) => {
  try {
    const invoices = await Invoice.find({ userId: req.userId });
    res.json(invoices.map(toClientJson));
  } catch (e) {
    res.status(500).json({ error: 'Could not load invoices' });
  }
});

// PUT /api/invoices/:id - create or update (id = the Flutter-generated uuid)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const body = { ...req.body };
    delete body.id; // avoid clashing with clientInvoiceId below

    const invoice = await Invoice.findOneAndUpdate(
      { userId: req.userId, clientInvoiceId: id },
      { ...body, clientInvoiceId: id, userId: req.userId },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    res.json(toClientJson(invoice));
  } catch (e) {
    res.status(500).json({ error: 'Could not save invoice' });
  }
});

// DELETE /api/invoices/:id
router.delete('/:id', async (req, res) => {
  try {
    await Invoice.deleteOne({ userId: req.userId, clientInvoiceId: req.params.id });
    res.json({ deleted: true });
  } catch (e) {
    res.status(500).json({ error: 'Could not delete invoice' });
  }
});

function toClientJson(inv) {
  return {
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
    lastReminderAt: inv.lastReminderAt,
    rentalStartDate: inv.rentalStartDate,
    rentalEndDate: inv.rentalEndDate,
  };
}

module.exports = router;
