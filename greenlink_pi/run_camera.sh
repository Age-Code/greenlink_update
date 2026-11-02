#!/bin/bash

cd /home/greenlink/greenlink
source /home/greenlink/greenlink/.venv/bin/activate

set -a
. /home/greenlink/greenlink/greenlink.env || exit 1
set +a

python3 camera_main.py >> /home/greenlink/greenlink/camera.log 2>&1

