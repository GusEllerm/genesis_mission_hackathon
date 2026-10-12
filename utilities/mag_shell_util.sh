# Send one prompt to a model through the AmSC Model Access Gateway (MAG).
#
# Usage:
#   export AMSC_TOKEN=<your key>
#   source utilities/mag_shell_util.sh
#   amsc <model> [prompt]          # prompt defaults to "Hello"
#   amsc --list                    # list available models (or -l)
#
# The provider header defaults to microsoft. To change it: AMSC_PROVIDER=openai amsc ...
#
# Example:
#   amsc openai/gpt-oss-120b "What is QED drug-likeness?"
#
# Requires curl and jq. Prints the JSON response.
amsc() {
  local model="${1}"
  local prompt="${2:-Hello}"
  local provider="${AMSC_PROVIDER:-microsoft}"

  if [ -z "$AMSC_TOKEN" ]; then
    echo "Error: AMSC_TOKEN is not set." >&2
    echo "To set up access and get a key, see https://amsc-docs-d762d2.gitlab.io/model-access-gateway/" >&2
    return 1
  fi

  if [ "$model" = "-l" ] || [ "$model" = "--list" ]; then
    curl -s --url https://mag.genesis.americansciencecloud.org/v1/models \
      --header "Authorization: Bearer $AMSC_TOKEN" \
      --header "X-AmSC-MAG-Provider: $provider" | jq -r '.data[].id'
    return
  fi

  curl -s --request POST \
    --url https://mag.genesis.americansciencecloud.org/v1/chat/completions \
    --header "Authorization: Bearer $AMSC_TOKEN" \
    --header "X-AmSC-MAG-Provider: $provider" \
    --header "Content-Type: application/json" \
    --data "$(jq -n \
      --arg model "$model" \
      --arg prompt "$prompt" \
      '{model: $model, messages: [{role: "user", content: $prompt}]}'
    )" | jq
}
