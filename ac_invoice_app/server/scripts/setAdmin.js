/// Promotes an existing user to admin, for cases where they registered
/// before you added their email to ADMIN_EMAILS.
///
/// Usage (from inside server/):
///   node scripts/setAdmin.js someone@example.com
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error('Usage: node scripts/setAdmin.js <email>');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const user = await User.findOneAndUpdate(
    { email: email.toLowerCase() },
    { role: 'admin' },
    { new: true }
  );

  if (!user) {
    console.error(`No user found with email ${email}`);
  } else {
    console.log(`${user.email} is now an admin.`);
  }

  await mongoose.disconnect();
}

main();
