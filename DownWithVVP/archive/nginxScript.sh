#!/bin/bash

# Переменные
VAR_DIR="/home/$USER/nginx"
VAR_DIR_NJS="/home/$USER/njs"
VAR_REP="https://github.com/nginx/nginx.git"
VAR_REP_NJS="https://github.com/nginx/njs"

PREFIX_NGINX="/usr/local/nginx"
SBIN_NGINX="/usr/sbin/nginx"
CONF_NGINX="/etc/nginx"
PID_NGINX="/var/run"
LOG_NGINX="/var/log/nginx"


# Debug

set -x
set -e


# Update and installing dependencies

sudo apt-get update

sudo apt-get install -y gcc make
sudo apt-get install -y libpcre3-dev zlib1g-dev
sudo apt-get install -y libssl-dev


# git download

if command -v git &> /dev/null; then
    echo "Git установлен. Версия: $(git --version)"
else
    sudo apt-get install -y git
fi


# Folder create and permissions

echo "Создаю директории и настраиваю права..."
sudo mkdir -p /var/log/nginx
sudo mkdir -p /var/cache/nginx
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
sudo mkdir -p /var/www/html

# Создаем пользователя nginx если его нет
if ! grep -q "nginx" /etc/passwd; then
    sudo useradd -r -s /sbin/nologin nginx
fi

# Download repository

if [ ! -d "$VAR_DIR" ]; then
    echo "Клонируем репозиторий nginx"
    git clone $VAR_REP "$VAR_DIR"
else
    echo "Репозиторий уже существует"
fi

if [ ! -d "$VAR_DIR_NJS" ]; then
    echo "Клонируем репозиторий njs"
    git clone $VAR_REP_NJS "$VAR_DIR_NJS"
else
    echo "Репозиторий уже существует"
fi


# Configure
echo "Конфигурирую..."
cd "$VAR_DIR"

# Обновляем пути для правильной работы с systemd
./auto/configure \
  --prefix="$PREFIX_NGINX" \
  --sbin-path="$SBIN_NGINX" \
  --conf-path="$CONF_NGINX/nginx.conf" \
  --pid-path="$PID_NGINX/nginx/nginx.pid" \
  --error-log-path="$LOG_NGINX/error.log" \
  --http-log-path="$LOG_NGINX/access.log" \
  --with-pcre \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_auth_request_module \
  --with-http_gunzip_module


# Make

echo "Собираю..."
sudo make
echo "Устанавливаю..."
sudo make install

# Копируем конфигурационные файлы если их нет
if [ ! -f "/etc/nginx/nginx.conf" ]; then
    echo "Создаю базовый конфиг nginx..."
    sudo cp "$VAR_DIR/conf/nginx.conf" /etc/nginx/
    sudo sed -i 's#logs/error.log#/var/log/nginx/error.log#g' /etc/nginx/nginx.conf
    sudo sed -i 's#logs/access.log#/var/log/nginx/access.log#g' /etc/nginx/nginx.conf
    sudo sed -i 's#logs/nginx.pid#/var/run/nginx/nginx.pid#g' /etc/nginx/nginx.conf
fi


# Устанавливаем правильные права
sudo chown -R nginx:nginx /var/log/nginx
sudo chown -R nginx:nginx /var/cache/nginx
sudo chown -R nginx:nginx /var/www/html
sudo chmod 755 /var/log/nginx
sudo chmod 755 /var/cache/nginx
sudo chown -R nginx:nginx $CONF_NGINX

# Создаем pid директорию с правильными правами
sudo mkdir -p /var/run/nginx
sudo chown -R nginx:nginx /var/run/nginx

# Systemd create

function systemd_create() {
    local pit_file="$1"
    local sbin_file="$2"
    local conf_file="$3"

    cat << EOF | sudo tee /etc/systemd/system/nginx.service > /dev/null
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs
After=network.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=${pit_file}/nginx/nginx.pid
ExecStartPre=${sbin_file} -t -c ${conf_file}/nginx.conf
ExecStart=${sbin_file} -c ${conf_file}/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID
TimeoutStopSec=5
KillMode=mixed
User=nginx
Group=nginx
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
}

systemd_create "$PID_NGINX" "$SBIN_NGINX" "$CONF_NGINX"

# Создаем тестовую HTML страницу
sudo bash -c 'echo "<html><body><h1>NGINX работает!</h1></body></html>" > /var/www/html/index.html'
sudo chown nginx:nginx /var/www/html/index.html

# Включаем и запускаем nginx
sudo systemctl daemon-reload
sudo systemctl enable nginx

echo "Проверяем конфигурацию..."
sudo /usr/sbin/nginx -t

echo "Запускаем nginx..."
sudo systemctl start nginx

sleep 2

echo "Проверяем статус..."
sudo systemctl status nginx --no-pager

echo "Проверяем доступность через curl..."
curl -I http://localhost || echo "Curl не смог подключиться, проверьте логи"

echo "Установка завершена!"


# Debug

set +x