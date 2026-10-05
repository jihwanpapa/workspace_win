#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
chmod +x "$DIR"/*.command "$DIR"/*.py "$DIR"/*.exp
echo "실행 권한이 부여되었습니다."
