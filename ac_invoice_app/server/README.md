# AC Invoice API

A small Node.js + Express + MongoDB backend for the Flutter AC Rental
Invoice app. Handles:

- `POST /api/auth/register` — create an account
- `POST /api/auth/login` — log in, returns a JWT token
- `GET /api/invoices` — list the logged-in user's invoices
- `PUT /api/invoices/:id` — create/update an invoice
- `DELETE /api/invoices/:id` — delete an invoice

All `/api/invoices/*` routes require `Authorization: Bearer <token>`.

## 1. Set up your `.env`

```bash
cd server
cp .env.example .env
```

Open `.env` and fill in:

- **`MONGODB_URI`** — from Atlas: **Database → Connect → Drivers**, copy the
  connection string, replace `<username>`/`<password>` with your database
  user's credentials, and add a database name before the `?`, e.g.:
  ```
  mongodb+srv://myuser:mypassword@cluster0.vlwqn2j.mongodb.net/ac_invoice_app?retryWrites=true&w=majority&appName=Cluster0
  ```
  ⚠️ If you previously shared a connection string with someone else (chat,
  email, etc.), rotate that database user's password in Atlas first —
  **Database Access** → edit the user → **Edit Password**.

- **`JWT_SECRET`** — any long random string. Generate one with:
  ```bash
  node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
  ```

## 2. Run it locally

```bash
npm install
npm start
```

You should see:
```
Connected to MongoDB
Server running on port 4000
```

Test it:
```bash
curl http://localhost:4000/
# -> AC Invoice API is running
```

## 3. Point the Flutter app at it

Open `lib/config/api_config.dart` in the Flutter project and set `baseUrl`:

- **Testing on an Android emulator**, your laptop's `localhost` is reachable
  at `10.0.2.2`:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:4000';
  ```
- **Testing on a real phone on the same Wi-Fi**, use your laptop's local IP
  (find it with `ipconfig` on Windows / `ifconfig` on Mac/Linux), e.g.:
  ```dart
  static const String baseUrl = 'http://192.168.1.23:4000';
  ```
- **For a release build / anyone outside your Wi-Fi**, deploy the server
  (step 4) and use that public URL instead.

## 4. Deploy it for free (so your phone can reach it anywhere)

[Render](https://render.com) has a free tier that works well for this:

1. Push the `server/` folder to a GitHub repo (or use Render's "deploy from
   a folder" option if offered).
2. On Render: **New → Web Service** → connect your repo.
   - **Root Directory:** `server`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
3. Under **Environment**, add `MONGODB_URI` and `JWT_SECRET` (same values as
   your local `.env`).
4. Deploy. Render gives you a URL like `https://ac-invoice-api.onrender.com`
   — put that in `lib/config/api_config.dart` as `baseUrl`.

(Free-tier Render services sleep after inactivity and take a few seconds to
wake up on the first request — fine for a small business app like this.)

## Security notes

- Passwords are hashed with bcrypt before being stored — never stored in
  plain text.
- Every invoice route checks the JWT and only touches that user's data.
- Don't commit `.env` — it's already in `.gitignore`.
