# 🔧 X-UI Troubleshooting Guide

Руководство по устранению типичных ошибок X-UI Ultimate Installer.

---

## 📋 Содержание

1. [X-UI не запускается](#x-ui-не-запускается)
2. [Панель не открывается](#панель-не-открывается)
3. [Ошибки инициализации БД](#ошибки-инициализации-бд)
4. [SSL сертификаты](#ssl-сертификаты)
5. [Проблемы с протоколами](#проблемы-с-протоколами)
6. [Nginx ошибки](#nginx-ошибки)
7. [Порты заняты](#порты-заняты)
8. [AppArmor блокирует](#apparmor-блокирует)

---

## ❌ X-UI не запускается

### Симптомы:
```bash
systemctl status x-ui
● x-ui.service - X-UI Panel
   Loaded: loaded
   Active: failed (Result: exit-code)
```

### Диагностика:

```bash
# 1. Проверить логи
journalctl -u x-ui -n 50 --no-pager

# 2. Проверить бинарник
ls -la /usr/local/x-ui/x-ui
file /usr/local/x-ui/x-ui

# 3. Запустить вручную для отладки
cd /usr/local/x-ui
./x-ui
```

### Решения:

**Проблема 1: БД не инициализирована**
```bash
# Создать БД вручную
cd /usr/local/x-ui
timeout 10 ./x-ui
sleep 3
pkill -f x-ui

# Проверить
ls -la x-ui.db
```

**Проблема 2: Неправильная архитектура**
```bash
# Проверить архитектуру
uname -m
file /usr/local/x-ui/x-ui

# Если не совпадает - переустановить
rm -rf /usr/local/x-ui
bash install.sh
```

**Проблема 3: Порт занят**
```bash
# Проверить порт
ss -tlnp | grep :$(cat /root/x-ui-port.txt)

# Убить процесс на порту
fuser -k $(cat /root/x-ui-port.txt)/tcp

# Перезапустить
systemctl restart x-ui
```

**Проблема 4: Права доступа**
```bash
chmod +x /usr/local/x-ui/x-ui
chown -R root:root /usr/local/x-ui
systemctl restart x-ui
```

---

## 🌐 Панель не открывается

### Симптомы:
- `https://domain/path/` возвращает 502 Bad Gateway
- `https://domain/path/` возвращает 404 Not Found
- Соединение отклонено

### Диагностика:

```bash
# 1. Проверить X-UI запущен
systemctl status x-ui

# 2. Проверить Nginx
systemctl status nginx
nginx -t

# 3. Проверить порты
ss -tlnp | grep x-ui
ss -tlnp | grep nginx

# 4. Проверить логи Nginx
tail -f /var/log/nginx/error.log
```

### Решения:

**Проблема 1: X-UI не запущен**
```bash
systemctl start x-ui
systemctl status x-ui
```

**Проблема 2: Nginx не проксирует**
```bash
# Проверить конфигурацию
cat /etc/nginx/sites-available/x-ui.conf

# Должно быть:
# proxy_pass http://127.0.0.1:RANDOM_PORT;

# Перезапустить Nginx
nginx -t && systemctl restart nginx
```

**Проблема 3: Неправильный URI**
```bash
# Проверить URI панели
grep "URI панели" /root/x-ui-credentials.txt

# Правильный URL:
# https://domain/RANDOM_URI/
```

**Проблема 4: UFW блокирует**
```bash
ufw status
ufw allow 443/tcp
ufw allow 80/tcp
ufw reload
```

---

## 💾 Ошибки инициализации БД

### Симптомы:
```
WARN: БД x-ui.db не создана — x-ui может не запуститься
WARN: x-ui setting -port не сработал
```

### Причины:
- X-UI не успевает создать БД за отведённое время
- Процесс x-ui падает при инициализации
- Недостаточно прав на запись

### Решения:

**Метод 1: Ручная инициализация (улучшенный)**
```bash
cd /usr/local/x-ui
systemctl stop x-ui

# Запустить x-ui в фоне
./x-ui > /tmp/x-ui-init.log 2>&1 &
XUI_PID=$!

# Ждать создания БД (до 15 секунд)
for i in $(seq 1 15); do
    if [[ -f x-ui.db ]]; then
        echo "БД создана за $i секунд"
        break
    fi
    sleep 1
done

# Остановить процесс
kill -15 $XUI_PID
sleep 2
pkill -f x-ui

# Проверить
ls -la x-ui.db
```

**Метод 2: Создать БД через sqlite3**
```bash
apt install -y sqlite3

sqlite3 /usr/local/x-ui/x-ui.db << 'EOF'
CREATE TABLE IF NOT EXISTS user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    webBasePath TEXT DEFAULT '/',
    cert TEXT DEFAULT '',
    key TEXT DEFAULT ''
);
INSERT OR IGNORE INTO user (id, username, password) VALUES (1, 'admin', 'admin');
EOF

chmod 600 /usr/local/x-ui/x-ui.db
systemctl restart x-ui
```

**Метод 3: Скачать готовую БД**
```bash
# Для MHSanaei/3x-ui
curl -fsSL https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.db \
  -o /usr/local/x-ui/x-ui.db

chmod 600 /usr/local/x-ui/x-ui.db
systemctl restart x-ui
```

**Метод 4: Прямое редактирование через sqlite3**
```bash
apt install -y sqlite3

# Установить учётные данные
USERNAME=$(grep "Логин:" /root/x-ui-credentials.txt | awk '{print $2}')
PASSWORD=$(grep "Пароль:" /root/x-ui-credentials.txt | awk '{print $2}')
WEBPATH=$(grep "URI панели:" /root/x-ui-credentials.txt | awk '{print $3}')

sqlite3 /usr/local/x-ui/x-ui.db "UPDATE user SET username='${USERNAME}' WHERE id=1;"
sqlite3 /usr/local/x-ui/x-ui.db "UPDATE user SET password='${PASSWORD}' WHERE id=1;"
sqlite3 /usr/local/x-ui/x-ui.db "UPDATE user SET webBasePath='${WEBPATH}' WHERE id=1;"

systemctl restart x-ui
```

**Метод 3: Использовать x-ui меню**
```bash
x-ui
# Выбрать пункт 7: Сбросить логин/пароль/URI панели
```

---

## 🔐 SSL сертификаты

### Симптомы:
- `ERR_SSL_PROTOCOL_ERROR`
- `NET::ERR_CERT_AUTHORITY_INVALID`
- `Could not bind TCP port 80 because it is already in use`
- Сертификат не применяется

### Диагностика:

```bash
# 1. Проверить сертификаты
certbot certificates

# 2. Проверить Nginx использует SSL
cat /etc/nginx/sites-available/x-ui.conf | grep ssl

# 3. Проверить права
ls -la /etc/letsencrypt/live/*/

# 4. Проверить порт 80
ss -tlnp | grep :80
```

### Решения:

**Проблема 1: Порт 80 занят (certbot не может получить сертификат)**

Скрипт автоматически определяет занятость порта и использует:
- **standalone** метод если порт 80 свободен
- **webroot** метод если порт 80 занят

Ручное решение:
```bash
# Остановить процесс на порту 80
ss -tlnp | grep :80
fuser -k 80/tcp

# Или использовать webroot метод
mkdir -p /var/www/letsencrypt
certbot certonly --webroot -w /var/www/letsencrypt \
  -d yourdomain.com --email admin@yourdomain.com --agree-tos
```

**Проблема 2: Сертификат не получен**
```bash
# Остановить Nginx
systemctl stop nginx

# Получить сертификат
certbot certonly --standalone -d yourdomain.com --email admin@yourdomain.com --agree-tos

# Запустить Nginx
systemctl start nginx
```

**Проблема 2: Сертификат истёк**
```bash
certbot renew --force-renewal
systemctl reload nginx
```

**Проблема 3: Symlink не создан**
```bash
DOMAIN="yourdomain.com"
mkdir -p /usr/local/x-ui/cert
rm -f /usr/local/x-ui/cert/server.crt /usr/local/x-ui/cert/server.key
ln -sf /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /usr/local/x-ui/cert/server.crt
ln -sf /etc/letsencrypt/live/${DOMAIN}/privkey.pem /usr/local/x-ui/cert/server.key
systemctl restart x-ui
```

---

## 🛡️ Проблемы с протоколами

### Shadowsocks 2022 не работает

```bash
# Проверить статус
systemctl status shadowsocks

# Проверить порт
ss -tlnp | grep ssserver

# Логи
journalctl -u shadowsocks -n 50

# Перезапустить
systemctl restart shadowsocks
```

### Naive Proxy не работает

```bash
# Проверить Caddy
systemctl status naive-proxy

# Проверить порт
ss -tlnp | grep caddy

# Логи
journalctl -u naive-proxy -n 50

# Проверить конфигурацию
cat /etc/caddy-naive/Caddyfile
```

### Cloak не работает

```bash
# Проверить статус
systemctl status cloak

# Проверить конфигурацию
cat /etc/cloak/server.json

# Логи
journalctl -u cloak -n 50
```

### VLESS Reality

```bash
# Проверить ключи сгенерированы
cat /usr/local/x-ui/reality/config.json

# Проверить в credentials
grep REALITY /root/x-ui-credentials.txt

# Импортировать в X-UI панель вручную
```

---

## 🔧 Nginx ошибки

### 502 Bad Gateway

```bash
# X-UI не запущен
systemctl start x-ui

# Неправильный upstream порт
cat /etc/nginx/sites-available/x-ui.conf | grep proxy_pass
# Должно быть: proxy_pass http://127.0.0.1:RANDOM_PORT;

# Проверить порт X-UI
cat /root/x-ui-port.txt
ss -tlnp | grep $(cat /root/x-ui-port.txt)
```

### 404 Not Found

```bash
# Неправильный location в Nginx
cat /etc/nginx/sites-available/x-ui.conf | grep location

# Должно быть:
# location /RANDOM_URI/ {
#     proxy_pass http://127.0.0.1:PORT/RANDOM_URI/;
# }
```

### Nginx не запускается

```bash
# Проверить синтаксис
nginx -t

# Проверить логи
tail -f /var/log/nginx/error.log

# Порт 80/443 занят
ss -tlnp | grep :80
ss -tlnp | grep :443

# Убить процесс
fuser -k 80/tcp
fuser -k 443/tcp

systemctl restart nginx
```

---

## 🔌 Порты заняты

### Диагностика:

```bash
# Проверить все порты
ss -tlnp

# Проверить конкретный порт
ss -tlnp | grep :PORT

# Найти процесс
lsof -i :PORT
```

### Решения:

```bash
# Убить процесс на порту
fuser -k PORT/tcp

# Или найти PID и убить
kill -9 $(lsof -t -i:PORT)

# Изменить порт X-UI
x-ui
# Выбрать пункт 8: Настройки панели
```

---

## 🛡️ AppArmor блокирует

### Симптомы:
```bash
dmesg | grep apparmor | grep x-ui
# apparmor="DENIED" operation="open" profile="/usr/local/x-ui/x-ui"
```

### Решения:

**Метод 1: Отключить профиль**
```bash
aa-disable /usr/local/x-ui/x-ui
systemctl restart x-ui
```

**Метод 2: Режим complain**
```bash
aa-complain /usr/local/x-ui/x-ui
systemctl restart x-ui
```

**Метод 3: Полностью отключить AppArmor**
```bash
systemctl stop apparmor
systemctl disable apparmor
reboot
```

---

## 📊 Общая диагностика

### Полная проверка системы:

```bash
#!/bin/bash

echo "=== X-UI Status ==="
systemctl status x-ui --no-pager

echo -e "\n=== X-UI Logs ==="
journalctl -u x-ui -n 20 --no-pager

echo -e "\n=== Nginx Status ==="
systemctl status nginx --no-pager

echo -e "\n=== Ports ==="
ss -tlnp | grep -E "x-ui|nginx"

echo -e "\n=== Database ==="
ls -la /usr/local/x-ui/x-ui.db

echo -e "\n=== SSL Certificates ==="
certbot certificates

echo -e "\n=== UFW Status ==="
ufw status

echo -e "\n=== Credentials ==="
cat /root/x-ui-credentials.txt

echo -e "\n=== Disk Space ==="
df -h /

echo -e "\n=== Memory ==="
free -h

echo -e "\n=== AppArmor ==="
dmesg | grep -i apparmor | grep x-ui | tail -5
```

Сохраните как `/usr/local/x-ui/diagnose.sh` и запустите:
```bash
chmod +x /usr/local/x-ui/diagnose.sh
/usr/local/x-ui/diagnose.sh
```

---

## 🆘 Экстренное восстановление

### Полная переустановка X-UI:

```bash
# 1. Сохранить БД
cp /usr/local/x-ui/x-ui.db /root/x-ui-backup.db

# 2. Остановить сервисы
systemctl stop x-ui
systemctl stop nginx

# 3. Удалить X-UI
rm -rf /usr/local/x-ui
rm -f /etc/systemd/system/x-ui.service

# 4. Переустановить
bash install.sh

# 5. Восстановить БД (опционально)
cp /root/x-ui-backup.db /usr/local/x-ui/x-ui.db
systemctl restart x-ui
```

---

## 📞 Поддержка

Если проблема не решена:

1. Соберите диагностику: `/usr/local/x-ui/diagnose.sh > /root/x-ui-debug.txt`
2. Проверьте логи: `/var/log/x-ui-install.log`
3. Создайте issue: https://github.com/sergej19882906/x-ui-ultimate/issues

---

**X-UI Ultimate Installer v1.2.0** | 2026
