# AC Rental Invoice App (Flutter)

A black & white GST invoice app built for an AC rental business in Tiruppur.
Everything (logo, company details, bank details, signature) is entered
manually in **Settings** — no auto-fetch, no third-party invoice format.

## Screens

- **Splash** — a short animated intro (fade + scale logo) shown for about
  1.5 seconds when the app opens.
- **Login / Register** — shown on first launch. Register now collects
  **Name, Phone, Email, Password**. You can also tap "Continue without an
  account" to use the app fully offline (cloud backup just won't run until
  you're signed in).
- **Home** — list of all invoices, totals (Billed / Received / Pending), tap
  "New Invoice" to create one.
- **Clients** — add / edit / delete clients (swipe left to delete).
- **Settings** — account (sync/logout, admin dashboard if you're an admin),
  company details, upload logo, draw or upload your **signature**, bank
  details, terms & conditions.

## Creating an invoice

1. From Home, tap **New Invoice**.
2. Pick an existing client or tap the person-add icon to create one inline.
3. Invoice No. and Date are pre-filled (editable). Set the **Rental Period
   From / To** dates for the AC units being billed.
4. Add item rows: **Item, Unit, Qty, Price, IGST %** — Amount, IGST amount and
   Total are calculated live under each row (Qty × Price = Amount, then IGST
   is applied on top), e.g. `10 Ton, Qty 10, Price 2000 → Amount 20,000`.
5. Tap **Add Row** for more services/items.
6. Enter **Received Amount** — Balance is calculated automatically.
7. Tap **Save & Preview Invoice** to generate the PDF.

## Invoice PDF layout

Built with the `pdf` package as a single grid (rows & columns only, no
floating "boxes"):

- Logo (left) / Company name, address, GSTIN (right)
- Bill To (with client GSTIN) / Invoice No., Date & Rental Period
- Item table: #, Item, Unit, Qty, Price/Unit, Amount, **IGST %** (header),
  **IGST Amt** (its own column), Total
- Bank details (incl. Branch) / Sub Total, IGST Total, Total, Received, Balance
- Invoice Amount in Words (auto-generated, Indian numbering)
- Terms & Conditions / Authorised Signatory (your uploaded signature image)

From the invoice view you can **Share** (system share sheet — WhatsApp,
email, etc.), **Download** (saves the PDF into the app's `Invoices` folder),
**Edit**, or **Delete** the invoice.

## Logo & signature

Both the logo and signature tiles in Settings show a small **✕** button once
an image is set, so you can clear and re-upload either one at any time.

For the signature specifically, tapping the tile now offers a choice:

- **Write on White Board** — draw your signature with your finger right on
  the phone screen (a blank canvas with Clear/Save), or
- **Upload Image** — pick an existing signature photo/scan from your gallery.

Either way, the result is saved and reused automatically on every invoice.

## Collecting pending payments (reminders)

Reminders are fully in-app — nothing opens WhatsApp or SMS, so this works
the same whether you're running on a laptop, emulator, or a real phone.

- On the **Home** screen, any invoice with a balance due shows a bell icon —
  tap it to open a dialog with a ready-made reminder message for that client
  (invoice no., date, total, and the pending balance).
- On the **Invoice view** screen, a full-width **"Remind Client — Balance
  Due Rs. X"** button opens the same dialog.
- Tap **"Copy & Mark Reminded"** to copy the message to your clipboard (to
  paste anywhere you like) and stamp the invoice with today's date — the
  list will then show "Reminded on dd-mm-yy" under that invoice.

## Login, Register & cloud sync

The app works fully **offline** with zero setup — local storage
(`shared_preferences`) is always the source of truth. Logging in is optional
and only adds cloud backup/sync of your invoices, via a small backend of our
own:

```
Flutter  --HTTPS-->  Node.js + Express API  --->  MongoDB Atlas (Cluster0)
```

On first launch you'll see Login/Register. You can:
- **Log In** with an existing account
- **Register** a new one
- **Continue without an account** — skips straight into the app, no cloud
  sync happens until you log in later from Settings → Account

Once signed in, every invoice save/delete is pushed to the server in the
background (silently, best-effort — the app never blocks or fails if the
network is down). Settings → Account also has a **Sync Now** button to pull
invoices back down (useful after reinstalling or switching devices) and a
**Log Out** button.

### Setting this up

1. **Start the backend** — see `server/README.md` for the full walkthrough
   (create your `.env`, `npm install`, `npm start`, and how to point it at
   your existing MongoDB Atlas cluster). It covers both running locally for
   development and deploying for free on Render so it works from anywhere.
2. **Point the app at it** — set `baseUrl` in `lib/config/api_config.dart` to
   wherever your server is running (see comments in that file for the
   emulator/real-device/deployed cases).
3. **Run the app**, register an account, create an invoice, and check your
   server logs / Atlas **Browse Collections** — you should see it land in
   the `invoices` collection within a few seconds.

That's it — the backend handles password hashing, login tokens, and keeping
each user's invoices separate, so nothing sensitive ever touches the Flutter
app directly except the login token.

## Admin Dashboard

Any user whose email is listed in the server's `ADMIN_EMAILS` (see
`server/.env.example`) automatically becomes an admin when they register.
Admins get an extra **"Admin Dashboard"** button in Settings → Account,
showing:

- **Users tab** — every registered user (name, phone, email, joined date).
  Tap the **⋮** menu on any user to **Make Admin / Remove Admin**, or
  **Delete User** (permanently removes that account and every invoice they
  created). An admin can't do either to their own account from here.
- **All Invoices tab** — every invoice from every user, newest first, each
  showing who created it, the total, and the pending balance. **Tap any
  invoice to open its full detail** — client name/phone/GSTIN/address,
  rental period, every line item, and the amount breakdown. This works even
  though the invoice belongs to a different user's device, because a
  snapshot of the client's details is saved alongside the invoice when it's
  first created.

To promote a user who already registered *before* you set `ADMIN_EMAILS`,
run from inside `server/`:
```bash
node scripts/setAdmin.js someone@example.com
```

Regular users never see the Admin Dashboard entry or can call the
`/api/admin/*` routes — the server checks the role embedded in their login
token and returns 403 otherwise.

### Regular users only ever see their own invoices

- Every `/api/invoices/*` request is filtered server-side by the logged-in
  user's ID, decoded from their token — there's no way for one regular
  user's requests to touch another user's invoices, even by guessing IDs.
- On the device itself: logging out clears the locally cached invoice list,
  and logging in immediately re-syncs down just that user's own invoices.
  This means if two different staff accounts log in on the same shared
  phone, neither ever sees a leftover trace of the other's invoices.
- Only the Admin Dashboard (above) is allowed to see across all users, and
  only for accounts with the `admin` role.

## Platform permissions (needed for logo/signature upload)

**iOS** — add to `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to select your company logo and signature image</string>
```

**Android** — no manifest change is normally required (the plugin uses the
system photo picker on modern Android versions).

## Setup

If this is the first time you're using these files (no `android`/`ios`
folders yet), scaffold the platform projects first, then drop this `lib`
folder and `pubspec.yaml` in on top:

```bash
flutter create .
flutter pub get
flutter run
```

If you already have a Flutter project set up, just copy `lib/` and
`pubspec.yaml` in, then:

```bash
flutter pub get
flutter run
```

### Dependencies used

- `shared_preferences` — local storage for clients, invoices, settings
- `pdf` + `printing` — PDF generation, preview, share/print
- `image_picker` — pick logo & signature images
- `path_provider` — persist uploaded images and save downloaded PDFs
- `intl` — date and currency formatting
- `uuid` — unique IDs for clients/invoices
- `http` — talks to our Node/Express backend (login/register + invoice sync)

### Notes

- All data is stored locally on the device (no backend/server). If you want
  invoices to sync across devices later, swap `StorageService` for a
  Firestore/SQLite-backed implementation — the rest of the app is unaffected
  since every screen only talks to `StorageService`.
- IGST defaults to 18% per row but is editable per item (e.g. for non-taxable
  items you can set it to 0).
- Currency formatting assumes INR (₹ shown as "Rs." in the PDF to avoid font
  issues with the ₹ glyph in some PDF viewers — swap for `PdfColors`/a Unicode
  font in `pdf_service.dart` if you'd like the ₹ symbol instead).
