# AfriCare Health Gambia — Deployment Guide
# From zero to live on Vercel in 8 steps

---

## STEP 1 — Upload this folder to GitHub

1. Go to github.com and sign in (create a free account if needed)
2. Click the green "New" button to create a new repository
3. Name it: `africare-health-gambia`
4. Set it to **Private**
5. Click "Create repository"
6. Download and install GitHub Desktop: desktop.github.com
7. Open GitHub Desktop → File → Add Local Repository
8. Navigate to this folder (africare-deploy) and add it
9. Click "Publish repository" to push it to GitHub

---

## STEP 2 — Create your Supabase database

1. Go to supabase.com → Sign up for a free account
2. Click "New project"
   - Name: `africare-health`
   - Database password: create a strong password and SAVE IT
   - Region: Choose "EU West" (closest to Gambia)
3. Wait for the project to finish creating (~2 minutes)
4. Go to: SQL Editor (left sidebar) → New query
5. Open the file `SUPABASE_SCHEMA.sql` from this folder
6. Copy the ENTIRE contents and paste into the SQL editor
7. Click "Run" (green button)
8. You should see "Success. No rows returned"

**Get your Supabase keys:**
- Go to Settings → API (left sidebar)
- Copy these three values — you need them in Step 5:
  - `Project URL` (looks like: https://xxxxx.supabase.co)
  - `anon public` key
  - `service_role secret` key (click the eye icon to reveal)

---

## STEP 3 — Create your Flutterwave account

1. Go to flutterwave.com → Sign up
2. Complete business verification (use AfriCare Health Gambia as business name)
3. Go to Dashboard → Settings → API Keys
4. Copy your:
   - Public key (starts with FLWPUBK-)
   - Secret key (starts with FLWSECK-)
   - Encryption key
5. Go to Settings → Webhooks
6. Add webhook URL: `https://your-vercel-domain.vercel.app/api/webhooks/flutterwave`
   (You'll get this URL in Step 6 — come back and add it then)

---

## STEP 4 — Create your 360Dialog (WhatsApp) account

1. Go to hub.360dialog.com → Sign up
2. Connect your WhatsApp Business account
   - You need a phone number that is NOT already on personal WhatsApp
   - Buy a Gambia (+220) SIM for this purpose
3. Note your API key from the dashboard
4. Go to Configuration → Webhooks
5. Add webhook URL: `https://your-vercel-domain.vercel.app/api/webhooks/whatsapp`
   (Come back and add this after Step 6)

**Submit WhatsApp message templates:**
Go to 360Dialog → Message Templates → New Template
Create these templates (copy the names exactly):
- `booking_confirmation` — body: "Hi {{1}}, your AfriCare consultation with {{2}} ({{3}}) is confirmed for {{4}}. Reference: {{5}}. Reply CANCEL to cancel or HELP for support."
- `instant_doctor_request` — body: "AfriCare {{1}} REQUEST — Patient: {{2}} ({{3}}) is waiting. Reference: {{4}}. Reply YES to accept or NO to decline. You have 60 seconds."
- `appointment_reminder` — body: "Hi {{1}}, reminder: your AfriCare consultation with {{2}} is tomorrow at {{3}}."
- `lab_referral` — body: "Hi {{1}}, your doctor has referred you to {{2}} for: {{3}}. Show referral code {{4}} at the lab. Lab contact: {{5}}."
- `consultation_complete` — body: "Hi {{1}}, your consultation with {{2}} is complete. Reference: {{3}}. Please rate your experience by replying 1-5."
- `doctor_payout` — body: "Hi {{1}}, your AfriCare earnings of {{2}} are being processed. Reference: {{3}}. Payment will arrive within 24 hours via mobile money."
- `doctor_approved` — body: "Welcome to AfriCare Health Gambia, {{1}}! Your profile is now live. Reply AVAILABLE when you are ready to accept consultations, and UNAVAILABLE when you are done."

Approval typically takes 24–48 hours.

---

## STEP 5 — Set up your environment variables

1. Make a copy of the file `.env.example` in this folder
2. Rename the copy to `.env.local`
3. Fill in every value using what you collected in Steps 2–4:

```
NEXT_PUBLIC_APP_URL=https://your-domain.vercel.app
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-...
FLUTTERWAVE_SECRET_KEY=FLWSECK-...
FLUTTERWAVE_ENCRYPTION_KEY=...
NEXT_PUBLIC_FLUTTERWAVE_PUBLIC_KEY=FLWPUBK-...
DIALOG_API_KEY=your-360dialog-key
DIALOG_PARTNER_ID=your-partner-id
WHATSAPP_PHONE_NUMBER_ID=your-phone-number-id
WEBHOOK_SECRET=any-long-random-string-you-make-up
```

Keep `.env.local` private — never commit it to GitHub.

---

## STEP 6 — Deploy to Vercel

1. Go to vercel.com → Sign up with your GitHub account
2. Click "Add New Project"
3. Find and select `africare-health-gambia` from your GitHub repositories
4. Vercel will auto-detect it as a Next.js project
5. Click "Environment Variables" and add every variable from Step 5
   - Click "Add" for each one, paste the name and value
6. Click "Deploy"
7. Wait ~3 minutes for the build to complete
8. Your site is now live at: `https://africare-health-gambia.vercel.app`

**Copy your Vercel URL and go back to:**
- Flutterwave (Step 3) → add webhook URL
- 360Dialog (Step 4) → add webhook URL

---

## STEP 7 — Test everything

Run through this checklist before going live:

**Website**
- [ ] Homepage loads at your Vercel URL
- [ ] All 5 tabs work (Home, Instant, Doctors, Plans, Home services)
- [ ] Doctors list shows the 6 seed doctors from the database
- [ ] "Online now" filter works

**Payments**
- [ ] Use a Flutterwave test card to make a test booking
- [ ] Check that the payment webhook fires (Flutterwave dashboard → Webhook logs)
- [ ] Check Supabase → Table Editor → bookings to see the booking recorded

**WhatsApp**
- [ ] Send a message to your AfriCare WhatsApp number
- [ ] Reply HELP — you should get the help menu back
- [ ] Confirm booking confirmation template sends after a test booking

**Revenue split**
- [ ] After a test payment, check Supabase → revenue_splits table
- [ ] Confirm africare_share + doctor_share = total_amount

---

## STEP 8 — Go live checklist

Before announcing to patients and doctors:

- [ ] Delete the seed doctor data from Supabase (or mark them inactive)
- [ ] Add your real doctor profiles via Supabase → Table Editor → doctors
- [ ] Set `is_approved = true` for each verified doctor
- [ ] Update NEXT_PUBLIC_APP_URL to your real domain if you have one
- [ ] Set up a custom domain in Vercel → Settings → Domains
- [ ] Submit WhatsApp templates and wait for approval (Step 4)
- [ ] Test a real end-to-end booking with a real patient and doctor
- [ ] Add AfriCare logo as /public/logo.png (for Flutterwave payment page)

---

## Support & troubleshooting

**Build fails on Vercel:**
- Check all environment variables are added in Vercel → Settings → Environment Variables
- Check the build logs for the specific error

**WhatsApp messages not sending:**
- Confirm DIALOG_API_KEY is correct
- Confirm the phone number format — Gambia numbers need country code: 2207000000
- Check 360Dialog dashboard → Message logs

**Payments not working:**
- Use Flutterwave test mode first (test keys, not live keys)
- Check webhook URL is exactly: https://your-domain.vercel.app/api/webhooks/flutterwave
- Check Flutterwave dashboard → Webhook logs for errors

**Database errors:**
- Go to Supabase → Logs → API logs to see what's failing
- Make sure you ran the full SUPABASE_SCHEMA.sql without errors

---

## File structure reference

```
africare-deploy/
├── pages/
│   ├── index.js                        ← Main patient website
│   ├── _app.js                         ← App wrapper
│   ├── _document.js                    ← HTML head
│   ├── payment/
│   │   └── callback.js                 ← After Flutterwave payment
│   └── api/
│       ├── bookings/
│       │   └── create.js               ← POST: create a booking
│       ├── doctors/
│       │   └── index.js                ← GET: list doctors
│       └── webhooks/
│           ├── flutterwave.js          ← Flutterwave payment events
│           └── whatsapp.js             ← Inbound WhatsApp messages
├── lib/
│   ├── supabase.js                     ← Database helpers
│   ├── whatsapp.js                     ← WhatsApp notification library
│   └── payments.js                     ← Flutterwave payment library
├── styles/
│   └── globals.css                     ← Global styles
├── SUPABASE_SCHEMA.sql                 ← Run this in Supabase SQL editor
├── .env.example                        ← Copy to .env.local and fill in
├── next.config.js
└── package.json
```
