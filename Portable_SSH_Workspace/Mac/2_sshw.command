#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$DIR/../config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.txt not found!"
    exit 1
fi

while IFS='=' read -r key value; do
    if [[ $key != \#* ]] && [[ -n $key ]]; then
        declare "$key"="$(echo -e "${value}" | tr -d '[:space:]')"
    fi
done < "$CONFIG_FILE"

if [ -z "$SSH_USER" ] || [ -z "$SSH_PASS" ] || [ -z "$OTP_SECRET" ]; then
    echo "Error: Missing configuration in config.txt"
    exit 1
fi

echo "접속할 서버를 입력하세요 (stg-kr, stg-us, prd-kr, prd-us, prd-cn, dev): "
read SERVER

declare -A PORTS
PORTS=( ["stg-kr"]="50022" ["stg-us"]="50023" ["prd-kr"]="60022" ["prd-us"]="60023" ["prd-cn"]="60024" ["dev"]="30022" )

PORT=${PORTS[$SERVER]}
if [ -z "$PORT" ]; then
    echo "Invalid server!"
    exit 1
fi

OTP=$(python3 "$DIR/totp.py" "$OTP_SECRET")

export SSH_USER SSH_PASS PORT OTP
expect "$DIR/sshw.exp"
