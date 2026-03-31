# 📋 Changelog

Все изменения в проекте.

Формат: [Keep a Changelog](https://keepachangelog.com/)
Версии: [SemVer](https://semver.org/)

---

## [1.0.2] - 2026-03-31

### 🐛 Fixed
- Исправлена генерация SSL email (admin@domain вместо admin@tld)
- Исправлено использование $RANDOM_PORT в скриптах (сохранение в файл)
- Исправлены пути SSL сертификатов для Nginx (ZeroSSL поддержка)
- Добавлена поддержка архитектур: armv6l, i686, riscv64

### 🔧 Improved
- generate-subscription.sh читает порт из файла
- Nginx конфиг использует правильные пути SSL

---

## [1.0.1] - 2026-XX-XX

### 🐛 Fixed
- Исправлена инициализация RANDOM_PORT
- Исправлена очистка временных файлов
- Исправлена проверка установки Docker
- Исправлена проверка SSL email
- AppArmor перемещён после установки X-UI
- Добавлена проверка статуса API

### ⚡ Optimized
- Удалены нерабочие протоколы
- Удалено дублирование установок
- Добавлена генерация API_KEY
- Оптимизирован размер скрипта
- Упрощены условия в финальном выводе
- Добавлен кэш загрузок

### 📝 Documentation
- Обновлена документация
- Добавлены файлы для GitHub

---

## [1.0.0] - 2026-XX-XX

### ✨ New
- Начальный релиз
- 31 функция в скрипте
- Поддержка Ubuntu/Debian
- IPv6 поддержка
- TCP BBR оптимизация
- UFW фаервол
- Fail2ban защита
- SSH hardening
- 2FA Google Authenticator
- AppArmor профили
- DDoS защита
- Cloudflare CDN
- Обход блокировок (7 протоколов)
- Мониторинг (Telegram, Discord, Uptime Kuma)
- Автообновление X-UI
- Автобэкап конфигурации
- Docker + Portainer
- Протоколы (Trojan-Go, Brook, Sing-Box)
- Генерация подписок
- QR коды
- REST API
- Конвертер ссылок
- Health check

### 📝 Documentation
- Полная документация
- README с примерами
- FAQ и Troubleshooting

---

## [Unreleased]

Планы на будущее:
- CrowdSec интеграция
- Grafana дашборды
- Auto-healing сервисов
- Rclone для бэкапов
- Ansible роль

---

[1.0.1]: https://github.com/sergej19882906/x-ui-ultimate/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sergej19882906/x-ui-ultimate/releases/tag/v1.0.0
