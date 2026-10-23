#!/usr/bin/env bash

endpoint="${1:-http://localhost:8000}"
endpoint="${endpoint%/}"

# Query vLLM OpenAI-compatible /v1/models endpoint with a short timeout
response=$(curl -s --connect-timeout 0.5 -m 1 "${endpoint}/v1/models" 2>/dev/null)

if [ -n "$response" ]; then
    echo "$response" | jq -c '[.data[].id] // []' 2>/dev/null || echo "[]"
else
    echo "[]"
fi
