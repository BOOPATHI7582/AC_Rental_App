const mongoose = require('mongoose');

const invoiceItemSchema = new mongoose.Schema(
  {
    itemName: String,
    unit: String,
    quantity: Number,
    price: Number,
    igstPercent: Number,
  },
  { _id: false }
);

const invoiceSchema = new mongoose.Schema(
  {
    // The invoice id generated on the Flutter side (uuid) - kept as the
    // stable identifier so the app and server always agree on which
    // invoice is which.
    clientInvoiceId: { type: String, required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

    invoiceNo: String,
    date: Date,
    clientId: String,
    // Snapshot of the client's details at save time, so an admin can view
    // full invoice details without needing the creator's local client list.
    clientName: String,
    clientPhone: String,
    clientGstin: String,
    clientAddress: String,
    clientState: String,

    items: [invoiceItemSchema],
    receivedAmount: Number,
    notes: String,
    lastReminderAt: Date,
    rentalStartDate: Date,
    rentalEndDate: Date,
  },
  { timestamps: true }
);

invoiceSchema.index({ userId: 1, clientInvoiceId: 1 }, { unique: true });

module.exports = mongoose.model('Invoice', invoiceSchema);
