#!/bin/bash
set -e

# --- Обновление и установка базовых пакетов ---
echo "▶ Обновление системы"
apt update -y
apt install -y cron socat nano curl docker.io

# Включаем и запускаем docker
systemctl enable --now docker

# --- Установка Marzban ---
echo "▶ Установка Marzban"
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

# --- Создание .env ---
echo "▶ Создание файла .env"
mkdir -p /opt/marzban
cat > /opt/marzban/.env <<EOF
UVICORN_PORT=443
UVICORN_SSL_CERTFILE="/var/lib/marzban/certs/fullchain.pem"
UVICORN_SSL_KEYFILE="/var/lib/marzban/certs/key.pem"
XRAY_SUBSCRIPTION_URL_PREFIX="https://a.forsalebot.top"
EOF

# --- Генерация рандомной почты для acme.sh ---
RAND_EMAIL="$(openssl rand -hex 6)@gmail.com"
echo "▶ Используется email для acme.sh: ${RAND_EMAIL}"

# --- Установка acme.sh и выдача сертификата ---
echo "▶ Установка acme.sh"
curl https://get.acme.sh | sh -s email=${RAND_EMAIL}

mkdir -p /var/lib/marzban/certs

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue --standalone -d a.forsalebot.top \
  --key-file /var/lib/marzban/certs/key.pem \
  --fullchain-file /var/lib/marzban/certs/fullchain.pem

# --- Перезапуск Marzban ---
echo "▶ Перезапуск Marzban"
marzban restart

echo ""
echo "=============================="
echo "✅ УСТАНОВКА ЗАВЕРШЕНА"
echo "EMAIL (acme.sh): ${RAND_EMAIL}"
echo "=============================="

