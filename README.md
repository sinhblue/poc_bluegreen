# Aurora Blue/Green Upgrade POC

A minimal Flask application for PostgreSQL that simulates an RDS Aurora blue/green upgrade readiness dashboard.

## Features
- 10 tables in PostgreSQL
- Seed script with ~100 records per table
- SQL schema and seed scripts in `sql/schema.sql` and `sql/seed_data.sql`
- API endpoints for DB status, sample rows, upgrade checks, and blue/green switch simulation
- Web UI dashboard for table row counts, readiness checks, and deployment toggle

## Install

1. Create and activate a Python virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Copy the example environment file and configure your Postgres URL:

```powershell
copy .env.example .env
```

4. Update `.env` if needed. Example:

```text
DATABASE_URL=postgresql://postgres:password@localhost:5432/aurora_poc
```

## Run the app

1. Create the schema and seed data:

```powershell
python populate.py
```

   Or use raw SQL scripts with Postgres:

```powershell
psql -d aurora_poc -f sql/schema.sql
psql -d aurora_poc -f sql/seed_data.sql
```

2. Start the Flask app:

```powershell
python app.py
```

3. Open `http://127.0.0.1:5000` in your browser.

## Useful endpoints
- `GET /api/status` — connection status, DB version, row counts
- `POST /api/upgrade/check` — performs readiness checks
- `POST /api/bluegreen/switch` — toggles demo blue/green state
- `GET /tables` — table volume dashboard

## Deploy on EC2

1. SSH into your EC2 instance.
1. Update packages and install Python, venv, git, and PostgreSQL client tools:

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git postgresql-client
```

1. Clone the repository or copy the project files onto the instance:

```bash
git clone <your-repo-url> poc_bluegreen
cd poc_bluegreen
```

1. Create and activate a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

1. Install dependencies:

```bash
pip install -r requirements.txt
```

1. Copy the environment example and configure the database connection:

```bash
cp .env.example .env
```

Edit `.env` and set `DATABASE_URL` for your database. For an RDS/Aurora instance, use your endpoint and credentials, e.g.:

```text
DATABASE_URL=postgresql://username:password@your-aurora-endpoint:5432/poc_bluegreen
```

1. Create the database if using a local Postgres instance:

```bash
psql -U postgres -c "CREATE DATABASE poc_bluegreen;"
```

1. Create schema and seed data:

```bash
python populate.py
```

Or use the SQL scripts directly:

```bash
psql -d poc_bluegreen -f sql/schema.sql
psql -d poc_bluegreen -f sql/seed_data.sql
```

1. Start the Flask app:

```bash
python app.py
```

1. Open the app from your browser using the EC2 public DNS and port 5000, e.g. `http://ec2-public-dns:5000`.

> Make sure your EC2 security group allows inbound traffic on port `5000`, or configure an NGINX reverse proxy on port `80`/`443` and forward to `localhost:5000`.

## Notes for RDS Aurora POC
- Set `DATABASE_URL` to your Aurora writer or reader endpoint.
- Use the API and UI to verify connectivity and table row counts before an upgrade.
- The blue/green switch is simulated in `.bluegreen_state` and helps demonstrate a deployment alias flip.
