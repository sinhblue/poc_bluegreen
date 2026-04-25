#!/bin/bash
set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install Python and dependencies
apt-get install -y python3 python3-pip python3-venv git postgresql-client awscli jq

# Clone repository (adjust URL as needed)
cd /opt
git clone https://github.com/sinhblue/poc_bluegreen.git
cd poc_bluegreen

# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Fetch DB password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id poc-bluegreen-aurora-password-20260424164309557300000001 --query SecretString --output text | jq -r '.password')

# Wait until the Aurora endpoint is ready
wait_for_db() {
  local host="$1"
  local port="$2"
  if [ -z "$port" ]; then port="5432"; fi
  local user="$3"
  local max_attempts=30
  local delay=10
  local attempt=1

  echo "Waiting for database at $host:$port..."
  until PGPASSWORD="$DB_PASSWORD" pg_isready -h "$host" -p "$port" -U "$user" >/dev/null 2>&1; do
    if [ "$attempt" -ge "$max_attempts" ]; then
      echo "ERROR: database did not become ready after $((max_attempts * delay)) seconds"
      exit 1
    fi
    printf '.'
    sleep "$delay"
    attempt=$((attempt + 1))
  done
  echo -e "\nDatabase is ready."
}

wait_for_db "${db_endpoint}" 5432 "${db_user}"

# Create .env file with database connection
cat > .env <<EOF
DATABASE_URL=postgresql://${db_user}:$DB_PASSWORD@${db_endpoint}:5432/${db_name}
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
EOF

# Run database initialization
python3 populate.py

# Create systemd service for Flask app
cat > /etc/systemd/system/poc-bluegreen.service <<EOF
[Unit]
Description=POC Blue/Green Flask Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/poc_bluegreen
Environment="PATH=/opt/poc_bluegreen/.venv/bin"
ExecStart=/opt/poc_bluegreen/.venv/bin/python app.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable poc-bluegreen
systemctl start poc-bluegreen

echo "POC Blue/Green setup complete!"
