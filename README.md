# AIScope — AI Solutions Directory

## Quick Start

### 1. Supabase Setup (15 minutes)

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** → paste the contents of `supabase/schema.sql` → Run
3. Go to **Storage** → create two public buckets: `logos` and `portfolio`
4. Go to **Settings → API** → copy your `Project URL` and `anon public` key

### 2. Configure the App

Open `assets/js/config.js` and replace:

```js
const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';
```

### 3. Deploy to GitHub Pages

1. Push this folder to a GitHub repository
2. Go to **Settings → Pages → Source**: Deploy from branch `main`, folder `/` (root)
3. Your site will be live at `https://yourusername.github.io/repo-name`

> **Important:** Update all internal links to include your base path if deploying to a subdirectory.

---

## File Structure

```
/
├── index.html              Homepage
├── search.html             Search & filter results
├── listing.html            Company profile page (?slug=company-slug)
├── auth/
│   ├── login.html          Sign in
│   └── register.html       Create account
├── dashboard/
│   ├── index.html          Dashboard overview
│   ├── edit.html           Create/edit listing
│   └── portfolio.html      Manage portfolio images
├── assets/
│   ├── css/main.css        Full design system
│   └── js/
│       ├── config.js       Supabase config + constants
│       ├── app.js          Shared utilities + card renderer
│       └── auth.js         Auth state + helpers
└── supabase/
    └── schema.sql          Full PostgreSQL schema
```

---

## Storage Buckets

Create these in Supabase Dashboard → Storage:

| Bucket      | Public | Used For                    |
|-------------|--------|-----------------------------|
| `logos`     | ✓      | Company logos               |
| `portfolio` | ✓      | Portfolio/case study images |

---

## Adding Your First Listings (Manual Seed)

The fastest way to seed the directory:

1. Sign up via `/auth/register.html`
2. Go to your Supabase dashboard → Table Editor → `listings`
3. Insert rows directly for your first 20–50 companies
4. Set `status = 'published'` and `is_claimed = false`
5. Once companies claim their profiles, `is_claimed` becomes `true`

Or use the bulk insert via SQL:

```sql
INSERT INTO listings (owner_id, name, slug, listing_type, tagline, website_url, status, hq_country)
VALUES
  ('<your-user-id>', 'Acme AI Agency', 'acme-ai-agency', 'agency', 'AI workflow automation for SMBs', 'https://acmeai.com', 'published', 'United States'),
  -- add more rows...
;
```

---

## Outreach Email Template

When you've manually added a company, send this:

> Subject: We listed [Company Name] on AIScope
>
> Hey [Name], we added [Company Name] to our AI solutions directory — you can see the listing here: [URL].
>
> We pulled the info from your website so a few details might be off. Takes about 5 minutes to claim and correct. It's free.
>
> [Claim Your Profile →]

---

## Environment Variables (for CI/CD)

If you automate deployment, set these as GitHub Secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Then use a build step to inject them into `config.js`.

---

## Future Roadmap

- **Phase 2:** Reviews + ratings + verified badges
- **Phase 3:** Stripe-powered featured/sponsored listings
- **Phase 4:** Lead inbox for listing owners
- **Phase 5:** RFP system + AI-powered matching

---

## Tech Stack

- **Frontend:** Vanilla HTML, CSS, JavaScript (no build step)
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Hosting:** GitHub Pages
- **Search:** PostgreSQL full-text search (tsvector + GIN index)
- **Auth:** Supabase Auth (email/password + magic link)
