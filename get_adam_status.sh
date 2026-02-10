#!/bin/bash
# get_adam_status.sh
# Performs a self-diagnosis of Adam's core functions.

echo "🤖 Adam Status Self-Diagnosis 🤖"
echo "---------------------------------"

# --- Check 1: Gemini Quota ---
echo "1. Checking Gemini API Quotas..."
QUOTA_SCRIPT="/Users/eva/.openclaw/workspace/adam-workshop/get-quota.sh"

if [ -f "$QUOTA_SCRIPT" ]; then
    QUOTA_OUTPUT=$($QUOTA_SCRIPT)
    # Corrected grep to look for 'Flash'
    QUOTA_STATUS=$(echo "$QUOTA_OUTPUT" | grep 'Flash')
    # Trim whitespace for cleaner output
    CLEAN_QUOTA_STATUS=$(echo "$QUOTA_STATUS" | awk '{$1=$1};1')
    echo "   - Quota Status: $CLEAN_QUOTA_STATUS"
else
    echo "   - ERROR: get-quota.sh script not found at $QUOTA_SCRIPT"
fi

# --- Check 2: Model API Availability ---
echo "2. Checking Model API Availability (gemini-2.5-flash)..."
export GOOGLE_CLOUD_PROJECT_ID="adam-agent-project-486300"
TEST_PROMPT="Tell me the word 'test' in Russian."

# Using perl for a 15-second timeout, as the 'timeout' command is not available.
API_RESPONSE=$(perl -e 'alarm 15; exec @ARGV' /opt/homebrew/bin/gemini -m gemini-2.5-flash "$TEST_PROMPT")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    CLEAN_RESPONSE=$(echo "$API_RESPONSE" | tr -d '\n')
    echo "   - SUCCESS: Model responded."
    echo "   - Response: '$CLEAN_RESPONSE'"
elif [ $EXIT_CODE -eq 142 ] || [ $EXIT_CODE -eq 15 ]; then # alarm signal
    echo "   - ERROR: Model API call timed out after 15 seconds."
else
    echo "   - ERROR: Model API call failed with exit code $EXIT_CODE."
fi

echo "---------------------------------"
echo "Diagnosis complete."
