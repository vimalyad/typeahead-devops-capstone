#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
kubectl apply -f kubernetes/namespace.yaml
if ! kubectl -n assignment-s21 get secret typeahead-database >/dev/null 2>&1; then
  python3 - <<'PY'
import json, os, secrets, subprocess
document = {
    'apiVersion': 'v1', 'kind': 'Secret',
    'metadata': {'name': 'typeahead-database', 'namespace': 'assignment-s21'},
    'type': 'Opaque',
    'stringData': {'password': os.environ.get('DATABASE_PASSWORD') or secrets.token_urlsafe(32)},
}
subprocess.run(['kubectl', 'apply', '-f', '-'], input=json.dumps(document), text=True, check=True)
PY
fi
