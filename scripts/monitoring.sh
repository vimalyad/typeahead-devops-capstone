#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, secrets, subprocess
found = subprocess.check_output(['kubectl', '-n', 'assignment-s21', 'get', 'secret',
    'grafana-admin', '--ignore-not-found', '-o', 'name'], text=True)
if not found.strip():
    secret = {'apiVersion':'v1', 'kind':'Secret', 'metadata':{'name':'grafana-admin',
        'namespace':'assignment-s21'}, 'stringData':{'password':secrets.token_urlsafe(32)}}
    subprocess.run(['kubectl','create','-f','-'], input=json.dumps(secret), text=True, check=True)
PY
helm upgrade --install monitoring monitoring -n assignment-s21 --wait --timeout 5m
