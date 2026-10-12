

amsc() {
  local model="${1:-claude-sonnet}"
  local prompt="${2:-Hello}"

  if [ -z "$AMSC_I2_API_KEY" ]; then
    echo "Error: AMSC_I2_API_KEY is not set." >&2
    echo "To set up access and get a key, see https://amsc-docs-d762d2.gitlab.io/model-access-gateway/" >&2
    return 1
  fi

  curl -s --request POST \
    --url https://i2-api.staging.american-science-cloud.org/v1/chat/completions \
    --header "Authorization: Bearer $AMSC_I2_API_KEY" \
    --header "Content-Type: application/json" \
    --data "$(jq -n \
      --arg model "$model" \
      --arg prompt "$prompt" \
      '{model: $model, messages: [{role: "user", content: $prompt}]}'
    )" | jq
}