#!/bin/bash

# =============================================================================
# X-UI Ultimate Installation Script v1.0.3
# Полная настройка безопасности, мониторинга, обхода блокировок и оптимизации
# =============================================================================
# GitHub: https://github.com/sergej19882906/x-ui-ultimate
# License: MIT
# Version: 1.0.3
# Year: 2026
# =============================================================================
# ⚠️ ПРЕДУПРЕЖДЕНИЕ: Использование для обхода блокировок может быть
# незаконным в вашей юрисдикции. Проконсультируйтесь с юристом.
# =============================================================================

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Лог файл
LOG_FILE="/var/log/x-ui-install.log"
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1

# Функции
log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error_log() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА:${NC} $1"; }
success_log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] УСПЕХ:${NC} $1"; }
warn_log() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ВНИМАНИЕ:${NC} $1"; }

# Сломанные сторонние repo (часто 404 Not Found у packagecloud) ломают весь apt update.
_apt_cleanup_bad_repos() {
    rm -f /etc/apt/sources.list.d/*ookla* /etc/apt/sources.list.d/*speedtest* 2>/dev/null || true
    sed -i '/packagecloud\.io\/ookla\/speedtest-cli/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true
}

# Одна строка в crontab пользователя root (без дублей при повторном запуске)
_cron_set_line() {
    local line="$1"
    ( crontab -l 2>/dev/null | grep -vF "$line" || true
      echo "$line"
    ) | crontab -
}

# Проверка root
if [[ $EUID -ne 0 ]]; then
    error_log "Запустите от root"
    exit 1
fi

# Проверка ОС
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
        warn_log "Тестировался на Ubuntu/Debian. Ваша ОС: $OS_ID"
        read -r -p "Продолжить? (y/n): " c
        if [[ "$c" != "y" ]]; then
            exit 1
        fi
    fi
else
    error_log "ОС не определена"
    exit 1
fi

# Проверка ресурсов
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
if [[ $TOTAL_RAM -lt 512 ]]; then
    error_log "Нужно 512MB+ RAM"
    exit 1
fi

FREE_DISK=$(df / | tail -1 | awk '{print $4}')
if [[ $FREE_DISK -lt 1048576 ]]; then
    error_log "Нужно 1GB+ места"
    exit 1
fi

# =============================================================================
# Вопросы
# =============================================================================
log "=== 📋 Настройки ==="

read -r -p "Домен: " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    error_log "Домен обязателен"
    exit 1
fi

read -r -p "Email для SSL: " SSL_EMAIL
if [[ ! "$SSL_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    SSL_EMAIL="admin@${DOMAIN}"
    warn_log "Email: $SSL_EMAIL"
fi

echo -e "${CYAN}Версия X-UI:${NC}"
echo "  1) vaxilu/x-ui (старая)"
echo "  2) MHSanaei/3x-ui (рекомендуется)"
echo "  3) FranzKafkaYu/x-ui"
read -r -p "Выбор (Enter=2): " xv
case $xv in
    1) XUI_REPO="vaxilu/x-ui" ;;
    3) XUI_REPO="FranzKafkaYu/x-ui" ;;
    *) XUI_REPO="MHSanaei/3x-ui" ;;  # По умолчанию 3x-ui
esac
log "Выбрана версия: ${CYAN}$XUI_REPO${NC}"

read -r -p "Включить IPv6? (y/n): " ENABLE_IPV6

log "=== 🛡️ Обход блокировок ==="
read -r -p "Маскировка трафика? (y/n): " ENABLE_OBFUSCATION
TRANSPORT_TYPE="ws"
if [[ "$ENABLE_OBFUSCATION" == "y" ]]; then
    echo "  1) WebSocket (рек)  2) gRPC  3) HTTP/2"
    read -r -p "Транспорт (Enter=1): " tc
    case $tc in
        2) TRANSPORT_TYPE="grpc" ;;
        3) TRANSPORT_TYPE="http" ;;
    esac
fi

read -r -p "Cloudflare CDN? (y/n): " USE_CDN
read -r -p "ShadowTLS? (y/n): " ENABLE_SHADOWTLS
read -r -p "Reality протокол? (y/n): " ENABLE_REALITY
read -r -p "Hysteria 2? (y/n): " ENABLE_HYSTERIA
read -r -p "Tuic? (y/n): " ENABLE_TUIC
read -r -p "WireGuard? (y/n): " ENABLE_WIREGUARD
read -r -p "WARP (Cloudflare)? (y/n): " ENABLE_WARP

if [[ "$ENABLE_OBFUSCATION" == "y" ]]; then
    log "Транспорт маскировки: ${TRANSPORT_TYPE}"
fi
if [[ "$ENABLE_REALITY" == "y" ]]; then
    warn_log "Reality: настройте вручную в панели X-UI после установки"
fi

if [[ "$USE_CDN" == "y" ]]; then
    RANDOM_PORT=$((RANDOM % 57000 + 8000))
else
    # X-UI всегда на внутреннем порту — Nginx проксирует через 443
    RANDOM_PORT=$((RANDOM % 57000 + 20000))
fi

# Сохраняем порт для использования в скриптах
echo "${RANDOM_PORT}" > /root/x-ui-port.txt
chmod 600 /root/x-ui-port.txt

log "=== 🔒 Безопасность ==="
read -r -p "SSH hardening? (y/n): " SETUP_SSH_HARDENING
SSH_PORT="22"
if [[ "$SETUP_SSH_HARDENING" == "y" ]]; then
    read -r -p "Порт SSH (Enter=случайный): " SSH_PORT
    if [[ -z "$SSH_PORT" ]]; then
        SSH_PORT=$((RANDOM % 64000 + 1024))
    fi
fi
read -r -p "2FA? (y/n): " ENABLE_2FA
read -r -p "AppArmor? (y/n): " ENABLE_APPARMOR
read -r -p "DDoS защита? (y/n): " ENABLE_DDOS_PROT

log "=== 📊 Мониторинг ==="
read -r -p "Telegram? (y/n): " SETUP_TELEGRAM
if [[ "$SETUP_TELEGRAM" == "y" ]]; then
    read -r -p "Токен бота: " TELEGRAM_BOT_TOKEN
    read -r -p "Chat ID: " TELEGRAM_CHAT_ID
fi
read -r -p "Discord webhook? (y/n): " SETUP_DISCORD
if [[ "$SETUP_DISCORD" == "y" ]]; then
    read -r -p "URL: " DISCORD_WEBHOOK
fi
read -r -p "Uptime Kuma? (y/n): " SETUP_UPTIME_KUMA

log "=== 🔄 Автообновление ==="
read -r -p "Автообновление X-UI? (y/n): " ENABLE_AUTO_UPDATE
read -r -p "Автобэкап? (y/n): " ENABLE_AUTO_BACKUP
BACKUP_PATH="/root/x-ui-backups"

log "=== 🐳 Docker ==="
read -r -p "Docker? (y/n): " INSTALL_DOCKER
INSTALL_PORTAINER="n"
if [[ "$INSTALL_DOCKER" == "y" ]]; then
    read -r -p "Portainer? (y/n): " INSTALL_PORTAINER
fi

log "=== 📦 Протоколы ==="
read -r -p "Trojan-Go? (y/n): " INSTALL_TROJAN_GO
read -r -p "Brook? (y/n): " INSTALL_BROOK
read -r -p "Sing-Box? (y/n): " INSTALL_SINGBOX

log "=== 📱 Клиенты ==="
read -r -p "Генерация подписок? (y/n): " CREATE_SUBSCRIPTION
read -r -p "QR коды? (y/n): " GENERATE_QR
read -r -p "REST API? (y/n): " CREATE_API
read -r -p "Конвертер ссылок? (y/n): " INSTALL_LINK_CONVERTER

read -r -p "Очистка системы? (y/n): " ENABLE_CLEANUP
read -r -p "Speedtest? (y/n): " INSTALL_SPEEDTEST
read -r -p "ZeroSSL вместо Let's Encrypt? (y/n): " USE_ZEROSL

# HTTPS для Portainer / Uptime Kuma: Nginx + тот же LE-сертификат (SAN), поддомены в DNS
USE_DOCKER_SUBDOMAIN_TLS="n"
PORTAINER_HTTPS_HOST=""
KUMA_HTTPS_HOST=""
if [[ "$INSTALL_DOCKER" == "y" ]] && { [[ "$INSTALL_PORTAINER" == "y" ]] || [[ "$SETUP_UPTIME_KUMA" == "y" ]]; }; then
    read -r -p "HTTPS через Nginx для Docker UI (portainer.${DOMAIN}, kuma.${DOMAIN} — только выбранные; нужен DNS) (y/n): " USE_DOCKER_SUBDOMAIN_TLS
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" == "y" ]]; then
        [[ "$INSTALL_PORTAINER" == "y" ]] && PORTAINER_HTTPS_HOST="portainer.${DOMAIN}"
        [[ "$SETUP_UPTIME_KUMA" == "y" ]] && KUMA_HTTPS_HOST="kuma.${DOMAIN}"
    fi
fi

# =============================================================================
# Обновление
# =============================================================================
log "Обновление..."
if ! apt-get update -qq; then
    warn_log "apt update завершился с ошибкой (часто 404 у стороннего repo, напр. Ookla) — чистка источников и повтор"
    _apt_cleanup_bad_repos
    apt-get update -qq || warn_log "apt update всё ещё с ошибкой — проверьте /etc/apt/sources.list.d/"
fi
apt-get upgrade -y

log "Зависимости..."
apt install -y curl wget socat unzip tar gnupg2 lsb-release ca-certificates \
    ufw fail2ban apparmor-utils openssl iptables cron jq pwgen git htop xz-utils

# Генерация данных
XUI_USERNAME="admin$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)"
XUI_PASSWORD=$(head /dev/urandom | tr -dc 'A-Za-z0-9@#%_' | head -c 20)
API_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
# Безопасный URI панели (случайный сложный путь)
XUI_WEB_PATH=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 16)
# Безопасный URI подписки (случайный сложный путь)
SUB_PATH=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 24)
ARCH=$(uname -m)

log "Порт: ${CYAN}${RANDOM_PORT}${NC}"
log "Логин: ${CYAN}${XUI_USERNAME}${NC}"
log "Пароль: ${CYAN}${XUI_PASSWORD}${NC}"
log "URI панели: ${CYAN}/${XUI_WEB_PATH}${NC}"
log "URI подписки: ${CYAN}/${SUB_PATH}${NC}"

# =============================================================================
# Протоколы
# =============================================================================
if [[ "$ENABLE_OBFUSCATION" == "y" || "$ENABLE_SHADOWTLS" == "y" || "$ENABLE_HYSTERIA" == "y" || "$ENABLE_TUIC" == "y" ]]; then
    log "Протоколы обхода..."
    
    curl -fsSL -o /tmp/v2ray.sh https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
    bash /tmp/v2ray.sh --force
    rm -f /tmp/v2ray.sh
    systemctl enable --now v2ray 2>/dev/null || true

    if [[ "$ENABLE_HYSTERIA" == "y" ]]; then
        case $ARCH in
            x86_64) HY_BIN="hysteria-linux-amd64" ;;
            aarch64) HY_BIN="hysteria-linux-arm64" ;;
            armv7l) HY_BIN="hysteria-linux-armv7" ;;
            *)
                warn_log "Hysteria: нет готовой сборки для $ARCH — пропуск"
                HY_BIN=""
                ;;
        esac
        if [[ -n "$HY_BIN" ]]; then
            HY_URL=$(curl -sL https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r --arg n "$HY_BIN" '.assets[] | select(.name == $n) | .browser_download_url' | head -n1)
            if [[ -n "$HY_URL" && "$HY_URL" != "null" ]]; then
                if curl -fsSL "$HY_URL" -o /usr/local/bin/hysteria; then
                    chmod +x /usr/local/bin/hysteria
                else
                    warn_log "Hysteria: не удалось скачать бинарник"
                    rm -f /usr/local/bin/hysteria
                fi
            else
                warn_log "Hysteria: в последнем релизе нет asset «${HY_BIN}»"
            fi
        fi
    fi

    if [[ "$ENABLE_TUIC" == "y" ]]; then
        case $ARCH in
            x86_64) TUIC_LA="x86_64-unknown-linux-musl" ;;
            aarch64) TUIC_LA="aarch64-unknown-linux-musl" ;;
            *)
                warn_log "Tuic: нет готовой сборки для $ARCH — пропуск"
                TUIC_LA=""
                ;;
        esac
        if [[ -n "$TUIC_LA" ]]; then
            # Актуальные релизы: https://github.com/tuic-protocol/tuic (старый EAimTY/tuic может давать 404)
            TUIC_META=$(curl -sL https://api.github.com/repos/tuic-protocol/tuic/releases/latest)
            TUIC_URL=""
            for _tuc_suf in "$TUIC_LA" "${TUIC_LA/-musl/-gnu}"; do
                _u=$(echo "$TUIC_META" | jq -r --arg suf "$_tuc_suf" '.assets[] | select(.name | test("^tuic-server-.+-" + $suf + "$")) | .browser_download_url' | head -n1)
                if [[ -n "$_u" && "$_u" != "null" ]]; then
                    TUIC_URL="$_u"
                    break
                fi
            done
            if [[ -n "$TUIC_URL" ]]; then
                if curl -fsSL "$TUIC_URL" -o /usr/local/bin/tuic; then
                    chmod +x /usr/local/bin/tuic
                else
                    warn_log "Tuic: не удалось скачать ${TUIC_URL}"
                    rm -f /usr/local/bin/tuic
                fi
            else
                warn_log "Tuic: не найден подходящий asset для ${TUIC_LA} в репозитории tuic-protocol/tuic"
            fi
        fi
    fi
    
    if [[ "$ENABLE_SHADOWTLS" == "y" ]]; then
        case $ARCH in
            x86_64) STLS_BIN="shadow-tls-x86_64-unknown-linux-musl" ;;
            aarch64) STLS_BIN="shadow-tls-aarch64-unknown-linux-musl" ;;
            armv7l) STLS_BIN="shadow-tls-armv7-unknown-linux-musleabihf" ;;
            armv6l) STLS_BIN="shadow-tls-arm-unknown-linux-musleabi" ;;
            *) error_log "ShadowTLS: архитектура $ARCH не поддерживается"; exit 1 ;;
        esac
        STLS_URL=$(curl -sL https://api.github.com/repos/ihciah/shadow-tls/releases/latest | jq -r --arg n "$STLS_BIN" '.assets[] | select(.name == $n) | .browser_download_url' | head -n1)
        if [[ -n "$STLS_URL" && "$STLS_URL" != "null" ]]; then
            if curl -fsSL "$STLS_URL" -o /usr/local/bin/shadow-tls; then
                chmod +x /usr/local/bin/shadow-tls
            else
                warn_log "ShadowTLS: не удалось скачать ${STLS_BIN}"
                rm -f /usr/local/bin/shadow-tls
            fi
        else
            warn_log "ShadowTLS: не найден asset «${STLS_BIN}» в последнем релизе"
        fi
    fi
fi

# WireGuard
if [[ "$ENABLE_WIREGUARD" == "y" ]]; then
    apt install -y wireguard qrencode
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
    wg genkey | tee /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
    cat > /etc/wireguard/wg0.conf << WGC
[Interface]
Address = 10.0.0.1/24
PrivateKey = $(cat /etc/wireguard/private.key)
ListenPort = 51820
WGC
    systemctl enable wg-quick@wg0 2>/dev/null || true
fi

# =============================================================================
# WARP (Cloudflare)
# =============================================================================
if [[ "$ENABLE_WARP" == "y" ]]; then
    log "WARP (Cloudflare)..."

    # Установка warp-cli
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
        curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg 2>/dev/null
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list 2>/dev/null || true
        apt-get update -qq 2>/dev/null || _apt_cleanup_bad_repos && apt-get update -qq 2>/dev/null || true
    fi

    if apt-get install -y cloudflare-warp 2>/dev/null; then
        success_log "WARP клиент установлен"

        # Регистрация WARP
        warp-cli --accept-tos registration new 2>/dev/null || true
        warp-cli --accept-tos mode warp 2>/dev/null || true
        warp-cli --accept-tos connect 2>/dev/null || true

        # Проверяем статус подключения
        sleep 5
        if warp-cli --accept-tos status 2>/dev/null | grep -qi "connected\|update"; then
            success_log "WARP подключён"
        else
            warn_log "WARP: статус неизвест — проверьте вручную: warp-cli status"
        fi

        # Отключаем WARP от systemd-resolved (может конфликтовать)
        systemctl disable systemd-resolved 2>/dev/null || true
    else
        warn_log "WARP не установлен — пробуем альтернативный метод..."
        # Альтернатива: wgcf (WireGuard Profile for Cloudflare)
        if curl -fsSL https://github.com/ViRb3/wgcf/releases/download/v2.2.21/wgcf_2.2.21_linux_amd64 -o /usr/local/bin/wgcf; then
            chmod +x /usr/local/bin/wgcf
            # Генерируем ключи
            wgcf register --accept-tos 2>/dev/null || true
            wgcf generate 2>/dev/null || true
            if [[ -f wgcf-profile.conf ]]; then
                cp wgcf-profile.conf /etc/wireguard/warp.conf
                systemctl enable --now wg-quick@warp 2>/dev/null || true
                success_log "WARP подключён через wgcf (WireGuard)"
            else
                warn_log "WARP: не удалось сгенерировать профиль wgcf"
            fi
        else
            error_log "WARP: не удалось установить ни warp-cli, ни wgcf"
            ENABLE_WARP="n"
        fi
    fi
fi

# =============================================================================
# UFW
# =============================================================================
log "UFW..."
if [[ "$ENABLE_IPV6" == "y" ]]; then
    sed -i 's/IPV6=no/IPV6=yes/' /etc/default/ufw
fi
ufw --force reset
# Docker мостирует трафик через FORWARD; у UFW по умолчанию DROP → контейнеры без выхода в сеть/NAT.
if [[ "$INSTALL_DOCKER" == "y" ]] && [[ -f /etc/default/ufw ]]; then
    if grep -q '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw; then
        sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    else
        printf '\n# Docker: разрешить forwarding для bridge (docker0)\nDEFAULT_FORWARD_POLICY="ACCEPT"\n' >> /etc/default/ufw
    fi
fi
ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp comment 'SSH'
if [[ "$SETUP_SSH_HARDENING" == "y" && "$SSH_PORT" != "22" ]]; then
    ufw allow "${SSH_PORT}"/tcp comment 'SSH2'
fi
# UFW: один порт на команду (несколько аргументов → ERROR: Wrong number of arguments)
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow "${RANDOM_PORT}"/tcp
if [[ "$ENABLE_OBFUSCATION" == "y" ]]; then
    for _ufw_p in 8080 8443 2053 2083 2087 2096; do
        ufw allow "${_ufw_p}"/tcp
    done
fi
if [[ "$ENABLE_WIREGUARD" == "y" ]]; then
    ufw allow 51820/udp
fi
if [[ "$ENABLE_WARP" == "y" ]]; then
    ufw allow 51820/udp comment 'WARP' 2>/dev/null || ufw allow 51820/udp
fi
if [[ "$ENABLE_HYSTERIA" == "y" ]]; then
    ufw allow 443/udp
fi
if [[ "$INSTALL_PORTAINER" == "y" ]]; then
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" != "y" ]]; then
        ufw allow 9000/tcp comment 'Portainer'
    fi
fi
if [[ "$SETUP_UPTIME_KUMA" == "y" && "$INSTALL_DOCKER" == "y" ]]; then
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" != "y" ]]; then
        ufw allow 3001/tcp comment 'Uptime-Kuma'
    fi
fi

echo "y" | ufw enable

# =============================================================================
# DDoS защита
# =============================================================================
if [[ "$ENABLE_DDOS_PROT" == "y" ]]; then
    cat > /etc/sysctl.d/10-ddos.conf << 'DDOSC'
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_rfc1337=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
DDOSC
    sysctl --system
fi

# =============================================================================
# TCP BBR
# =============================================================================
log "TCP BBR..."
cat > /etc/sysctl.d/10-bbr.conf << 'BBRC'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv6.tcp_congestion_control=bbr
net.ipv4.tcp_tw_reuse=1
BBRC
if [[ "$ENABLE_IPV6" == "y" ]]; then
    echo -e "net.ipv6.conf.all.disable_ipv6=0\nnet.ipv6.conf.default.disable_ipv6=0" >> /etc/sysctl.d/10-bbr.conf
fi
sysctl --system

# =============================================================================
# SSH Hardening
# =============================================================================
if [[ "$SETUP_SSH_HARDENING" == "y" ]]; then
    SSH_BAK="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
    cp /etc/ssh/sshd_config "$SSH_BAK"
    cat > /etc/ssh/sshd_config << SSHC
Port ${SSH_PORT}
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
SSHC
    if sshd -t; then
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || error_log "Не удалось перезапустить SSH"
    else
        error_log "SSH ошибка"
        cp "$SSH_BAK" /etc/ssh/sshd_config
        SSH_PORT="22"
    fi
fi

# =============================================================================
# Fail2ban (после SSH: корректный порт sshd в jail)
# =============================================================================
log "Fail2ban..."
cat > /etc/fail2ban/jail.local << F2BJ
[DEFAULT]
bantime=3600
maxretry=5
banaction=ufw

[sshd]
enabled=true
port=${SSH_PORT}
maxretry=3

[x-ui]
enabled=true
port=8000:65000
logpath=/var/log/x-ui/*.log
maxretry=5
F2BJ

cat > /etc/fail2ban/filter.d/x-ui.conf << 'F2BF'
[Definition]
failregex=.*Failed.*
ignoreregex=
F2BF

mkdir -p /var/log/x-ui
systemctl restart fail2ban
systemctl enable fail2ban

# =============================================================================
# Docker
# =============================================================================
DOCKER_OK=false
if [[ "$INSTALL_DOCKER" == "y" ]]; then
    log "Docker..."

    # Повторный запуск скрипта: Docker может быть уже установлен — тогда не трогаем get.docker.com,
    # просто приводим сервисы в нормальное состояние.
    if ! command -v docker &>/dev/null; then
        if ! curl -fsSL https://get.docker.com | sh; then
            error_log "Docker ошибка"
            INSTALL_DOCKER="n"
            INSTALL_PORTAINER="n"
        fi
    fi

    if [[ "$INSTALL_DOCKER" == "y" ]]; then
        systemctl daemon-reload 2>/dev/null || true
        systemctl reset-failed docker.service docker.socket containerd.service 2>/dev/null || true
        systemctl unmask docker.socket docker.service containerd.service 2>/dev/null || true

        # containerd должен быть запущен; иначе dockerd может падать.
        systemctl enable --now containerd 2>/dev/null || true

        # Ubuntu/Debian: dockerd часто слушает через socket activation (fd://).
        if systemctl cat docker.socket &>/dev/null; then
            systemctl enable --now docker.socket
        fi
        systemctl enable --now docker.service

        if systemctl is-active --quiet docker; then
            DOCKER_OK=true
        else
            error_log "Docker ошибка"
            INSTALL_DOCKER="n"
            INSTALL_PORTAINER="n"
        fi
    fi
fi

# =============================================================================
# X-UI
# =============================================================================
log "X-UI..."

if systemctl is-active --quiet x-ui 2>/dev/null || systemctl is-active --quiet 3x-ui 2>/dev/null; then
    warn_log "X-UI установлен"
    read -r -p "Переустановить? (y/n): " reinstall
    if [[ "$reinstall" != "y" ]]; then
        exit 0
    fi
    systemctl stop x-ui 2>/dev/null || systemctl stop 3x-ui 2>/dev/null || true
    rm -rf /usr/local/x-ui /etc/systemd/system/x-ui.service
fi

cd /root
LATEST_VER=$(curl -s "https://api.github.com/repos/${XUI_REPO}/releases/latest" | grep -oP '"tag_name": "\K[^"]+')
if [[ -z "$LATEST_VER" ]]; then
    error_log "Версия не получена"
    exit 1
fi

case $ARCH in
    x86_64) FNAME="x-ui-linux-amd64" ;;
    aarch64) FNAME="x-ui-linux-arm64" ;;
    armv7l) FNAME="x-ui-linux-arm32" ;;
    armv6l) FNAME="x-ui-linux-arm32v6" ;;
    i686|i386) FNAME="x-ui-linux-x86" ;;
    riscv64) FNAME="x-ui-linux-riscv64" ;;
    *) error_log "Архитектура: $ARCH (не поддерживается)"; exit 1 ;;
esac

log "Загрузка X-UI ${LATEST_VER}..."
XUI_TARBALL="/root/${FNAME}.tar.gz"
XUI_TMPDIR="$(mktemp -d)"
XUI_DL_URL="https://github.com/${XUI_REPO}/releases/download/${LATEST_VER}/${FNAME}.tar.gz"
if ! curl -fsSL "$XUI_DL_URL" -o "${XUI_TARBALL}"; then
    error_log "Загрузка X-UI: 404 или сеть — ${XUI_DL_URL}"
    rm -rf "${XUI_TMPDIR}"
    exit 1
fi
tar -xzf "${XUI_TARBALL}" -C "${XUI_TMPDIR}"

# В разных релизах папка внутри архива может называться по-разному (часто просто `x-ui/`).
XUI_SRC_DIR=""
if [[ -d "${XUI_TMPDIR}/${FNAME}" ]]; then
    XUI_SRC_DIR="${XUI_TMPDIR}/${FNAME}"
elif [[ -d "${XUI_TMPDIR}/x-ui" ]]; then
    XUI_SRC_DIR="${XUI_TMPDIR}/x-ui"
else
    first_dir="$(find "${XUI_TMPDIR}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -n "${first_dir}" ]]; then
        XUI_SRC_DIR="${first_dir}"
    fi
fi

if [[ -z "${XUI_SRC_DIR}" || ! -f "${XUI_SRC_DIR}/x-ui" ]]; then
    error_log "Не найден бинарник x-ui в архиве (${FNAME}.tar.gz)"
    rm -rf "${XUI_TMPDIR}"
    exit 1
fi

rm -rf /usr/local/x-ui
mv "${XUI_SRC_DIR}" /usr/local/x-ui
rm -rf "${XUI_TMPDIR}"

# Обход проверки версии
if [[ -f /usr/local/x-ui/x-ui ]]; then
    chmod +x /usr/local/x-ui/x-ui
fi

# Symlink для команды x-ui
if [[ ! -f /usr/local/bin/x-ui ]]; then
    ln -sf /usr/local/x-ui/x-ui /usr/local/bin/x-ui
    log "Symlink: /usr/local/bin/x-ui -> /usr/local/x-ui/x-ui"
fi

cat > /etc/systemd/system/x-ui.service << 'XUISVC'
[Unit]
Description=X-UI Panel
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/x-ui/x-ui
ExecStop=/bin/kill -15 $MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
XUISVC

systemctl daemon-reload
systemctl enable x-ui

# =============================================================================
# Инициализация учётных данных X-UI
# =============================================================================
log "Настройка учётных данных X-UI..."
if [[ -f /usr/local/x-ui/x-ui ]]; then
    # x-ui setting — установка логина, пароля и порта без интерактива
    # Используем expect-подоб подход через x-ui команды
    cd /usr/local/x-ui
    # Инициализация БД (первый запуск создаёт x-ui.db)
    if [[ ! -f /usr/local/x-ui/x-ui.db ]]; then
        # Запускаем x-ui на 5 секунд чтобы он создал БД, затем останавливаем
        timeout 5 ./x-ui >/dev/null 2>&1 || true
        sleep 2
        systemctl stop x-ui 2>/dev/null || pkill -f '/usr/local/x-ui/x-ui' 2>/dev/null || true
        sleep 2
    fi

    # Определяем пути к SSL сертификатам для x-ui panel
    XUI_CERT=""
    XUI_KEY=""
    if [[ "$USE_ZEROSL" == "y" ]]; then
        XUI_CERT="/usr/local/x-ui/cert/fullchain.crt"
        XUI_KEY="/usr/local/x-ui/cert/server.key"
    elif [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
        XUI_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
        XUI_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
    fi

    # Устанавливаем учётные данные через x-ui commands
    # x-ui username и x-ui password — стандартные команды для 3x-ui
    if [[ -n "$XUI_CERT" && -n "$XUI_KEY" ]]; then
        log "Настройка SSL и URI для x-ui panel..."
        /usr/local/x-ui/x-ui setting \
            -username "${XUI_USERNAME}" \
            -password "${XUI_PASSWORD}" \
            -port "${RANDOM_PORT}" \
            -cert "$XUI_CERT" \
            -key "$XUI_KEY" \
            -webBasePath "/${XUI_WEB_PATH}" 2>/dev/null && \
            success_log "Учётные данные, SSL и URI установлены" || \
            warn_log "x-ui setting с SSL/URI не поддерживается — пробуем без SSL"
    fi

    # Fallback: без SSL параметров
    if ! /usr/local/x-ui/x-ui setting -username "${XUI_USERNAME}" &>/dev/null; then
        warn_log "Пробуем альтернативный метод установки учётных данных..."
        # Генерируем хеш пароля и записываем прямо в БД через SQLite
        if command -v sqlite3 &>/dev/null || apt-get install -y sqlite3 &>/dev/null; then
            PASS_HASH=$(/usr/local/x-ui/x-ui -hash "${XUI_PASSWORD}" 2>/dev/null || echo "")
            if [[ -n "$PASS_HASH" && -f /usr/local/x-ui/x-ui.db ]]; then
                sqlite3 /usr/local/x-ui/x-ui.db "UPDATE user SET username='${XUI_USERNAME}', password='${PASS_HASH}' WHERE id=1;" 2>/dev/null || true
                success_log "Учётные данные установлены через БД"
            else
                warn_log "Не удалось создать хеш пароля — используйте x-ui меню"
            fi
        fi
    else
        success_log "Учётные данные установлены"
    fi

    # Если SSL не настроен через setting, копируем сертификаты в папку x-ui
    # и создаём конфиг для panel
    if [[ -n "$XUI_CERT" && -n "$XUI_KEY" ]]; then
        # Убеждаемся что x-ui видит сертификаты
        if [[ ! -f "$XUI_CERT" ]]; then
            warn_log "SSL сертификат не найден: $XUI_CERT"
        fi
        if [[ ! -f "$XUI_KEY" ]]; then
            warn_log "SSL ключ не найден: $XUI_KEY"
        fi
        # Создаём symlink из letsencrypt в папку x-ui для надёжности
        if [[ "$USE_ZEROSL" != "y" && -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
            mkdir -p /usr/local/x-ui/cert
            ln -sf "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" /usr/local/x-ui/cert/server.crt
            ln -sf "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" /usr/local/x-ui/cert/server.key
            log "Symlink SSL: /usr/local/x-ui/cert -> Let's Encrypt"
        fi
    fi
fi

# =============================================================================
# AppArmor
# =============================================================================
if [[ "$ENABLE_APPARMOR" == "y" && -f /usr/local/x-ui/x-ui ]]; then
    cat > /etc/apparmor.d/usr.local.x-ui.x-ui << 'AASVC'
#include <tunables/global>
/usr/local/x-ui/x-ui flags=(complain) {
  #include <abstractions/base>
  network inet tcp,
  network inet udp,
  /usr/local/x-ui/** r,
  /var/log/x-ui/** rw,
}
AASVC
    aa-complain /usr/local/x-ui/x-ui 2>/dev/null || true
fi

# =============================================================================
# 2FA
# =============================================================================
if [[ "$ENABLE_2FA" == "y" ]]; then
    apt install -y libpam-google-authenticator qrencode
    if [[ ! -f /root/.google_authenticator ]]; then
        google-authenticator -t -d -f -r 3 -R 30 -w 3
    else
        warn_log "2FA: /root/.google_authenticator уже есть — пропуск google-authenticator"
    fi
    if ! grep -q 'pam_google_authenticator' /etc/pam.d/common-auth; then
        echo "auth required pam_google_authenticator.so" >> /etc/pam.d/common-auth
    fi
fi

# =============================================================================
# SSL
# =============================================================================
log "SSL..."
SSL_OK=false

# Один сертификат на основной домен + поддомены Portainer/Kuma (если включены)
LE_DOMAIN_ARGS=( -d "$DOMAIN" )
[[ -n "$PORTAINER_HTTPS_HOST" ]] && LE_DOMAIN_ARGS+=( -d "$PORTAINER_HTTPS_HOST" )
[[ -n "$KUMA_HTTPS_HOST" ]] && LE_DOMAIN_ARGS+=( -d "$KUMA_HTTPS_HOST" )

systemctl stop nginx 2>/dev/null || true

if [[ "$USE_ZEROSL" == "y" ]]; then
    # shellcheck disable=SC1090
    if curl https://get.acme.sh | sh -s email="${SSL_EMAIL}" && source ~/.bashrc; then
        ~/.acme.sh/acme.sh --register-account -m "${SSL_EMAIL}"
        ACME_ISSUE=( --issue -d "$DOMAIN" )
        [[ -n "$PORTAINER_HTTPS_HOST" ]] && ACME_ISSUE+=( -d "$PORTAINER_HTTPS_HOST" )
        [[ -n "$KUMA_HTTPS_HOST" ]] && ACME_ISSUE+=( -d "$KUMA_HTTPS_HOST" )
        ACME_ISSUE+=( --standalone --force )
        if ~/.acme.sh/acme.sh "${ACME_ISSUE[@]}"; then
            mkdir -p /usr/local/x-ui/cert
            ~/.acme.sh/acme.sh --install-cert -d "${DOMAIN}" \
                --cert-file /usr/local/x-ui/cert/server.crt \
                --key-file /usr/local/x-ui/cert/server.key \
                --fullchain-file /usr/local/x-ui/cert/fullchain.crt
            SSL_OK=true
        fi
    fi
    if [[ "$SSL_OK" != "true" ]]; then
        USE_ZEROSL="n"
    fi
fi

if [[ "$USE_ZEROSL" != "y" ]]; then
    apt install -y certbot
    if [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]]; then
        warn_log "SSL: Let's Encrypt — обновление/расширение сертификата и копирование в x-ui"
        certbot certonly --standalone --cert-name "$DOMAIN" --expand --non-interactive --agree-tos --email "${SSL_EMAIL}" "${LE_DOMAIN_ARGS[@]}" || \
            warn_log "certbot expand: если не прошло — проверьте DNS для поддоменов"
        certbot renew --non-interactive --cert-name "$DOMAIN" 2>/dev/null || certbot renew --non-interactive 2>/dev/null || true
        mkdir -p /usr/local/x-ui/cert
        cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem /usr/local/x-ui/cert/server.crt
        cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem /usr/local/x-ui/cert/server.key
        chmod 600 /usr/local/x-ui/cert/server.key
        SSL_OK=true
    elif certbot certonly --standalone --non-interactive --agree-tos --email "${SSL_EMAIL}" "${LE_DOMAIN_ARGS[@]}"; then
        mkdir -p /usr/local/x-ui/cert
        cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem /usr/local/x-ui/cert/server.crt
        cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem /usr/local/x-ui/cert/server.key
        chmod 600 /usr/local/x-ui/cert/server.key
        SSL_OK=true
    fi
fi

# =============================================================================
# Nginx
# =============================================================================
log "Nginx..."
apt install -y nginx

cat > /var/www/html/index.html << 'CATHTML'
<!DOCTYPE html><html lang="ru"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Кото-Сервер</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:sans-serif;background:linear-gradient(135deg,#2c1810,#1a1a2e);min-height:100vh;color:#fff;display:flex;align-items:center;justify-content:center;overflow:hidden;position:relative}.container{text-align:center;padding:40px;z-index:10;position:relative}.cat{font-size:100px;animation:bounce 2s infinite}@keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-20px)}}h1{font-size:3rem;background:linear-gradient(90deg,#ff9a56,#ff6b6b);-webkit-background-clip:text;-webkit-text-fill-color:transparent}p{color:#b8a092;margin:20px 0}.status{display:inline-block;padding:10px 25px;background:rgba(102,252,143,0.1);border:2px solid #66fc91;border-radius:50px;color:#66fc91}.flying-cat{position:fixed;font-size:40px;opacity:0.7;animation:fly linear infinite;pointer-events:none;z-index:1}@keyframes fly{0%{transform:translateX(-100px) rotate(0deg) scale(0.6)}25%{transform:translateX(25vw) rotate(15deg) scale(0.8) translateY(-30px)}50%{transform:translateX(50vw) rotate(-10deg) scale(1) translateY(-15px)}75%{transform:translateX(75vw) rotate(20deg) scale(0.9) translateY(-40px)}100%{transform:translateX(calc(100vw + 100px)) rotate(0deg) scale(0.6)}}.flying-cat:nth-child(1){top:10%;animation-duration:12s;animation-delay:0s;font-size:36px}.flying-cat:nth-child(2){top:25%;animation-duration:15s;animation-delay:3s;font-size:44px}.flying-cat:nth-child(3){top:45%;animation-duration:10s;animation-delay:1s;font-size:32px}.flying-cat:nth-child(4){top:60%;animation-duration:18s;animation-delay:5s;font-size:50px}.flying-cat:nth-child(5){top:75%;animation-duration:14s;animation-delay:2s;font-size:38px}.flying-cat:nth-child(6){top:85%;animation-duration:11s;animation-delay:7s;font-size:42px}.flying-cat:nth-child(7){top:5%;animation-duration:16s;animation-delay:4s;font-size:30px}.flying-cat:nth-child(8){top:50%;animation-duration:13s;animation-delay:6s;font-size:46px}.flying-cat:nth-child(9){top:35%;animation-duration:17s;animation-delay:8s;font-size:34px}.flying-cat:nth-child(10){top:90%;animation-duration:9s;animation-delay:1s;font-size:40px}</style></head>
<body>
<div class="flying-cat">🐱</div>
<div class="flying-cat">🐈</div>
<div class="flying-cat">😺</div>
<div class="flying-cat">🐱</div>
<div class="flying-cat">😸</div>
<div class="flying-cat">🐈‍⬛</div>
<div class="flying-cat">🐱</div>
<div class="flying-cat">😻</div>
<div class="flying-cat">🐈</div>
<div class="flying-cat">😺</div>
<div class="container"><div class="cat">🐱</div><h1>Мяу-Сервер</h1><p>Сервер охраняется котиками 24/7</p><div class="status">Онлайн</div></div></body></html>
CATHTML

IPV6_HTTP=""
IPV6_HTTPS=""
if [[ "$ENABLE_IPV6" == "y" ]]; then
    IPV6_HTTP="    listen [::]:80;"
    IPV6_HTTPS="    listen [::]:443 ssl http2;"
fi

# Определяем пути к SSL сертификатам
if [[ "$USE_ZEROSL" == "y" ]]; then
    SSL_CERT_PATH="/usr/local/x-ui/cert/fullchain.crt"
    SSL_KEY_PATH="/usr/local/x-ui/cert/server.key"
else
    SSL_CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    SSL_KEY_PATH="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
fi

DOCKER_NGINX_EXTRA=""
if [[ -n "$PORTAINER_HTTPS_HOST" ]]; then
    DOCKER_NGINX_EXTRA+=$(cat <<PNBLK

server {
    listen 80;
    ${IPV6_HTTP}
    server_name ${PORTAINER_HTTPS_HOST};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    ${IPV6_HTTPS}
    server_name ${PORTAINER_HTTPS_HOST};
    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    server_tokens off;
}
PNBLK
)
fi
if [[ -n "$KUMA_HTTPS_HOST" ]]; then
    DOCKER_NGINX_EXTRA+=$(cat <<KMBLK

server {
    listen 80;
    ${IPV6_HTTP}
    server_name ${KUMA_HTTPS_HOST};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl http2;
    ${IPV6_HTTPS}
    server_name ${KUMA_HTTPS_HOST};
    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    server_tokens off;
}
KMBLK
)
fi

cat > /etc/nginx/sites-available/default << NGC
server {
    listen 80;
    ${IPV6_HTTP}
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    ${IPV6_HTTPS}
    server_name ${DOMAIN};
    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;
    root /var/www/html;
    index index.html;

    # Reverse proxy к X-UI панели
    location /${XUI_WEB_PATH}/ {
        proxy_pass http://127.0.0.1:${RANDOM_PORT}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    # Без слэша — редирект на слэш для корректной работы
    location =/${XUI_WEB_PATH} {
        return 301 https://\$server_name/${XUI_WEB_PATH}/;
    }

    # Reverse proxy к подпискам X-UI
    location /${SUB_PATH}/ {
        # Раздаём статический base64 файл подписки
        alias /usr/local/x-ui/subscription-b64.txt;
        default_type 'text/plain; charset=utf-8';
        add_header Access-Control-Allow-Origin '*' always;
        add_header Cache-Control 'no-cache, no-store, must-revalidate' always;
    }
    location =/${SUB_PATH} {
        return 301 https://\$server_name/${SUB_PATH}/;
    }

    location / { try_files \$uri \$uri/ =404; }
    server_tokens off;
}
${DOCKER_NGINX_EXTRA}
NGC

systemctl restart nginx
systemctl enable nginx

# Portainer / Uptime Kuma — после Nginx (TLS на :443, backend на loopback)
if [[ "$INSTALL_PORTAINER" == "y" && "$DOCKER_OK" == "true" ]]; then
    docker volume create portainer_data
    docker rm -f portainer 2>/dev/null || true
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" == "y" ]]; then
        docker run -d --name portainer --restart=always -p 127.0.0.1:9000:9000 \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
            portainer/portainer-ce:latest
    else
        docker run -d --name portainer --restart=always -p 9000:9000 \
            -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data \
            portainer/portainer-ce:latest
    fi
fi
if [[ "$SETUP_UPTIME_KUMA" == "y" && "$DOCKER_OK" == "true" ]]; then
    docker rm -f uptime-kuma 2>/dev/null || true
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" == "y" ]]; then
        docker run -d --name uptime-kuma --restart=always -p 127.0.0.1:3001:3001 \
            -v uptime-kuma:/app/data louislam/uptime-kuma:1
    else
        docker run -d --name uptime-kuma --restart=always -p 3001:3001 \
            -v uptime-kuma:/app/data louislam/uptime-kuma:1
    fi
fi

# =============================================================================
# Протоколы
# =============================================================================
log "Протоколы..."

if [[ "$INSTALL_TROJAN_GO" == "y" ]]; then
    TJ_VER=$(curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest | grep -oP '"tag_name": "\K[v0-9.]+')
    [[ -z "$TJ_VER" ]] && TJ_VER="v0.10.6"
    case $ARCH in
        x86_64) TJ_ZIP="trojan-go-linux-amd64.zip" ;;
        aarch64) TJ_ZIP="trojan-go-linux-arm64.zip" ;;
        armv7l) TJ_ZIP="trojan-go-linux-armv7.zip" ;;
        *)
            warn_log "Trojan-Go: нет сборки для $ARCH — пропуск"
            TJ_ZIP=""
            ;;
    esac
    if [[ -n "$TJ_ZIP" ]]; then
        if curl -fsSL "https://github.com/p4gefau1t/trojan-go/releases/download/${TJ_VER}/${TJ_ZIP}" -o /tmp/tj.zip; then
            unzip -o /tmp/tj.zip -d /usr/local/bin/
            rm -f /tmp/tj.zip
            chmod +x /usr/local/bin/trojan-go
            ufw allow 443/tcp comment 'Trojan' 2>/dev/null || true
        else
            warn_log "Trojan-Go: загрузка ${TJ_ZIP} не удалась"
            rm -f /tmp/tj.zip
        fi
    fi
fi

if [[ "$INSTALL_BROOK" == "y" ]]; then
    BK_VER=$(curl -s https://api.github.com/repos/txthinking/brook/releases/latest | grep -oP '"tag_name": "\K[v0-9.]+')
    [[ -z "$BK_VER" ]] && BK_VER="v20240214"
    case $ARCH in
        x86_64) BK_BIN="brook_linux_amd64" ;;
        aarch64) BK_BIN="brook_linux_arm64" ;;
        armv7l) BK_BIN="brook_linux_armv7" ;;
        *)
            warn_log "Brook: нет сборки для $ARCH — пропуск"
            BK_BIN=""
            ;;
    esac
    if [[ -n "$BK_BIN" ]]; then
        if curl -fsSL "https://github.com/txthinking/brook/releases/download/${BK_VER}/${BK_BIN}" -o /usr/local/bin/brook; then
            chmod +x /usr/local/bin/brook
            ufw allow 9999/tcp comment 'Brook' 2>/dev/null || true
        else
            warn_log "Brook: загрузка не удалась"
            rm -f /usr/local/bin/brook
        fi
    fi
fi

if [[ "$INSTALL_SINGBOX" == "y" ]]; then
    SB_VER=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep -oP '"tag_name": "\K[v0-9.]+')
    if [[ -z "$SB_VER" ]]; then
        error_log "sing-box: версия не получена"
        exit 1
    fi
    SB_NOPREFIX="${SB_VER#v}"
    case $ARCH in
        x86_64) SB_LA=amd64 ;;
        aarch64) SB_LA=arm64 ;;
        armv7l) SB_LA=armv7 ;;
        armv6l) SB_LA=armv6 ;;
        i686|i386) SB_LA=386 ;;
        riscv64) SB_LA=riscv64 ;;
        *) error_log "sing-box: архитектура $ARCH не поддерживается"; exit 1 ;;
    esac
    SB_TGZ="sing-box-${SB_NOPREFIX}-linux-${SB_LA}.tar.gz"
    SB_DL="https://github.com/SagerNet/sing-box/releases/download/${SB_VER}/${SB_TGZ}"
    if curl -fsSL "$SB_DL" -o /tmp/sb.tar.gz; then
        tar -xzf /tmp/sb.tar.gz -C /tmp/
        mv "/tmp/sing-box-${SB_NOPREFIX}-linux-${SB_LA}/sing-box" /usr/local/bin/
        rm -rf /tmp/sb.tar.gz /tmp/sing-box-*
        chmod +x /usr/local/bin/sing-box
    else
        warn_log "sing-box: не удалось скачать ${SB_TGZ} (404 или сеть)"
        rm -f /tmp/sb.tar.gz
    fi
fi

# =============================================================================
# Данные
# =============================================================================
log "Сохранение..."

PORTAINER_CRED_LINE=""
KUMA_CRED_LINE=""
if [[ -n "$PORTAINER_HTTPS_HOST" ]]; then
    PORTAINER_CRED_LINE="Portainer (HTTPS): https://${PORTAINER_HTTPS_HOST}
"
fi
if [[ -n "$KUMA_HTTPS_HOST" ]]; then
    KUMA_CRED_LINE="Uptime Kuma (HTTPS): https://${KUMA_HTTPS_HOST}
"
fi

cat > /root/x-ui-credentials.txt << CREDS
╔═══════════════════════════════════════════════════════════╗
║              X-UI Panel Credentials                       ║
╠═══════════════════════════════════════════════════════════╣
Дата: $(date '+%Y-%m-%d %H:%M:%S')
Домен: ${DOMAIN}
URL: https://${DOMAIN}/${XUI_WEB_PATH}/
Внутренний порт X-UI: ${RANDOM_PORT}
URI панели: /${XUI_WEB_PATH}
URI подписки: /${SUB_PATH}
Логин: ${XUI_USERNAME}
Пароль: ${XUI_PASSWORD}
SSH Порт: ${SSH_PORT}
API Key: ${API_KEY}
${PORTAINER_CRED_LINE}${KUMA_CRED_LINE}╠═══════════════════════════════════════════════════════════╣
Команды: x-ui start|stop|restart|status|log
╚═══════════════════════════════════════════════════════════╝
CREDS

chmod 600 /root/x-ui-credentials.txt

# =============================================================================
# Автообновление
# =============================================================================
if [[ "$ENABLE_AUTO_UPDATE" == "y" ]]; then
    cat > /usr/local/x-ui/auto-update.sh << AUTOU
#!/bin/bash
LOG="/var/log/x-ui-autoupdate.log"
CUR=\$(x-ui version 2>/dev/null || echo "unknown")
LAT=\$(curl -s https://api.github.com/repos/${XUI_REPO}/releases/latest | grep -oP '"tag_name": "\K[^"]+')
[[ -z "\$LAT" ]] && exit 0
if [[ "\$CUR" != "\$LAT" ]]; then
    echo "[\$(date)] Update \$CUR -> \$LAT" >> "\$LOG"
    x-ui update
    systemctl restart x-ui
fi
AUTOU
    chmod +x /usr/local/x-ui/auto-update.sh
    _cron_set_line "0 3 * * * /usr/local/x-ui/auto-update.sh"
fi

# =============================================================================
# Автобэкап
# =============================================================================
if [[ "$ENABLE_AUTO_BACKUP" == "y" ]]; then
    mkdir -p "$BACKUP_PATH"
    cat > /usr/local/x-ui/backup.sh << BACKUP
#!/bin/bash
BD="${BACKUP_PATH}"
DT=\$(date +%Y%m%d_%H%M%S)
cp /usr/local/x-ui/x-ui.db "\${BD}/x-ui-db-\${DT}.bak" 2>/dev/null
cd "\${BD}" && ls -t *.bak 2>/dev/null | tail -n +11 | xargs -r rm
echo "[\$(date)] Backup: \${DT}" >> /var/log/x-ui-backup.log
BACKUP
    chmod +x /usr/local/x-ui/backup.sh
    _cron_set_line "0 3 * * * /usr/local/x-ui/backup.sh"
fi

# =============================================================================
# Telegram
# =============================================================================
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    cat > /usr/local/x-ui/telegram-notify.sh << TGNOT
#!/bin/bash
BOT="${TELEGRAM_BOT_TOKEN}"
CHAT="${TELEGRAM_CHAT_ID}"
curl -s -X POST "https://api.telegram.org/bot\${BOT}/sendMessage" -d "chat_id=\${CHAT}&text=\$1&parse_mode=HTML" > /dev/null
TGNOT
    chmod +x /usr/local/x-ui/telegram-notify.sh
    /usr/local/x-ui/telegram-notify.sh "🟢 X-UI: ${DOMAIN}"
fi

# =============================================================================
# Discord
# =============================================================================
if [[ -n "$DISCORD_WEBHOOK" ]]; then
    cat > /usr/local/x-ui/discord-notify.sh << DCNOT
#!/bin/bash
curl -s -X POST "${DISCORD_WEBHOOK}" -H "Content-Type: application/json" -d "{\"content\":\"\$1\"}" > /dev/null
DCNOT
    chmod +x /usr/local/x-ui/discord-notify.sh
fi

# =============================================================================
# Подписки
# =============================================================================
if [[ "$CREATE_SUBSCRIPTION" == "y" ]]; then
    RANDOM_PORT=$(cat /root/x-ui-port.txt 2>/dev/null || echo "$RANDOM_PORT")
    cat > /usr/local/x-ui/generate-subscription.sh << SUBSH
#!/bin/bash
SUB="/usr/local/x-ui/subscriptions.txt"
DOMAIN=\$(grep "Домен:" /root/x-ui-credentials.txt 2>/dev/null | awk '{print \$2}')
SUB_URI=\$(grep "URI подписки:" /root/x-ui-credentials.txt 2>/dev/null | awk '{print \$3}')
[[ -z "\$SUB_URI" ]] && SUB_URI=\$(cat /root/x-ui-sub-path.txt 2>/dev/null)
[[ -z "\$SUB_URI" ]] && SUB_URI="sub"
echo "# X-UI Subscriptions - \$(date)" > "\$SUB"
x-ui link 2>/dev/null | grep -iE 'vless|trojan|vmess' >> "\$SUB" || echo "No links" >> "\$SUB"
base64 -w0 "\$SUB" > /usr/local/x-ui/subscription-b64.txt
echo "URL: https://\${DOMAIN}\${SUB_URI}/"
echo "Подписка доступна через HTTPS (порт 443) с SSL-сертификатом"
SUBSH
    chmod +x /usr/local/x-ui/generate-subscription.sh
    # Сохраняем URI подписки для справки
    echo "${SUB_PATH}" > /root/x-ui-sub-path.txt
    chmod 600 /root/x-ui-sub-path.txt
fi

# =============================================================================
# QR коды
# =============================================================================
if [[ "$GENERATE_QR" == "y" ]]; then
    apt install -y qrencode
    cat > /usr/local/x-ui/generate-qr.sh << 'QRSH'
#!/bin/bash
QRD="/usr/local/x-ui/qr-codes"
mkdir -p "$QRD"
x-ui link 2>/dev/null | while read -r link; do
    if [[ "$link" =~ ^(vless|trojan|vmess|ss):// ]]; then
        NM=$(echo "$link" | sed 's/.*#//' | tr -d ' ')
        if [[ -z "$NM" ]]; then
            NM="cfg_$(date +%s)"
        fi
        echo "$link" | qrencode -o "$QRD/${NM}.png" -s 8
    fi
done
echo "QR saved to: $QRD"
QRSH
    chmod +x /usr/local/x-ui/generate-qr.sh
fi

# =============================================================================
# REST API
# =============================================================================
if [[ "$CREATE_API" == "y" ]]; then
    log "REST API..."
    apt install -y python3-flask

    cat > /usr/local/x-ui/api.py << APIPY
#!/usr/bin/env python3
from flask import Flask, jsonify, request
import subprocess

app = Flask(__name__)
API_KEY = "${API_KEY}"

def auth():
    return request.headers.get('Authorization') == f"Bearer {API_KEY}"

@app.route('/api/status', methods=['GET'])
def status():
    if not auth():
        return jsonify({"error": "Unauthorized"}), 401
    r = subprocess.run(['x-ui', 'status'], capture_output=True, text=True)
    return jsonify({"status": "ok", "output": r.stdout})

@app.route('/api/links', methods=['GET'])
def links():
    if not auth():
        return jsonify({"error": "Unauthorized"}), 401
    r = subprocess.run(['x-ui', 'link'], capture_output=True, text=True)
    return jsonify({"status": "ok", "links": r.stdout.strip().split('\n')})

@app.route('/api/restart', methods=['POST'])
def restart():
    if not auth():
        return jsonify({"error": "Unauthorized"}), 401
    subprocess.run(['systemctl', 'restart', 'x-ui'])
    return jsonify({"status": "ok", "message": "X-UI restarted"})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080)
APIPY

    chmod +x /usr/local/x-ui/api.py
    
    cat > /etc/systemd/system/x-ui-api.service << 'APISVC'
[Unit]
Description=X-UI REST API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/x-ui/api.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
APISVC

    systemctl daemon-reload
    systemctl enable x-ui-api
    if systemctl start x-ui-api && systemctl is-active --quiet x-ui-api; then
        success_log "API запущен (порт 8080)"
    else
        warn_log "API не запустился"
    fi
fi

# =============================================================================
# Конвертер
# =============================================================================
if [[ "$INSTALL_LINK_CONVERTER" == "y" ]]; then
    cat > /usr/local/x-ui/link-converter.sh << 'CONVSH'
#!/bin/bash
echo "1) To Base64  2) From Base64  3) To QR  4) Exit"
read -r -p "Choice: " c
case $c in
    1) read -r -p "Link: " l; echo "$l" | base64 -w0 ;;
    2) read -r -p "Base64: " b; echo "$b" | base64 -d ;;
    3) read -r -p "Link: " l; echo "$l" | qrencode -o - -t ansi ;;
esac
CONVSH
    chmod +x /usr/local/x-ui/link-converter.sh
fi

# =============================================================================
# Speedtest
# =============================================================================
if [[ "$INSTALL_SPEEDTEST" == "y" ]]; then
    log "Speedtest..."
    # Репозиторий Ookla (packagecloud):
    # - на новых релизах (например Ubuntu noble) может не быть Release → apt update падает
    # - при ошибке откатываем repo и ставим speedtest-cli из репозитория дистрибутива
    ST_SH=$(mktemp)
    if curl -fsSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh -o "${ST_SH}"; then
        bash "${ST_SH}" || warn_log "Ookla: ошибка при подключении репозитория (продолжаем с apt)"
    else
        warn_log "Ookla: не удалось скачать script.deb.sh"
    fi
    rm -f "${ST_SH}"
    if apt-get update -qq; then
        if apt-get install -y speedtest; then
            success_log "Установлен speedtest (Ookla)"
        else
            warn_log "Пакет speedtest не найден — ставлю speedtest-cli из репозитория"
            apt-get install -y speedtest-cli
            success_log "Команда: speedtest-cli (дистрибутив, не бинарник Ookla)"
        fi
    else
        warn_log "APT update упал (часто из-за packagecloud Release). Убираю repo Ookla и ставлю speedtest-cli."
        rm -f /etc/apt/sources.list.d/*ookla* /etc/apt/sources.list.d/*speedtest* 2>/dev/null || true
        # На всякий случай — удаляем строки packagecloud ookla из любых *.list
        sed -i '/packagecloud\.io\/ookla\/speedtest-cli/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true
        apt-get update -qq || true
        apt-get install -y speedtest-cli
        success_log "Команда: speedtest-cli (дистрибутив, репозиторий Ookla отключён)"
    fi
fi

# =============================================================================
# Health Check
# =============================================================================
cat > /usr/local/x-ui/health-check.sh << 'HLTHSH'
#!/bin/bash
LOG="/var/log/x-ui-health.log"
ALERT="/var/log/x-ui-alert.log"
check() {
    if systemctl is-active --quiet "$2"; then
        echo "[OK] $1" >> "$LOG"
    else
        echo "[FAIL] $1" >> "$ALERT"
        systemctl restart "$2"
    fi
}
check "X-UI" "x-ui"
check "Nginx" "nginx"
check "Fail2ban" "fail2ban"
D=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [[ $D -gt 90 ]]; then
    echo "[WARN] Disk: ${D}%" >> "$ALERT"
fi
HLTHSH
chmod +x /usr/local/x-ui/health-check.sh
_cron_set_line "*/5 * * * * /usr/local/x-ui/health-check.sh"

# =============================================================================
# Очистка
# =============================================================================
if [[ "$ENABLE_CLEANUP" == "y" ]]; then
    apt autoremove -y
    apt autoclean
    journalctl --vacuum-time=7d
    if [[ -n "$FNAME" ]]; then
        rm -f /root/${FNAME}.tar.gz
    fi
    rm -f /tmp/*.sh /tmp/*.tar.gz /tmp/*.zip 2>/dev/null || true
fi

# =============================================================================
# Запуск
# =============================================================================
log "Запуск X-UI..."

# Проверяем что бинарник существует и исполняемый
if [[ ! -x /usr/local/x-ui/x-ui ]]; then
    error_log "Бинарник x-ui не найден или не исполняемый"
    ls -la /usr/local/x-ui/ 2>/dev/null || true
else
    success_log "Бинарник x-ui: $(file /usr/local/x-ui/x-ui)"
fi

# Проверяем что БД существует
if [[ ! -f /usr/local/x-ui/x-ui.db ]]; then
    warn_log "БД x-ui.db отсутствует — x-ui создаст её при первом запуске"
fi

# Сбрасываем failed-состояние сервиса
systemctl reset-failed x-ui 2>/dev/null || true

# Перезапускаем сервис (не просто start, чтобы подхватить настройки)
systemctl restart x-ui

# Ждём инициализации (x-ui может грузиться до 10 секунд)
log "Ожидание инициализации x-ui..."
for i in $(seq 1 15); do
    if systemctl is-active --quiet x-ui; then
        success_log "X-UI запущен (через ${i} сек)"
        break
    fi
    if [[ $i -eq 15 ]]; then
        error_log "X-UI не запустился за 15 секунд"
        echo ""
        error_log "=== Диагностика ==="
        echo "Status:"
        systemctl status x-ui --no-pager 2>&1 | head -20
        echo ""
        echo "Last journal entries:"
        journalctl -u x-ui --no-pager -n 15 2>&1 | tail -15
        echo ""
        # Проверяем не упал ли по сегфолту
        if dmesg 2>/dev/null | grep -i "x-ui\|segfault" | tail -3; then
            error_log "Возможен segfault — проверьте dmesg"
        fi
        # Проверяем AppArmor
        if dmesg 2>/dev/null | grep -i "apparmor.*x-ui" | tail -3; then
            warn_log "AppArmor может блокировать x-ui"
        fi
        echo ""
        warn_log "Попробуйте: x-ui (меню) для ручной настройки"
        warn_log "Или: /usr/local/x-ui/x-ui (прямой запуск для отладки)"
        break
    fi
    sleep 1
done

# =============================================================================
# Финал
# =============================================================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ Установка завершена! v1.0.3                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Информация:${NC}"
echo -e "  Домен:     ${YELLOW}${DOMAIN}${NC}"
echo -e "  Порт:      ${YELLOW}${RANDOM_PORT}${NC}"
echo -e "  SSH:       ${YELLOW}${SSH_PORT}${NC}"
if [[ "$ENABLE_IPV6" == "y" ]]; then
    echo -e "  IPv6:      ${GREEN}Включён${NC}"
fi
if [[ "$ENABLE_WARP" == "y" ]]; then
    echo -e "  WARP:      ${GREEN}Подключён${NC}"
fi
echo -e "  UFW:       ${GREEN}Включён${NC}"
echo -e "  BBR:       ${GREEN}Включён${NC}"
if [[ "$DOCKER_OK" == "true" ]]; then
    echo -e "  Docker:    ${GREEN}Установлен${NC}"
fi

echo ""
echo -e "${CYAN}🔐 Доступ:${NC}"
echo -e "  URL:    ${GREEN}https://${DOMAIN}/${XUI_WEB_PATH}/${NC}"
echo -e "  (внутренний порт X-UI: ${RANDOM_PORT})"
echo -e "  Логин:  ${YELLOW}${XUI_USERNAME}${NC}"
echo -e "  Пароль: ${YELLOW}${XUI_PASSWORD}${NC}"
echo -e "  API:    ${YELLOW}${API_KEY}${NC}"

echo ""
echo -e "${CYAN}📁 Файлы:${NC}"
echo -e "  Credentials: /root/x-ui-credentials.txt"
echo -e "  Log:         ${LOG_FILE}"

echo ""
echo -e "${CYAN}⚙️ Команды:${NC}"
echo -e "  x-ui              - меню"
echo -e "  x-ui status       - статус"
if [[ "$ENABLE_WARP" == "y" ]]; then
    echo -e "  warp-cli status   - статус WARP"
    echo -e "  warp-cli connect  - подключить WARP"
    echo -e "  warp-cli disconnect - отключить WARP"
fi
if [[ "$CREATE_SUBSCRIPTION" == "y" ]]; then
    echo -e "  generate-subscription.sh - подписки"
    echo -e "  Подписка: https://${DOMAIN}${SUB_PATH}/"
fi
if [[ "$GENERATE_QR" == "y" ]]; then
    echo -e "  generate-qr.sh          - QR коды"
fi
if [[ "$CREATE_API" == "y" ]]; then
    echo -e "  API: http://localhost:8080/api/"
fi
if [[ "$SETUP_UPTIME_KUMA" == "y" && "$DOCKER_OK" == "true" ]]; then
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" == "y" && -n "$KUMA_HTTPS_HOST" ]]; then
        echo -e "  Uptime Kuma: ${GREEN}https://${KUMA_HTTPS_HOST}${NC}"
    else
        echo -e "  Uptime Kuma: http://${DOMAIN}:3001"
    fi
fi
if [[ "$INSTALL_PORTAINER" == "y" && "$DOCKER_OK" == "true" ]]; then
    if [[ "$USE_DOCKER_SUBDOMAIN_TLS" == "y" && -n "$PORTAINER_HTTPS_HOST" ]]; then
        echo -e "  Portainer:   ${GREEN}https://${PORTAINER_HTTPS_HOST}${NC}"
    else
        echo -e "  Portainer:   http://${DOMAIN}:9000"
    fi
fi

if [[ "$SETUP_SSH_HARDENING" == "y" && "$SSH_PORT" != "22" ]]; then
    echo -e ""
    echo -e "${RED}⚠️ SSH порт: ${SSH_PORT}${NC}"
    echo -e "${YELLOW}Не закрывайте сессию!${NC}"
fi

echo -e ""
echo -e "${GREEN}Готово!${NC}"
