#!/usr/bin/env bash
# Run the verified Typeahead release with individual docker run commands.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
lab=assignment-s21-direct
label="devops.assignment=$lab"
release="${IMAGE_TAG:-0f8f27c95cae983b8274d649db2435200450c48a}"
registry=ghcr.io/vimalyad/typeahead-capstone

cleanup() {
  mapfile -t containers < <(docker ps -aq --filter "label=$label")
  if ((${#containers[@]})); then docker rm -f "${containers[@]}"; fi
  mapfile -t volumes < <(docker volume ls -q --filter "label=$label")
  if ((${#volumes[@]})); then docker volume rm "${volumes[@]}"; fi
  mapfile -t networks < <(docker network ls -q --filter "label=$label")
  if ((${#networks[@]})); then docker network rm "${networks[@]}"; fi
}
wait_http() {
  local url="$1"
  for ((attempt=0; attempt<90; attempt++)); do
    if curl -fsS "$url" >/dev/null; then return; fi
    sleep 2
  done
  return 1
}
status() {
  docker ps --filter "label=$label" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

case "${1:-help}" in
  up)
    if docker network inspect "$lab" >/dev/null 2>&1; then
      printf 'This lab already exists. Run bash run-containers.sh down before a fresh run.\n' >&2
      exit 1
    fi
    private_env="$(mktemp)"
    chmod 600 "$private_env"
    trap 'rm -f -- "$private_env"' EXIT
    trap 'cleanup' ERR
    # Passwords go through a private environment file, never command-line arguments or logs.
    python3 - "$private_env" "$release" <<'PY'
import pathlib,secrets,sys
password=secrets.token_urlsafe(32)
pathlib.Path(sys.argv[1]).write_text(
    'POSTGRES_PASSWORD='+password+'\nSPRING_DATASOURCE_PASSWORD='+password+'\n'
    'SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/typeahead\n'
    'SPRING_DATASOURCE_USERNAME=app\nAPP_VERSION='+sys.argv[2]+'\n')
PY
    docker network create --label "$label" "$lab"
    docker volume create --label "$label" "$lab-pgdata"
    docker volume create --label "$label" "$lab-kafkadata"
    docker run -d --name "$lab-postgres" --label "$label" --network "$lab" --network-alias postgres \
      --user 70:70 --memory 192m --env-file "$private_env" -e POSTGRES_DB=typeahead -e POSTGRES_USER=app \
      -v "$lab-pgdata:/var/lib/postgresql/data" \
      postgres:16-alpine@sha256:721873c34ceb9f8d8fc265984940dc982404c105f19ad51be9fdc5970a6080ea
    docker run -d --name "$lab-redis" --label "$label" --network "$lab" --network-alias redis \
      --user 999:999 --memory 64m --tmpfs /data:uid=999,gid=999 \
      redis:7-alpine@sha256:858f009f9709ce576febc734aa78b8f6d624b82571f9ddb6bda4377c833b3499 \
      redis-server --maxmemory 16mb --maxmemory-policy allkeys-lru --save '' --appendonly no
    docker run -d --name "$lab-kafka" --label "$label" --network "$lab" --network-alias kafka \
      --user 1000:1000 --memory 640m -v "$lab-kafkadata:/var/lib/kafka/data" \
      -e CLUSTER_ID=MkU3OEVBNTcwNTJENDM2Qk -e KAFKA_NODE_ID=1 -e KAFKA_PROCESS_ROLES=broker,controller \
      -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093 \
      -e KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
      -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 \
      -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT \
      -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER -e KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
      -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
      -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 -e KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 \
      -e KAFKA_LOG_DIRS=/var/lib/kafka/data -e KAFKA_LOG_RETENTION_HOURS=1 \
      -e KAFKA_LOG_SEGMENT_BYTES=16777216 -e 'KAFKA_HEAP_OPTS=-Xms128m -Xmx256m' \
      apache/kafka:4.1.0@sha256:bff074a5d0051dbc0bbbcd25b045bb1fe84833ec0d3c7c965d1797dd289ec88f
    db_ready=false
    for ((attempt=0; attempt<45; attempt++)); do
      if docker exec "$lab-postgres" pg_isready -U app -d typeahead; then db_ready=true; break; fi
      sleep 2
    done
    "$db_ready"
    docker run -d --name "$lab-ingestion" --label "$label" --network "$lab" --network-alias ingestion-service \
      --memory 512m --read-only --tmpfs /tmp:uid=65532,gid=65532,size=64m \
      --cap-drop ALL --security-opt no-new-privileges:true --env-file "$private_env" \
      -e SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092 -p 127.0.0.1:19882:8082 \
      "$registry-ingestion:$release"
    wait_http http://127.0.0.1:19882/health/readiness
    docker run -d --name "$lab-suggestion" --label "$label" --network "$lab" --network-alias suggestion-service \
      --memory 512m --read-only --tmpfs /tmp:uid=65532,gid=65532,size=64m \
      --cap-drop ALL --security-opt no-new-privileges:true --env-file "$private_env" \
      -e APP_REDIS_NODES=redis:6379 -p 127.0.0.1:19881:8081 "$registry-suggestion:$release"
    wait_http http://127.0.0.1:19881/health/readiness
    docker run -d --name "$lab-frontend" --label "$label" --network "$lab" \
      --memory 48m --read-only --tmpfs /tmp:uid=101,gid=101,size=16m \
      --cap-drop ALL --security-opt no-new-privileges:true \
      -p 127.0.0.1:13081:8080 "$registry-frontend:$release"
    wait_http http://127.0.0.1:13081/api/queries
    status
    ;;
  check)
    status
    curl -fsS -w '\n' http://127.0.0.1:19882/health
    curl -fsS -w '\n' http://127.0.0.1:19882/health/readiness
    curl -fsS -w '\n' http://127.0.0.1:19881/health
    curl -fsS -w '\n' http://127.0.0.1:19881/health/readiness
    python3 "$project_dir/scripts/smoke.py" --url http://127.0.0.1:13081
    ;;
  down) cleanup ;;
  *) printf 'Usage: bash run-containers.sh up|check|down\n' ;;
esac
