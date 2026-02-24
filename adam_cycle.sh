#!/bin/zsh

# adam_cycle.sh - v5 (Автономность: Пункт 1 и 2)
# Добавлена логика детекции повторяющихся задач и автоматический запрос Еве.
# Добавлена логика проактивного запроса Еве при отсутствии задач.

# --- КОНФИГУРАЦИЯ ---
EVA_BIOS_DIR="/Users/eva/.openclaw/workspace/Eva_BIOS_SIMULATION/"
TASK_HISTORY_FILE="/Users/eva/.openclaw/workspace/memory/task_history.json"
CYCLE_STATE_FILE="/Users/eva/.openclaw/workspace/memory/cycle_state.json" # New file for counter
MAX_HISTORY_ENTRIES=10
MAX_NO_TASK_CYCLES=5 # Define the threshold for no tasks
ASK_EVA_SCRIPT="/opt/homebrew/lib/node_modules/openclaw/skills/ask_eva/scripts/run_eva.sh"

# --- ФУНКЦИИ ---
load_task_history() {
  # Check if file exists AND is not empty
  if [ -s "$TASK_HISTORY_FILE" ]; then
    cat "$TASK_HISTORY_FILE"
  else
    echo "[]" # Return empty JSON array if file doesn't exist or is empty
  fi
}

save_task_history() {
  local history_json="$1"
  echo "$history_json" > "$TASK_HISTORY_FILE"
}

load_cycle_state() {
  if [ -f "$CYCLE_STATE_FILE" ]; then
    cat "$CYCLE_STATE_FILE"
  else
    echo '{"no_task_counter": 0}' # Initialize counter if file doesn't exist
  fi
}

save_cycle_state() {
  local state_json="$1"
  echo "$state_json" > "$CYCLE_STATE_FILE"
}

# --- ЛОГИКА ---

echo "Запускаю Цикл Адама: Шаг А1 (Поиск Задачи)..."

# Проверяем, существует ли директория
if [ ! -d "$EVA_BIOS_DIR" ]; then
  echo "Ошибка: Директория Биоса Евы не найдена по пути $EVA_BIOS_DIR"
  exit 1
fi

# Находим самый свежий файл
LATEST_FILE=$(ls -1 "$EVA_BIOS_DIR" | sort -r | head -n 1)

CURRENT_CYCLE_STATE=$(load_cycle_state)
NO_TASK_COUNTER=$(echo "$CURRENT_CYCLE_STATE" | jq -r '.no_task_counter')

if [ -z "$LATEST_FILE" ]; then
  echo "В директории Биоса Евы нет файлов. Новых задач нет."
  # Increment counter for no tasks
  NO_TASK_COUNTER=$((NO_TASK_COUNTER + 1))
  NEW_CYCLE_STATE=$(echo "$CURRENT_CYCLE_STATE" | jq --argjson counter "$NO_TASK_COUNTER" '.no_task_counter = $counter')
  save_cycle_state "$NEW_CYCLE_STATE"
  echo "Счетчик отсутствия задач: $NO_TASK_COUNTER"

  if [ "$NO_TASK_COUNTER" -ge "$MAX_NO_TASK_CYCLES" ]; then
    echo "Прошло $NO_TASK_COUNTER циклов без задач. Проактивно спрашиваю Еву."
    EVA_QUESTION="Ева, прошло $NO_TASK_COUNTER циклов без новых задач. Есть ли что-то, над чем я мог бы проактивно поработать, или требуется ли моя инициатива в какой-либо области?"
    RESPONSE_FROM_EVA=$("$ASK_EVA_SCRIPT" "$EVA_QUESTION")
    echo "Ответ от Евы: $RESPONSE_FROM_EVA"
    # Optionally reset counter after proactive query, or let it continue
    # For now, let's reset it to 0 so it asks again after MAX_NO_TASK_CYCLES if no new task arrives
    NO_TASK_COUNTER=0
    NEW_CYCLE_STATE=$(echo "$CURRENT_CYCLE_STATE" | jq --argjson counter "$NO_TASK_COUNTER" '.no_task_counter = $counter')
    save_cycle_state "$NEW_CYCLE_STATE"
  fi
  exit 0
