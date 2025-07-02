#!/bin/bash
# ssh -4 -o "StrictHostKeyChecking no" -L $DB_PORT:127.0.0.1:$DB_PORT $SSH_DB_USER@$SSH_DB_HOST  -N -f
uvicorn app:app --host 0.0.0.0 --port 5002 --workers $WORKERS  --log-config=log_conf.yaml --log-level="debug"
