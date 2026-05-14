# Raspberry Pi Deployment

This deploys the Karate App backend as:

```text
nginx :80/:443 -> gunicorn 127.0.0.1:5042 -> Flask app
```

Use Raspberry Pi OS Lite 64-bit.

## 1. Install Packages

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y git python3 python3-venv python3-pip nginx certbot python3-certbot-nginx
```

## 2. Install App

Create a dedicated service user without sudo/login shell:

```bash
sudo adduser --system --group --home /opt/karate-app --shell /usr/sbin/nologin karateapp
```

Clone or copy this repository to:

```bash
/opt/karate-app
```

Example:

```bash
sudo mkdir -p /opt/karate-app
sudo chown -R "$USER:$USER" /opt/karate-app
cd /opt/karate-app
git clone https://github.com/YOUR_USER/YOUR_REPO.git .
```

Create the Python environment:

```bash
cd /opt/karate-app/backend/api
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

After installing the virtual environment, give the app files to the service user:

```bash
sudo chown -R karateapp:karateapp /opt/karate-app
```

## 3. Cache Directory

```bash
sudo mkdir -p /var/lib/karate-app-backend
sudo chown -R karateapp:karateapp /var/lib/karate-app-backend
```

## 4. Environment File

```bash
sudo cp /opt/karate-app/backend/api/deploy/systemd/karate-app-backend.env.example /etc/karate-app-backend.env
sudo nano /etc/karate-app-backend.env
```

Set:

```text
LOCATIONIQ_API_KEY=your-locationiq-key
KARATEAPP_ADMIN_USERNAME=admin
KARATEAPP_ADMIN_PASSWORD=your-long-random-admin-password
KARATEAPP_BACKEND_DATABASE=/var/lib/karate-app-backend/geocode_cache.sqlite3
KARATEAPP_DATA_CACHE_TTL_SECONDS=600
PORT=5042
```

The admin password protects:

```text
/
/stats
/geocode/status
```

Generate a password with:

```bash
openssl rand -base64 32
```

## 5. systemd Service

Install and start:

```bash
sudo cp /opt/karate-app/backend/api/deploy/systemd/karate-app-backend.service /etc/systemd/system/karate-app-backend.service
sudo systemctl daemon-reload
sudo systemctl enable --now karate-app-backend
sudo systemctl status karate-app-backend
```

Test locally:

```bash
curl "http://127.0.0.1:5042/health"
curl "http://127.0.0.1:5042/geocode?q=Berlin"
```

Logs:

```bash
journalctl -u karate-app-backend -f
```

## 6. nginx

Copy config:

```bash
sudo cp /opt/karate-app/backend/api/deploy/nginx/karate-app-backend.conf /etc/nginx/sites-available/karate-app-backend
sudo nano /etc/nginx/sites-available/karate-app-backend
```

Replace:

```text
your-ddns-host.example
```

with your real No-IP/DDNS hostname.

Enable:

```bash
sudo ln -s /etc/nginx/sites-available/karate-app-backend /etc/nginx/sites-enabled/karate-app-backend
sudo nginx -t
sudo systemctl reload nginx
```

## 7. FritzBox Port Forwarding

Forward to your Raspberry Pi:

```text
TCP 80  -> Pi 80
TCP 443 -> Pi 443
```

## 8. HTTPS

After DDNS and port forwarding work:

```bash
sudo certbot --nginx -d your-ddns-host.example
```

Test:

```bash
curl "https://your-ddns-host.example/health"
curl "https://your-ddns-host.example/geocode?q=Berlin"
```

## 9. App Endpoint

In the Qt app set:

```cpp
inline const QString BaseUrl = QStringLiteral("https://your-ddns-host.example");
```

in:

```text
src/services/BackendConfig.hpp
```
