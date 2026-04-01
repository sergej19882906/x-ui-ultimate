# 📋 Подготовка к установке

Подробная инструкция по подготовке сервера к установке X-UI Ultimate Installer.

---

## ⏱️ Время подготовки

**5-10 минут** до запуска скрипта установки.

---

## ✅ Чек-лист перед установкой

- [ ] Сервер с Ubuntu 20.04+ / Debian 11+
- [ ] Домен с DNS записью на IP сервера
- [ ] 512 MB+ RAM, 1 GB+ диска
- [ ] Доступ root
- [ ] Порты 80, 443 открыты

---

## 1. Требования к серверу

| Параметр | Минимум | Рекомендуется |
|----------|---------|---------------|
| **ОС** | Ubuntu 20.04 / Debian 11 | Ubuntu 22.04 LTS |
| **RAM** | 512 MB | 1 GB+ |
| **Диск** | 1 GB | 5 GB+ |
| **Права** | root | root |
| **Домен** | Обязательно | Обязательно |

---

## 2. Домен и DNS

### 2.1. Купить домен

Примеры регистраторов:
- Namecheap
- GoDaddy
- Reg.ru
- Cloudflare (бесплатно)

### 2.2. Настроить DNS записи

**В панели регистратора домена:**

| Тип | Имя | Значение | TTL |
|-----|-----|----------|-----|
| A | @ | `<IP сервера>` | Auto |
| A | www | `<IP сервера>` | Auto |

**Опционально для Docker UI:**

| Тип | Имя | Значение | TTL |
|-----|-----|----------|-----|
| A | portainer | `<IP сервера>` | Auto |
| A | kuma | `<IP сервера>` | Auto |

### 2.3. Проверка DNS

```bash
# Домен должен разрешаться в IP сервера
ping example.com

# Или через dig
dig example.com +short

# Должен вернуться IP вашего сервера
```

---

## 3. Подготовка сервера

### 3.1. Подключиться по SSH

```bash
ssh root@<IP сервера>
```

### 3.2. Обновить систему

```bash
apt update && apt upgrade -y
```

### 3.3. Перезагрузить (если было много обновлений)

```bash
reboot
```

### 3.4. Проверить ресурсы

```bash
# Свободное место на диске
df -h /

# Оперативная память
free -m

# Архитектура процессора
uname -m
```

### 3.5. Проверить открытые порты

```bash
# Порты должны быть открыты в панели хостинга:
# - 22 (SSH)
# - 80 (HTTP, для SSL)
# - 443 (HTTPS, для SSL)
```

---

## 4. Скачать скрипт

```bash
# Скачать последнюю версию
wget -O install.sh https://raw.githubusercontent.com/sergej19882906/x-ui-ultimate/main/install.sh

# Сделать исполняемым
chmod +x install.sh

# Проверить версию в начале файла
head -20 install.sh | grep Version
```

---

## 5. Подготовить данные для установки

Заполните таблицу перед запуском:

| Параметр | Значение | Пример |
|----------|----------|--------|
| **Домен** | | `example.com` |
| **Email для SSL** | | `admin@example.com` |
| **Версия X-UI** | 1/2/3 | `2` (MHSanaei/3x-ui) |
| **IPv6** | y/n | `n` |
| **Маскировка трафика** | y/n | `y` |
| **Транспорт** | ws/grpc/http | `ws` |
| **Cloudflare CDN** | y/n | `n` |
| **ShadowTLS** | y/n | `y` |
| **Reality** | y/n | `n` |
| **Hysteria 2** | y/n | `y` |
| **Tuic** | y/n | `n` |
| **WireGuard** | y/n | `n` |
| **Порт 443** | y/n | `n` (случайный) |
| **SSH hardening** | y/n | `y` |
| **Порт SSH** | число | `2222` |
| **2FA** | y/n | `y` |
| **AppArmor** | y/n | `y` |
| **Telegram уведомления** | y/n | `n` |
| **Discord webhook** | y/n | `n` |
| **Uptime Kuma** | y/n | `y` |
| **Автообновление X-UI** | y/n | `y` |
| **Автобэкап** | y/n | `y` |
| **Docker** | y/n | `y` |
| **Portainer** | y/n | `y` |
| **HTTPS для Docker UI** | y/n | `y` |
| **Trojan-Go** | y/n | `n` |
| **Brook** | y/n | `n` |
| **Sing-Box** | y/n | `y` |
| **Генерация подписок** | y/n | `y` |
| **QR коды** | y/n | `y` |
| **REST API** | y/n | `y` |
| **Конвертер ссылок** | y/n | `n` |
| **Speedtest** | y/n | `y` |
| **ZeroSSL** | y/n | `n` |

---

## 6. Запуск установки

```bash
# Запустить скрипт
sudo ./install.sh

# Время установки: 10-15 минут
```

---

## 7. После установки

### 7.1. Сохранить данные доступа

```bash
# Вывести данные на экран
cat /root/x-ui-credentials.txt

# Или скопировать файл
cp /root/x-ui-credentials.txt /root/backup/
```

### 7.2. Проверить статус сервисов

```bash
# X-UI панель
systemctl status x-ui

# Nginx
systemctl status nginx

# Docker (если установлен)
systemctl status docker

# Uptime Kuma (если установлен)
docker ps | grep uptime-kuma
```

### 7.3. Открыть панель

```
URL: https://<domain>:<port>
Логин: adminXXXX
Пароль: (из файла credentials)
```

### 7.4. Проверить SSL сертификат

```bash
# Проверить сертификат
curl -vI https://<domain>

# Или онлайн:
# https://www.sslshopper.com/ssl-checker.html
```

---

## 🔧 Troubleshooting

### Домен не разрешается

```bash
# Проверить DNS
dig example.com +short

# Подождать 5-60 минут (распространение DNS)
# Проверить у регистратора
```

### Порт 80/443 занят

```bash
# Найти процесс на порту
ss -tlnp | grep :80
ss -tlnp | grep :443

# Остановить конфликтующий сервис
systemctl stop nginx
systemctl stop apache2
```

### Мало места

```bash
# Очистить кэш apt
apt clean

# Удалить старые ядра
apt autoremove --purge

# Найти большие файлы
du -ah / | sort -rh | head -20
```

### APT update падает

```bash
# Удалить сломанные репозитории
rm -f /etc/apt/sources.list.d/*ookla* /etc/apt/sources.list.d/*speedtest*
sed -i '/packagecloud\.io/d' /etc/apt/sources.list

# Повторить
apt update
```

### Docker не запускается

```bash
# Перезапустить сервисы
systemctl daemon-reload
systemctl restart containerd
systemctl restart docker.socket
systemctl restart docker.service

# Проверить логи
journalctl -u docker -n 50
```

---

## 📞 Поддержка

Если возникли проблемы:

1. Проверьте логи установки:
   ```bash
   tail -100 /var/log/x-ui-install.log
   ```

2. Проверьте статус сервисов:
   ```bash
   systemctl status x-ui nginx docker
   ```

3. Откройте issue на GitHub:
   https://github.com/sergej19882906/x-ui-ultimate/issues

---

## 🔗 Ссылки

- [Основная документация](DOCS.md)
- [README](README.md)
- [Changelog](CHANGELOG.md)
- [3x-ui GitHub](https://github.com/MHSanaei/3x-ui)
- [Cloudflare DNS](https://developers.cloudflare.com/dns/)

---

<div align="center">

**X-UI Ultimate Installer v1.0.3** | 2026

[⬆️ Наверх](#-подготовка-к-установке)

</div>
