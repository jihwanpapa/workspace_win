@echo off
set /p SERVER="접속할 서버를 입력하세요 (stg-kr, stg-us, prd-kr, prd-us, prd-cn, dev): "
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp02_sshw.ps1' -Server '%SERVER%'"
