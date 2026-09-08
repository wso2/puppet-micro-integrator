#!/usr/bin/env bash
#----------------------------------------------------------------------------
# Provisions an ICP org secret for connecting a runtime (e.g. Micro
# Integrator) via the [icp_config] block in its deployment.toml.
#
# IMPORTANT: the underlying GraphQL mutation (createOrgSecret) is NOT
# idempotent - every invocation mints a brand new secret, and the value is
# shown exactly once (ICP only stores a hash of it server-side, never the
# plaintext). Run this once per environment/integration you want to connect,
# then store the printed value out of band (e.g. Hiera/eyaml, a vault) as
# micro_integrator::params::icp_secret. Do NOT wire this script into a Puppet
# run that fires on every agent apply - that would silently rotate the
# secret and break the existing connection each time.
#
# Requires: curl, jq
#
# Usage:
#   ICP_PASSWORD=<icp-admin-password> ./create-icp-org-secret.sh \
#     --icp-url https://icp.example.com:9446 \
#     --username admin \
#     --environment-id <environment-id> \
#     [--component-id <component-id>] \
#     [--insecure]
#
# On success, prints only the secret string to stdout (format
# "<keyId>.<keyMaterial>") so it can be captured directly:
#   SECRET=$(ICP_PASSWORD=... ./create-icp-org-secret.sh ...)
#----------------------------------------------------------------------------
set -euo pipefail

ICP_URL=""
USERNAME=""
ENVIRONMENT_ID=""
COMPONENT_ID=""
INSECURE=()

while [ $# -gt 0 ]; do
  case "$1" in
    --icp-url) ICP_URL="$2"; shift 2 ;;
    --username) USERNAME="$2"; shift 2 ;;
    --environment-id) ENVIRONMENT_ID="$2"; shift 2 ;;
    --component-id) COMPONENT_ID="$2"; shift 2 ;;
    --insecure) INSECURE=(-k); shift ;;
    -h|--help)
      sed -n '2,29p' "$0"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$ICP_URL" ] || [ -z "$USERNAME" ] || [ -z "$ENVIRONMENT_ID" ]; then
  echo "Usage: $0 --icp-url <url> --username <user> --environment-id <id> [--component-id <id>] [--insecure]" >&2
  exit 1
fi

if [ -z "${ICP_PASSWORD:-}" ]; then
  echo "Set ICP_PASSWORD in the environment before running this script." >&2
  exit 1
fi

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "Missing required tool: $bin" >&2; exit 1; }
done

# 1. Log in and obtain a bearer token.
login_response=$(curl -sS "${INSECURE[@]}" -X POST "${ICP_URL%/}/auth/login" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg u "$USERNAME" --arg p "$ICP_PASSWORD" '{username:$u, password:$p}')")

token=$(printf '%s' "$login_response" | jq -r '.token // empty')
if [ -z "$token" ]; then
  echo "Login failed: $login_response" >&2
  exit 1
fi

# 2. Call the createOrgSecret mutation with that token.
if [ -n "$COMPONENT_ID" ]; then
  query='mutation($environmentId: String!, $componentId: String) { createOrgSecret(environmentId: $environmentId, componentId: $componentId) }'
  variables=$(jq -nc --arg env "$ENVIRONMENT_ID" --arg comp "$COMPONENT_ID" '{environmentId:$env, componentId:$comp}')
else
  query='mutation($environmentId: String!) { createOrgSecret(environmentId: $environmentId) }'
  variables=$(jq -nc --arg env "$ENVIRONMENT_ID" '{environmentId:$env}')
fi

gql_response=$(curl -sS "${INSECURE[@]}" -X POST "${ICP_URL%/}/graphql" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer ${token}" \
  -d "$(jq -nc --arg q "$query" --argjson v "$variables" '{query:$q, variables:$v}')")

secret=$(printf '%s' "$gql_response" | jq -r '.data.createOrgSecret // empty')
if [ -z "$secret" ]; then
  echo "createOrgSecret failed: $gql_response" >&2
  exit 1
fi

printf '%s\n' "$secret"
