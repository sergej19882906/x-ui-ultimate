# 📋 Changelog

Все изменения в проекте.

Формат: [Keep a Changelog](https://keepachangelog.com/)
Версии: [SemVer](https://semver.org/)

---

## [1.2.0] - 2026-04-03

### Added
- WARP (Cloudflare) в режиме **proxy** — SOCKS5 на 127.0.0.1:40000

### Fixed
- WARP **не разрывает SSH и Nginx** — proxy mode не меняет маршрутизацию
- SSL cp обрывал скрипт — 'same file' ошибка при symlink
- x-ui setting вызывается по одному параметру — не все сразу
- Увеличен timeout инициализации БД до 8 сек
- Fallback: sqlite3 UPDATE для username и webBasePath
- Symlink SSL с rm -f перед ln -sf

---

## [1.1.0] - 2026-04-03

### Added
- WARP (Cloudflare) в режиме **proxy** — SOCKS5 на 127.0.0.1:40000
- Интерактивное меню `x-ui` через wrapper-скрипт (10 пунктов)
- Обратный прокси Nginx для X-UI панели через `webBasePath`
- SSL-сертификаты для подписок через Nginx (HTTPS без порта)
- Случайный сложный URI для панели (`webBasePath`, 16 символов)
- Случайный сложный URI для подписок (24 символа)
- Летающие котики на странице-заглушке Nginx
- SOCKS5 прокси (Dante) для Telegram бота с авторизацией
- Автоматическое использование WARP прокси Telegram ботом

### Fixed
- WARP **не разрывает SSH и Nginx** — proxy mode не меняет маршрутизацию
- Конфликт портов Nginx (443) и X-UI — панель на внутреннем порту
- SSL-сертификаты не применялись в x-ui panel
- x-ui меню не работало через SSH (был symlink на бинарник)
- Symlink `/usr/local/bin/x-ui` заменён на wrapper-скрипт
- Инициализация БД x-ui.db перед настройкой учётных данных
- Диагностика запуска x-ui: systemd status, journalctl, dmesg, AppArmor check

### Changed
- Внешний URL панели: `https://domain/webBasePath/` (порт 443 через Nginx)
- Подписки раздаются через HTTPS с SSL-сертификатом
- Убрана кнопка "Войти" со страницы-заглушки

---

## [1.0.3] - 2026-04-01

### Fixed
- Docker: активация `docker.socket`, UFW `DEFAULT_FORWARD_POLICY=ACCEPT` для контейнеров; открытие портов 9000/3001
- Автообновление: API репозитория совпадает с выбранным при установке `XUI_REPO`
- SSH hardening: перезапуск сервиса `ssh` (не только несуществующий на Ubuntu `sshd`)
- `backup.sh`: дата в логе записывается во время бэкапа, а не при установке
- Финальный вывод Portainer только если Docker реально работает

### Improved
- Hysteria, Tuic, Trojan-Go, Brook: выбор артефакта по `uname -m`, отказоустойчивые загрузки
- WireGuard: каталог `/etc/wireguard` перед генерацией ключей
- Удалён устаревший `Protocol 2` из шаблона `sshd_config`

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
