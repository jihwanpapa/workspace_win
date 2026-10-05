#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$DIR/../config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.txt not found!"
    exit 1
fi

# Load config
while IFS='=' read -r key value; do
    if [[ $key != \#* ]] && [[ -n $key ]]; then
        declare "$key"="$(echo -e "${value}" | tr -d '[:space:]')"
    fi
done < "$CONFIG_FILE"

if [ -z "$SSH_USER" ]; then
    echo "Error: SSH_USER not set in config.txt"
    exit 1
fi

# Tunnel settings
WORK_PC="10.110.1.182"
WORK_PC_PORT="40022"

echo ">>> 업무 터널링을 시작합니다..."
echo ">>> Mac 버전은 터미널 창을 열어둔 상태로 유지하세요."

# Open SSH Tunnel
ssh -N -p $WORK_PC_PORT -D 1080 \
-L 0.0.0.0:50022:52.78.116.245:40022 \
-L 0.0.0.0:50023:34.215.245.92:40022 \
-L 0.0.0.0:60022:13.209.114.38:40022 \
-L 0.0.0.0:60023:52.206.216.205:40022 \
-L 0.0.0.0:60024:54.223.227.233:40022 \
-L 0.0.0.0:30022:3.35.117.172:40022 \
-o ServerAliveInterval=30 \
-o ServerAliveCountMax=3 \
-o StrictHostKeyChecking=accept-new \
bizjyheo@$WORK_PC
