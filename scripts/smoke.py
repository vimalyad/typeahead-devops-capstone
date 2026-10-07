#!/usr/bin/env python3
"""Verify the real HTTP/SQL/Kafka/search path. Exit nonzero on any failed assertion."""
import argparse
import json
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

parser = argparse.ArgumentParser()
parser.add_argument('--url', default='http://127.0.0.1:3000')
parser.add_argument('--host', help='Ingress Host header when using a port-forward')
args = parser.parse_args()
base = args.url.rstrip('/')

def request(path, method='GET', body=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if args.host:
        headers['Host'] = args.host
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(base + path, data=data, method=method, headers=headers)
    try:
        response = urllib.request.urlopen(req, timeout=15)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        payload = response.read().decode()
        assert response.status == expected, (path, response.status, payload[:300])
        return json.loads(payload) if payload and payload[0] in '[{' else payload

deadline = time.monotonic() + 300
while True:
    try:
        request('/api/queries')
        break
    except (OSError, AssertionError):
        if time.monotonic() > deadline:
            raise
        time.sleep(3)

key = 'capstone smoke ' + uuid.uuid4().hex[:10]
created = request('/api/queries', 'POST', {'query': key, 'allTimeCount': 3}, 201)
identifier = created['id']
try:
    assert request(f'/api/queries/{identifier}')['query'] == key
    request('/api/queries', 'POST', {'query': key, 'allTimeCount': 3}, 409)
    request('/api/queries', 'POST', {'query': ' ', 'allTimeCount': 0}, 400)
    updated = request(f'/api/queries/{identifier}', 'PUT', {'query': key, 'allTimeCount': 4})
    assert updated['allTimeCount'] == 4
    request('/api/search', 'POST', {'query': key})
    deadline = time.monotonic() + 90
    while request(f'/api/queries/{identifier}')['allTimeCount'] < 5:
        if time.monotonic() > deadline:
            raise AssertionError('Kafka event was not persisted to PostgreSQL')
        time.sleep(2)
    deadline = time.monotonic() + 60
    while not any(item['query'] == key for item in request('/api/suggest?q=' + urllib.parse.quote(key))):
        if time.monotonic() > deadline:
            raise AssertionError('Committed query did not become searchable')
        time.sleep(2)
    assert 'root' in request('/')
    request(f'/api/queries/{identifier}', 'DELETE', expected=204)
    request(f'/api/queries/{identifier}', expected=404)
    print(json.dumps({'result': 'PASS', 'checks': [
        'create/read/update/delete query', 'duplicate and validation errors',
        'Kafka event persisted to PostgreSQL', 'trie suggestion refreshed', 'frontend served',
    ]}, indent=2))
finally:
    # A failed run should not leave its generated test query in the catalog.
    try:
        request(f'/api/queries/{identifier}', 'DELETE', expected=204)
    except (OSError, AssertionError):
        pass
