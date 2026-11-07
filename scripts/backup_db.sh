#!/usr/bin/env bash
# GreenLink MySQL 백업 — 저장소 루트(docker-compose.prod.yml 위치)에서 실행한다.
#   ./scripts/backup_db.sh                 # backups/greenlink-YYYYmmdd-HHMMSS.sql.gz 생성, 14일 지난 백업 삭제
#   BACKUP_KEEP_DAYS=30 ./scripts/backup_db.sh
# 매일 자동 백업(WSL crontab -e):
#   30 3 * * * cd /home/geung/projects/greenlink && ./scripts/backup_db.sh >> backups/backup.log 2>&1
# 복원:
#   gunzip -c backups/<파일>.sql.gz | docker compose -f docker-compose.prod.yml exec -T db \
#     sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" greenlink'
set -euo pipefail

cd "$(dirname "$0")/.."

COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="backups"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$BACKUP_DIR/greenlink-$STAMP.sql.gz"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# 비밀번호는 db 컨테이너 안의 환경변수를 쓰므로 명령줄·로그에 남지 않는다.
docker compose -f "$COMPOSE_FILE" exec -T db \
  sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --no-tablespaces greenlink' \
  | gzip > "$TARGET.part"

mv "$TARGET.part" "$TARGET"
chmod 600 "$TARGET"
echo "[BACKUP] $TARGET ($(du -h "$TARGET" | cut -f1))"

find "$BACKUP_DIR" -name 'greenlink-*.sql.gz' -mtime +"$KEEP_DAYS" -print -delete
