#!/bin/sh
# Local throwaway PostgreSQL cluster for development and tests.
# Uses an already-installed PostgreSQL (no Docker). Data lives in backend/.pgdata (gitignored).
# Usage: scripts/dev-db.sh start | stop | status | reset
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="$DIR/.pgdata"
PORT="${DEV_DB_PORT:-54329}"

# Find PostgreSQL binaries: PATH first, then common install locations.
if command -v pg_ctl >/dev/null 2>&1; then
  BIN="$(dirname "$(command -v pg_ctl)")"
else
  for d in /Library/PostgreSQL/*/bin /opt/homebrew/opt/postgresql*/bin /usr/lib/postgresql/*/bin; do
    if [ -x "$d/pg_ctl" ]; then BIN="$d"; fi
  done
fi
if [ -z "$BIN" ]; then
  echo "PostgreSQL binaries not found. Install PostgreSQL 15+ or set PATH." >&2
  exit 1
fi

case "${1:-start}" in
  start)
    if [ ! -d "$DATA" ]; then
      # Trust auth, bound to localhost only: this cluster holds fake data and is never exposed.
      "$BIN/initdb" -D "$DATA" -U app -A trust -E UTF8 >/dev/null
    fi
    if ! "$BIN/pg_isready" -h localhost -p "$PORT" >/dev/null 2>&1; then
      "$BIN/pg_ctl" -D "$DATA" -o "-p $PORT -c listen_addresses=localhost" -l "$DATA/server.log" -w start >/dev/null
    fi
    for db in dosebook_app dosebook_test; do
      "$BIN/psql" -h localhost -p "$PORT" -U app -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1 \
        || "$BIN/createdb" -h localhost -p "$PORT" -U app "$db"
    done
    echo "PostgreSQL ready on localhost:$PORT (databases: dosebook_app, dosebook_test)"
    ;;
  stop)
    "$BIN/pg_ctl" -D "$DATA" -m fast stop
    ;;
  status)
    "$BIN/pg_isready" -h localhost -p "$PORT"
    ;;
  reset)
    "$BIN/pg_ctl" -D "$DATA" -m fast stop >/dev/null 2>&1 || true
    rm -rf "$DATA"
    echo "Removed $DATA"
    ;;
  *)
    echo "Usage: $0 start|stop|status|reset" >&2
    exit 1
    ;;
esac
