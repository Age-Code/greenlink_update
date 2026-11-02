#!/bin/bash

cd /home/greenlink/greenlink || exit 1

set -a
. /home/greenlink/greenlink/greenlink.env || exit 1
set +a

echo "===== SENSOR CRON START $(date) =====" >> /home/greenlink/greenlink/sensor.log

/home/greenlink/greenlink/.venv/bin/python3 /home/greenlink/greenlink/sensor_main.py >> /home/greenlink/greenlink/sensor.log 2>&1

echo "===== SENSOR CRON END $(date) =====" >> /home/greenlink/greenlink/sensor.log
