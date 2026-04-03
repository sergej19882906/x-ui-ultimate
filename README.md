# 🚀 X-UI Ultimate Installer

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/sergej19882906/x-ui-ultimate/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/ubuntu-20.04+-orange.svg)](https://ubuntu.com)
[![Debian](https://img.shields.io/badge/debian-11+-red.svg)](https://debian.org)

> ⚠️ **ПРЕДУПРЕЖДЕНИЕ**: Использование для обхода блокировок может быть незаконным в вашей юрисдикции.

Автоматическая установка и настройка **X-UI панели** с безопасностью, мониторингом и обходом блокировок.

---

## 📋 Содержание

- [Подготовка](#-подготовка)
- [Быстрый старт](#-быстрый-старт)
- [Требования](#-требования)
- [Функции](#-функции)
- [Команды](#-команды)
- [Документация](#-документация)
- [FAQ](#-faq)

---

## 📖 Подготовка

**⚠️ Важно:** Перед запуском установки необходимо подготовить сервер и домен.

**Подробная инструкция:** [PRE_INSTALL.md](PRE_INSTALL.md)

**Краткий чек-лист:**
- [ ] Домен с DNS записью на IP сервера
- [ ] Ubuntu 20.04+ / Debian 11+
- [ ] 512 MB+ RAM, 1 GB+ диска
- [ ] Порты 80, 443 открыты

---

## ⚡ Быстрый старт

```bash
wget -O install.sh https://raw.githubusercontent.com/sergej19882906/x-ui-ultimate/main/install.sh
chmod +x install.sh && sudo ./install.sh
```

**Время установки:** 10-15 минут

---

## 📋 Требования

| Параметр | Минимум | Рекомендуется |
|----------|---------|---------------|
| **ОС** | Ubuntu 20.04 / Debian 11 | Ubuntu 22.04 LTS |
| **RAM** | 512 MB | 1 GB+ |
| **Диск** | 1 GB | 5 GB+ |
| **Домен** | Обязательно | Обязательно |

---

## ✨ Функции

### 🔒 Безопасность (6)
UFW, Fail2ban, SSH hardening, 2FA, AppArmor, DDoS защита

### 🌐 Сеть (3)
IPv6, TCP BBR, Cloudflare CDN

### 🛡️ Обход блокировок (7)
WebSocket, gRPC, ShadowTLS, Reality, Hysteria 2, Tuic, WireGuard

### 📊 Мониторинг (4)
Telegram, Discord, Uptime Kuma, Health check

### 🔄 Автообновление (2)
X-UI, Автобэкап

### 🐳 Контейнеры (2)
Docker, Portainer

### 📦 Протоколы (3)
Trojan-Go, Brook, Sing-Box

### 📱 Клиенты (4)
Подписки, QR коды, REST API, Конвертер

**Всего:** 31 функция

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

### Скрипты
```bash
/usr/local/x-ui/generate-subscription.sh  # Подписки
/usr/local/x-ui/generate-qr.sh            # QR коды
/usr/local/x-ui/link-converter.sh         # Конвертер
/usr/local/x-ui/backup.sh                 # Бэкап
```

### REST API (порт 8080)
```bash
curl -H "Authorization: Bearer API_KEY" http://localhost:8080/api/status
curl -X POST -H "Authorization: Bearer API_KEY" http://localhost:8080/api/restart
```

---

## 📚 Документация

Полная документация: [DOCS.md](DOCS.md)

---

## ❓ FAQ

**Сколько нужно RAM?**  
Минимум 512MB, рекомендуется 1GB+.

**Можно без домена?**  
Нет, домен обязателен для SSL.

**Ошибка "This version does not support verification"?**  
Используйте версию **MHSanaei/3x-ui** (выбор 2 при установке).  
Или обновите скрипт: `wget -O install.sh https://raw.githubusercontent.com/sergej19882906/x-ui-ultimate/main/install.sh`

**Как сменить порт?**  
Через `x-ui` → настройки панели.

**Где логи?**  
`/var/log/x-ui-install.log`

**Как обновить?**  
`x-ui update`

**Как восстановить из бэкапа?**  
```bash
cp /root/x-ui-backups/x-ui-db-*.bak /usr/local/x-ui/x-ui.db
systemctl restart x-ui
```

---

## 🔗 Ссылки

- [📋 Подготовка к установке](PRE_INSTALL.md)
- [📚 Полная документация](DOCS.md)
- [3x-ui GitHub](https://github.com/MHSanaei/3x-ui)
- [v2ray Docs](https://www.v2ray.com)
- [Cloudflare](https://developers.cloudflare.com)
- [Docker](https://docs.docker.com)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)

---

## 📄 Лицензия

MIT License — см. [LICENSE](LICENSE)

---

## 🤝 Поддержка

1. Проверьте логи: `journalctl -u x-ui -f`
2. Проверьте статус: `systemctl status x-ui`
3. Перезапустите: `systemctl restart x-ui`
4. Восстановите из бэкапа

---

## 📊 Статистика

| Метрика | Значение |
|---------|----------|
| **Строк кода** | ~1080 |
| **Функций** | 31 |
| **Время установки** | 10-15 мин |
| **RAM** | 512 MB мин. |

---

## 🎯 Changelog

### v1.0.3 (2026-04-01)
- ✅ Docker: `docker.socket` + UFW `DEFAULT_FORWARD_POLICY`, порты Portainer/Uptime Kuma
- ✅ Автообновление X-UI по выбранному репозиторию (`XUI_REPO`), не только 3x-ui
- ✅ SSH: перезапуск через unit `ssh` (Ubuntu/Debian)
- ✅ Архитектуры: Hysteria, Tuic, Trojan-Go, Brook; безопасная загрузка (`curl` без обрыва всего скрипта)
- ✅ Бэкап: корректная дата в логе; WireGuard: `mkdir` для `/etc/wireguard`

### v1.0.2 (2026-03-31)
- ✅ Исправлена генерация SSL email
- ✅ Исправлено использование $RANDOM_PORT в скриптах
- ✅ Исправлены пути SSL сертификатов для Nginx
- ✅ Добавлена поддержка архитектур: armv6l, i686, riscv64

### v1.0.1 (2026)
- ✅ Исправлены ошибки инициализации
- ✅ Удалены нерабочие протоколы
- ✅ Добавлена генерация API_KEY
- ✅ Оптимизирован размер

### v1.0.0 (2026)
- 🎉 Первый релиз

---

<div align="center">

**X-UI Ultimate Installer v1.0.3**

[⬆️ Наверх](#-x-ui-ultimate-installer)

</div>
