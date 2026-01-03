#!/bin/bash
set -e

DOMAIN="a.forsalebot.top"
EMAIL="your@email.com"

echo "▶ Установка Marzban"
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

echo "▶ Установка пакетов"
apt update
apt install -y cron socat nano curl

echo "▶ Генерация SHORT_ID и KEY"
SHORT_ID=$(openssl rand -hex 8)
KEY=$(docker exec marzban-marzban-1 xray x25519 | grep Private | awk '{print $3}')

echo "▶ Обновление .env"
cat > /opt/marzban/.env <<EOF
UVICORN_PORT=443
UVICORN_SSL_CERTFILE="/var/lib/marzban/certs/fullchain.pem"
UVICORN_SSL_KEYFILE="/var/lib/marzban/certs/key.pem"
XRAY_SUBSCRIPTION_URL_PREFIX="https://${DOMAIN}"
SHORT_ID=${SHORT_ID}
KEY=${KEY}
EOF

echo "▶ Установка acme.sh"
curl https://get.acme.sh | sh -s email=${EMAIL}

mkdir -p /var/lib/marzban/certs

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue --standalone -d ${DOMAIN} \
  --key-file /var/lib/marzban/certs/key.pem \
  --fullchain-file /var/lib/marzban/certs/fullchain.pem

echo "▶ Перезапуск Marzban"
marzban restart

echo "✅ Готово!"
echo "SHORT_ID: ${SHORT_ID}"
echo "KEY: ${KEY}"
