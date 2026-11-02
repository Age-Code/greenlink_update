#!/bin/bash

cd /home/greenlink/greenlink
source /home/greenlink/greenlink/.venv/bin/activate

set -a
. /home/greenlink/greenlink/greenlink.env || exit 1
set +a

python3 command_worker.py >> /home/greenlink/greenlink/command.log 2>&1
