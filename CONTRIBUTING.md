# Contributing to X-UI Ultimate Installer

Спасибо за интерес к проекту!

## 🤝 Как внести вклад

### 1. Сообщить об ошибке

- Проверьте [Issues](https://github.com/sergej19882906/x-ui-ultimate/issues)
- Создайте новый Issue с описанием
- Приложите логи

### 2. Предложить улучшение

- Опишите предлагаемое улучшение
- Объясните почему это полезно

### 3. Pull Request

```bash
git clone https://github.com/sergej19882906/x-ui-ultimate.git
git checkout -b feature/your-feature
# Внесите изменения
git commit -m "Add: your feature"
git push origin feature/your-feature
```

## 📋 Требования к коду

### Стиль

```bash
# Функции логирования
log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error_log() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ОШИБКА:${NC} $1"; }

# Проверка ошибок
if [[ ! command ]]; then
    error_log "Описание"
    exit 1
fi
```

### Переменные

```bash
ENABLE_FEATURE=true
INSTALL_PACKAGE="name"
SETUP_OPTION="y"
```

### Комментарии

```bash
# =============================================================================
# Раздел скрипта
# =============================================================================
```

## 🧪 Тестирование

Перед PR:

1. **Проверьте синтаксис**
   ```bash
   bash -n install.sh
   ```

2. **Протестируйте на чистой Ubuntu/Debian**

3. **Обновите документацию**

## 📝 Чек-лист PR

- [ ] Код следует стилю
- [ ] Все функции работают
- [ ] Документация обновлена
- [ ] Нет ошибок синтаксиса

---

Спасибо за вклад! 🎉