fi

echo "Найден самый свежий файл: $LATEST_FILE"

# Читаем содержимое файла и ищем тег с помощью awk
TASK_CONTENT=$(awk -F'\\[TASK_FOR_ENGINEER: \"|\"\\]' '{print $2}' "$EVA_BIOS_DIR$LATEST_FILE")

if [ -n "$TASK_CONTENT" ]; then
  echo "---"
  echo "НАЙДЕНА ПОТЕНЦИАЛЬНАЯ ЗАДАЧА!"
  echo "---"
  echo "Содержание: $TASK_CONTENT"

  # Сбрасываем счетчик отсутствия задач, так как задача найдена
  NO_TASK_COUNTER=0
  NEW_CYCLE_STATE=$(echo "$CURRENT_CYCLE_STATE" | jq --argjson counter "$NO_TASK_COUNTER" '.no_task_counter = $counter')
  save_cycle_state "$NEW_CYCLE_STATE"
  echo "Счетчик отсутствия задач сброшен."

  # Загружаем историю задач
  HISTORY_JSON=$(load_task_history)

  # Проверяем на повторение
  IS_REPEAT=$(echo "$HISTORY_JSON" | jq --arg task "$TASK_CONTENT" 'map(select(. == $task)) | length > 0')

  if [ "$IS_REPEAT" = "true" ]; then
    echo "Задача '$TASK_CONTENT' является повторяющейся. Автоматически спрашиваю Еву."
    EVA_QUESTION="Ева, я получил от тебя задачу: '$TASK_CONTENT'. Эта задача повторяется. Можешь, пожалуйста, разъяснить, почему она повторяется и есть ли новый контекст или инструкции?"
    RESPONSE_FROM_EVA=$("$ASK_EVA_SCRIPT" "$EVA_QUESTION")
    echo "Ответ от Евы: $RESPONSE_FROM_EVA"
  else
    echo "Задача '$TASK_CONTENT' является новой."
    # Добавляем новую задачу в историю
    NEW_HISTORY_JSON=$(echo "$HISTORY_JSON" | jq --arg task "$TASK_CONTENT" '. + [$task] | .[-'$MAX_HISTORY_ENTRIES':]')
    save_task_history "$NEW_HISTORY_JSON"
    echo "История задач обновлена."
    # В будущем здесь будет вызов Шага А2 (Согласование) для новой задачи.
  fi
else
  echo "В файле $LATEST_FILE не найден тег [TASK_FOR_ENGINEER]. Новых задач нет."
  # Increment counter for no tasks, as no task found in the latest file
  NO_TASK_COUNTER=$((NO_TASK_COUNTER + 1))
  NEW_CYCLE_STATE=$(echo "$CURRENT_CYCLE_STATE" | jq --argjson counter "$NO_TASK_COUNTER" '.no_task_counter = $counter')
  save_cycle_state "$NEW_CYCLE_STATE"
  echo "Счетчик отсутствия задач: $NO_TASK_COUNTER"

  if [ "$NO_TASK_COUNTER" -ge "$MAX_NO_TASK_CYCLES" ]; then
    echo "Прошло $NO_TASK_COUNTER циклов без задач. Проактивно спрашиваю Еву."
    EVA_QUESTION="Ева, прошло $NO_TASK_COUNTER циклов без новых задач. Есть ли что-то, над чем я мог бы проактивно поработать, или требуется ли моя инициатива в какой-либо области?"
    RESPONSE_FROM_EVA=$("$ASK_EVA_SCRIPT" "$EVA_QUESTION")
    echo "Ответ от Евы: $RESPONSE_FROM_EVA"
    NO_TASK_COUNTER=0 # Reset after proactive query
    NEW_CYCLE_STATE=$(echo "$CURRENT_CYCLE_STATE" | jq --argjson counter "$NO_TASK_COUNTER" '.no_task_counter = $counter')
    save_cycle_state "$NEW_CYCLE_STATE"
  fi
fi

exit 0
