# AHS Sources

Daily sales reporting for multiple companies and branches. Branches report sales (typed in or uploaded from Excel/CSV); management gets an automatic daily report on screen, as Excel and PDF, and by email. English and Arabic (right-to-left).

## What it does

- **Branch logins.** A branch user can only enter, upload and see their own branch. Managers see every company and branch. Admins also manage setup.
- **Enter sales.** Gross sales, returns, cash, card, other, transactions, notes. Re-submitting a date replaces the earlier entry.
- **Upload.** Excel (.xlsx) or CSV with columns `branch_code, date, gross, returns, cash, card, other, transactions, note`. A template is downloadable in the app.
- **Daily report.** Group, company and branch totals; target %, comparison with the same weekday last week, month to date, average ticket, 14-day trend, 7-day submission tracker. Download as Excel or PDF.
- **Alerts.** Missing report, below target (default under 80%), drop vs last week (default over 20%), and payments that do not equal net sales. Thresholds are editable in Setup.
- **Email.** Every morning (default 07:00) the previous day's report goes to every admin and manager with an email address, with Excel and PDF attached. Every evening (default 21:30) branch users whose branch has not reported get a reminder. Times, and on/off, are editable in Setup.

## Run it (Docker)

```bash
cp .env.example .env          # then edit: set SECRET_KEY and, for email, the SMTP_* values
docker compose up -d --build
docker compose exec ahs flask create-admin      # asks for username and password
```

Open `http://<server>:8000`, sign in, then in **Setup** add companies, branches (each with a unique branch code and daily target) and users.

To try it with sample data first (only works on an empty database):

```bash
docker compose exec ahs flask seed-demo     # prints demo logins once
```

All data lives in the `ahs-data` Docker volume (a single SQLite file at `/data/ahs.sqlite`). Back it up by copying that file while the app is idle, or with `sqlite3 /data/ahs.sqlite ".backup backup.sqlite"`.

## Backups

- **Download backup** (Setup → Settings, admins only) gives you a complete copy of the database. Download one regularly and keep it somewhere other than the server.
- The server also saves a backup every night at 02:15 into `/data/backups` and keeps the last 14. These sit on the same disk, so they protect against mistakes, not against losing the disk.
- **Restore** (or move to another server): stop the app, replace `/data/ahs.sqlite` with the backup file (rename it to `ahs.sqlite`), and start the app again. With Docker: `docker compose stop`, copy the file into the `ahs-data` volume, `docker compose start`.

## Run it without Docker

```bash
pip install -r requirements.txt     # PDF export also needs pango and Noto fonts installed on the system
export SECRET_KEY=... DATABASE_PATH=./data/ahs.sqlite
flask --app app create-admin
gunicorn --workers 1 --threads 4 --bind 0.0.0.0:8000 wsgi:app
```

## Production notes

- **Put it behind HTTPS** (a reverse proxy such as nginx, Caddy or Traefik, or your host's load balancer) and set `COOKIE_SECURE=1`. Without HTTPS, passwords travel unencrypted.
- **Keep one worker.** The same process runs the email scheduler; more workers would send duplicate emails. One worker with threads handles dozens of branches comfortably.
- **Set `SECRET_KEY`.** If it is missing, a random key is generated at each start and everyone is logged out on restart.
- **Email** needs an SMTP account (Microsoft 365, Google Workspace, or your mail provider). In Setup, use *Send report email now* to test it.
- There is no login rate limiting or password reset email yet. An admin resets passwords in Setup, and `flask create-admin` can reset an admin's password if everyone is locked out.
- Report dates and schedules use `TIMEZONE` (default Asia/Riyadh).

## Develop

```bash
pip install -r requirements.txt pytest
python -m pytest tests
```

Layout: `app/views.py` (routes and CLI), `app/reports.py` (totals and alert rules), `app/exports.py` (Excel, PDF helpers, upload parsing), `app/mailer.py` (email and scheduled jobs), `app/i18n.py` (all English/Arabic text), `app/templates/`.
