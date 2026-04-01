# 🚀 X-UI Ultimate Installer v1.0.3 — Документация

## 📋 Оглавление

1. [Быстрый старт](#быстрый-старт)
2. [Требования](#требования)
3. [Установка](#установка)
4. [Функции](#функции)
5. [Команды](#команды)
6. [API](#api)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## ⚡ Быстрый старт

```bash
wget -O install.sh https://raw.githubusercontent.com/sergej19882906/x-ui-ultimate/main/install.sh
chmod +x install.sh && sudo ./install.sh
```

**Время установки:** 10-15 минут

---

## 📋 Требования

### Минимальные
- **ОС:** Ubuntu 20.04+ / Debian 11+
- **RAM:** 512 MB
- **Диск:** 1 GB
- **Права:** root
- **Домен:** Обязательно

### Рекомендуемые
- **ОС:** Ubuntu 22.04 LTS
- **RAM:** 1 GB+
- **Диск:** 5 GB+

---

## 📦 Установка

### Шаг 1: Подготовка

```bash
sudo apt update && sudo apt upgrade -y
wget -O install.sh https://raw.githubusercontent.com/sergej19882906/x-ui-ultimate/main/install.sh
chmod +x install.sh
```

### Шаг 2: Запуск

```bash
sudo ./install.sh
```

### Шаг 3: Вопросы

Скрипт задаст ~25 вопросов:
- Домен (для SSL)
- Email (для Let's Encrypt)
- Версия X-UI (1/2/3)
- IPv6 (y/n)
- Маскировка (y/n)
- Протоколы (y/n)
- Порт (443 или случайный)
- SSH hardening (y/n)
- 2FA (y/n)
- Docker (y/n)
- Мониторинг (y/n)

### Шаг 4: Данные

После установки:
- **URL:** `https://domain:port`
- **Логин:** `adminXXXX`
- **Пароль:** (случайный)
- **Файл:** `/root/x-ui-credentials.txt`

---

## ✨ Функции

### 🔒 Безопасность
- UFW фаервол (IPv4 + IPv6)
- Fail2ban (защита от брутфорса)
- SSH hardening (смена порта, ключи)
- 2FA Google Authenticator
- AppArmor профили
- DDoS защита

### 🌐 Сеть
- IPv6 dual-stack
- TCP BBR (ускорение до 40%)
- Cloudflare CDN

### 🛡️ Обход блокировок
- WebSocket + TLS
- gRPC + TLS
- ShadowTLS
- Reality
- Hysteria 2
- Tuic (UDP over QUIC)
- WireGuard

### 📊 Мониторинг
- Telegram уведомления
- Discord webhook
- Uptime Kuma (порт 3001)
- Health check (каждые 5 мин)

### 🔄 Автообновление
- X-UI (ежедневно)
- Автобэкап (ежедневно в 03:00)

### 🐳 Контейнеры
- Docker
- Portainer (порт 9000)

### 📦 Протоколы
- Trojan-Go (порт 443)
- Brook (порт 9999)
- Sing-Box

### 📱 Клиенты
- Генерация подписок
- QR коды
- REST API (порт 8080)
- Конвертер ссылок

---

## ⚙️ Команды

### X-UI
```bash
x-ui              # Меню
x-ui start        # Запустить
x-ui stop         # Остановить
x-ui restart      # Перезапустить
x-ui status       # Статус
x-ui log          # Логи
x-ui update       # Обновить
```

### Сервисы
```bash
systemctl status x-ui
systemctl restart x-ui
journalctl -u x-ui -f
```

### Скрипты
```bash
/usr/local/x-ui/generate-subscription.sh  # Подписки
/usr/local/x-ui/generate-qr.sh            # QR коды
/usr/local/x-ui/link-converter.sh         # Конвертер
/usr/local/x-ui/backup.sh                 # Бэкап
/usr/local/x-ui/health-check.sh           # Health check
```

### Логи
```bash
tail -f /var/log/x-ui-install.log
tail -f /var/log/x-ui/*.log
tail -f /var/log/x-ui-alert.log
```

---

## 🔌 API

**Порт:** 8080

### Эндпоинты

| Метод | Эндпоинт | Описание |
|-------|----------|----------|
| GET | `/api/status` | Статус X-UI |
| GET | `/api/links` | Ссылки |
| POST | `/api/restart` | Перезапуск |

### Пример

```bash
API_KEY="your_api_key"

# Статус
curl -H "Authorization: Bearer $API_KEY" http://localhost:8080/api/status

# Перезапуск
curl -X POST -H "Authorization: Bearer $API_KEY" http://localhost:8080/api/restart
```

### Python

```python
import requests

API_KEY = "your_api_key"
headers = {"Authorization": f"Bearer {API_KEY}"}

r = requests.get("http://localhost:8080/api/status", headers=headers)
print(r.json())
```

---

## 🔧 Troubleshooting

### X-UI не запускается
```bash
systemctl status x-ui
journalctl -u x-ui -f
systemctl restart x-ui
```

### SSL не работает
```bash
certbot certificates
certbot renew --force-renewal
tail -f /var/log/letsencrypt/letsencrypt.log
```

### Nginx не запускается
```bash
nginx -t
tail -f /var/log/nginx/error.log
systemctl restart nginx
```

### API не работает
```bash
systemctl status x-ui-api
journalctl -u x-ui-api -f
ss -tlnp | grep 8080
```

### UFW блокирует
```bash
ufw status verbose
ufw allow 8080/tcp
```

### Fail2ban забанил
```bash
fail2ban-client status
fail2ban-client set x-ui unbanip 1.2.3.4
```

---

## ❓ FAQ

**Сколько нужно RAM?**  
512MB минимум, 1GB+ рекомендуется.

**Можно без домена?**  
Нет, домен обязателен для SSL.

**Как сменить порт?**  
`x-ui` → настройки панели.

**Где логи установки?**  
`/var/log/x-ui-install.log`

**Как обновить вручную?**  
`x-ui update`

**Как восстановить из бэкапа?**  
```bash
cp /root/x-ui-backups/x-ui-db-*.bak /usr/local/x-ui/x-ui.db
systemctl restart x-ui
```

**IPv6 не работает?**  
```bash
cat /proc/sys/net/ipv6/conf/all/disable_ipv6
sysctl -w net.ipv6.conf.all.disable_ipv6=0
```

**Как отключить 2FA?**  
```bash
sed -i '/pam_google_authenticator/d' /etc/pam.d/common-auth
```

**Сменить API ключ?**  
```bash
nano /usr/local/x-ui/api.py
# Изменить API_KEY
systemctl restart x-ui-api
```

---

## 📚 Клиенты

### Windows
- v2rayN, Clash for Windows

### macOS
- ClashX Pro, V2rayU

### Linux
- v2rayA, Clash

### Android
- v2rayNG, Nekobox, Hiddify

### iOS
- Shadowrocket, Streisand, FoXray

---

## 🔗 Ссылки

- [3x-ui](https://github.com/MHSanaei/3x-ui)
- [v2ray](https://www.v2ray.com)
- [Cloudflare](https://developers.cloudflare.com)
- [Docker](https://docs.docker.com)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [WireGuard](https://www.wireguard.com)

---

## 📞 Поддержка

```bash
# Диагностика
tail -100 /var/log/x-ui-install.log
journalctl -u x-ui -n 50
```

---

<div align="center">

**X-UI Ultimate Installer v1.0.2** | 2026

</div>
