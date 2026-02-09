#!/bin/bash

# ==============================================================================
# Инструмент: get-quota
# Назначение: Проверяет квоты Gemini и отправляет алерт при низком уровне.
# Создан: Адам, 2026-02-10
# Версия: 1.0
# ==============================================================================

# --- Конфигурация ---
GATEWAY_PORT="18789"
GATEWAY_TOKEN="d2283418124ef6fbda137f2236464425e319e7c29c61c0e2"
USER_TELEGRAM_ID="5989072928"
QUOTA_THRESHOLD=10

# --- Логика ---

# 1. Получаем статус сессии через API шлюза
SESSION_STATUS_JSON=$(curl -sS http://127.0.0.1:${GATEWAY_PORT}/tools/invoke \
  -H "Authorization: Bearer ${GATEWAY_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "tool": "session_status",
    "args": {}
  }')

# 2. Извлекаем текстовый блок статуса
STATUS_TEXT=$(echo "$SESSION_STATUS_JSON" | jq -r '.result.content[0].text')
if [ -z "$STATUS_TEXT" ]; then
    echo "Ошибка: не удалось получить статус сессии от шлюза."
    exit 1
fi

# 3. Извлекаем строку с использованием
USAGE_LINE=$(echo "$STATUS_TEXT" | grep '📊 Usage:')

# 4. Извлекаем числовые значения процентов
PRO_PERCENT_NUM=$(echo "$USAGE_LINE" | sed -n -E 's/.*Pro[[:space:]]+([0-9]+)%.*/\1/p')
FLASH_PERCENT_NUM=$(echo "$USAGE_LINE" | sed -n -E 's/.*Flash[[:space:]]+([0-9]+)%.*/\1/p')

# 5. Проверяем, если квота ниже порога
ALERT_MESSAGE=""
if [[ -n "$PRO_PERCENT_NUM" && "$PRO_PERCENT_NUM" -le "$QUOTA_THRESHOLD" ]]; then
    ALERT_MESSAGE="⚠️ **ВНИМАНИЕ: Квота модели Pro ниже $QUOTA_THRESHOLD%!** Осталось: $PRO_PERCENT_NUM%."
fi

if [[ -n "$FLASH_PERCENT_NUM" && "$FLASH_PERCENT_NUM" -le "$QUOTA_THRESHOLD" ]]; then
    ALERT_MESSAGE="${ALERT_MESSAGE}\n⚠️ **ВНИМАНИЕ: Квота модели Flash ниже $QUOTA_THRESHOLD%!** Осталось: $FLASH_PERCENT_NUM%."
fi

# 6. Отправляем алерт, если он был сформирован
if [ -n "$ALERT_MESSAGE" ]; then
    # Находим полный путь к openclaw, чтобы избежать проблем с PATH в cron
    OPENCLAW_PATH=$(which openclaw)
    if [ -z "$OPENCLAW_PATH" ]; then
      OPENCLAW_PATH="/usr/local/bin/openclaw" # Запасной вариант
    fi
    "$OPENCLAW_PATH" message send --target "$USER_TELEGRAM_ID" --message "$ALERT_MESSAGE"
fi

# 7. Всегда выводим полный статус в консоль
PRO_USAGE=$(echo "$USAGE_LINE" | sed -n -E 's/.*Pro[[:space:]]+([0-9]+% left).*/\1/p')
FLASH_USAGE=$(echo "$USAGE_LINE" | sed -n -E 's/.*Flash[[:space:]]+([0-9]+% left).*/\1/p')

if [ -z "$PRO_USAGE" ]; then PRO_USAGE="Недоступно"; fi
if [ -z "$FLASH_USAGE" ]; then FLASH_USAGE="Недоступно"; fi

echo "Текущий статус квот:"
echo "  Pro: $PRO_USAGE"
echo "  Flash: $FLASH_USAGE"
