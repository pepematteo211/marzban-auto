#!/bin/bash
set -e

# -----------------------------
# Настройка
# -----------------------------
DOMAIN="a.forsalebot.top"   # <-- сюда твой домен
EMAIL_PREFIX="$(openssl rand -hex 6)"
RAND_EMAIL="${EMAIL_PREFIX}@gmail.com"

echo "▶ Домен: $DOMAIN"
echo "▶ Email для acme.sh: $RAND_EMAIL"

# -----------------------------
# Обновление системы и установка пакетов
# -----------------------------
echo "▶ Обновление системы и установка зависимостей..."
apt update -y && apt upgrade -y
apt install -y cron socat nano curl docker.io

# Включаем и запускаем Docker
systemctl enable --now docker

# -----------------------------
# Установка Marzban
# -----------------------------
echo "▶ Установка Marzban..."
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

# Проверяем, что директория создана
mkdir -p /opt/marzban

# -----------------------------
# Создание .env
# -----------------------------
echo "▶ Создание файла .env"
cat > /opt/marzban/.env <<EOF
UVICORN_PORT=443
UVICORN_SSL_CERTFILE="/var/lib/marzban/certs/fullchain.pem"
UVICORN_SSL_KEYFILE="/var/lib/marzban/certs/key.pem"
XRAY_SUBSCRIPTION_URL_PREFIX="https://${DOMAIN}"
EOF

# -----------------------------
# Установка acme.sh и выдача сертификата
# -----------------------------
echo "▶ Установка acme.sh"
curl https://get.acme.sh | sh -s email=${RAND_EMAIL}

mkdir -p /var/lib/marzban/certs

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue --standalone -d ${DOMAIN} \
  --key-file /var/lib/marzban/certs/key.pem \
  --fullchain-file /var/lib/marzban/certs/fullchain.pem

# -----------------------------
# Перезапуск Marzban
# -----------------------------
echo "▶ Перезапуск Marzban..."
marzban restart

# -----------------------------
# Завершение
# -----------------------------
echo ""
echo "=============================="
echo "✅ УСТАНОВКА ЗАВЕРШЕНА"
echo "DOMAIN: ${DOMAIN}"
echo "EMAIL (acme.sh): ${RAND_EMAIL}"
echo "=============================="
