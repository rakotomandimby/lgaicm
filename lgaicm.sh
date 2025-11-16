#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
lgaicm - Generate AI-powered conventional commit suggestions.

Usage:
  $SCRIPT_NAME [--type <commit-type>] [--help]

Options:
  -t, --type <commit-type>   Conventional commit type to enforce (default: ai-defined).
  -h, --help                 Show this help message.
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: Required command '$cmd' is not available in PATH." >&2
    exit 1
  fi
}

parse_positive_int() {
  local value="$1"
  local fallback="$2"
  if [[ "$value" =~ ^[0-9]+$ ]] && (( value > 0 )); then
    printf '%s' "$value"
  else
    printf '%s' "$fallback"
  fi
}

truncate_text() {
  local text="$1"
  local limit="$2"
  local length
  length=$(LC_ALL=C printf '%s' "$text" | wc -c | awk '{print $1}')
  if (( length <= limit )); then
    printf '%s' "$text"
  else
    head -c "$limit" <<<"$text"
    printf '\n[Diff truncated to %s bytes]\n' "$limit"
  fi
}

COMMIT_TYPE="ai-defined"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)
      if [[ -n "${2:-}" ]]; then
        COMMIT_TYPE="$2"
        shift 2
      else
        echo "Error: --type option requires a value." >&2
        usage
        exit 1
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'." >&2
      usage
      exit 1
      ;;
  esac
done

require_command git
require_command curl
require_command jq

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "Error: OPENAI_API_KEY environment variable is not set." >&2
  exit 1
fi

if git diff --cached --quiet; then
  echo "Error: No staged changes detected. Stage files before generating commit messages." >&2
  exit 1
fi

MODEL="${LGAICM_MODEL:-gpt-5.1-codex-mini}"
API_URL="${LGAICM_API_URL:-https://api.openai.com/v1/responses}"
CURL_TIMEOUT=$(parse_positive_int "${LGAICM_CURL_TIMEOUT:-0}" 45)
MAX_STAT_CHARS=$(parse_positive_int "${LGAICM_MAX_STAT_CHARS:-0}" 60000)
MAX_DIFF_CHARS=$(parse_positive_int "${LGAICM_MAX_DIFF_CHARS:-0}" 200000)
SUGGESTION_MIN=$(parse_positive_int "${LGAICM_MIN_SUGGESTIONS:-0}" 5)
SUGGESTION_MAX=$(parse_positive_int "${LGAICM_MAX_SUGGESTIONS:-0}" 7)

if (( SUGGESTION_MIN > SUGGESTION_MAX )); then
  SUGGESTION_MIN="$SUGGESTION_MAX"
fi

DIFF_STAT=$(git diff --cached --stat)
DIFF_PATCH=$(git diff --cached)

TRUNCATED_STAT=$(truncate_text "$DIFF_STAT" "$MAX_STAT_CHARS")
TRUNCATED_PATCH=$(truncate_text "$DIFF_PATCH" "$MAX_DIFF_CHARS")

if [[ "$COMMIT_TYPE" == "ai-defined" ]]; then
  TYPE_INSTRUCTION="Determine the most appropriate conventional commit type (such as feat, fix, chore, docs, style, refactor, perf, test, build, ci) for each suggestion based on the diff."
else
  TYPE_INSTRUCTION="Use the \"$COMMIT_TYPE\" conventional commit type for every suggestion."
fi

SYSTEM_INSTRUCTIONS=$(cat <<'EOF'
You are an expert release engineer helping craft precise conventional git commit messages.
Respond with plain text commit subject lines only.
Do not include numbering, explanations, or additional prose.
EOF
)

PROMPT=$(cat <<EOF
$TYPE_INSTRUCTION
Generate between $SUGGESTION_MIN and $SUGGESTION_MAX distinct conventional commit messages.
Each subject line must: stay under 120 characters, use the imperative mood, avoid trailing punctuation, and describe the staged changes accurately.
Return one commit message per line with no bullet markers or numbering.
Each suggestion must be formatted as: <type>(<scope>): <description>

Staged git diff summary (git diff --cached --stat):
$TRUNCATED_STAT

Full staged git diff (git diff --cached):
$TRUNCATED_PATCH
EOF
)

REQUEST_PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg instructions "$SYSTEM_INSTRUCTIONS" \
  --arg input "$PROMPT" \
  '{model: $model, instructions: $instructions, input: $input}')

if ! API_RESPONSE=$(
  curl -sS --fail-with-body \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    --max-time "$CURL_TIMEOUT" \
    "$API_URL" \
    -d "$REQUEST_PAYLOAD"
); then
  echo "Error: Failed to call OpenAI Responses API." >&2
  exit 1
fi

RAW_OUTPUT=$(echo "$API_RESPONSE" | jq -r '
  [ .output[]?.content[]? | select(.type == "output_text") | .text ] | join("\n")
')

if [[ -z "$(echo "$RAW_OUTPUT" | tr -d '[:space:]')" ]]; then
  echo "Error: OpenAI returned an empty response." >&2
  exit 1
fi

CLEAN_LINES=$(printf '%s\n' "$RAW_OUTPUT" | tr '\r' '\n' | \
  sed -e 's/^[[:space:]]*//' \
      -e 's/[[:space:]]*$//' \
      -e 's/^[0-9][0-9]*[.)-][[:space:]]*//' \
      -e 's/^[-*][[:space:]]*//' | \
  awk 'NF { if (!seen[$0]++) print }')

if [[ -z "$CLEAN_LINES" ]]; then
  echo "Error: Unable to extract commit suggestions from OpenAI response." >&2
  exit 1
fi

FINAL_LINES=$(printf '%s\n' "$CLEAN_LINES" | head -n "$SUGGESTION_MAX")

printf '%s\n' "$FINAL_LINES"

