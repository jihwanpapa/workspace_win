@echo off
echo 업무용 터널을 엽니다...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp01_connect_tunnel.ps1'"
pause
