@echo off
chcp 65001 >nul
title NVIDIA 듀얼 모니터 다운 현상 자동 해결 스크립트

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 관리자 권한 승인이 필요합니다. 승인 창이 뜨면 '예'를 눌러주세요...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

echo ========================================================
echo  NVIDIA 듀얼 모니터 충돌 및 다운 현상 자동 해결 작업 시작
echo ========================================================
echo.

echo [1/3] HAGS (하드웨어 가속 GPU 일정 예약) 비활성화 적용 중...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 1 /f

echo [2/3] TDR GPU 타임아웃 대기 시간 연장 (2초 -^> 10초) 적용 중...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrDelay" /t REG_DWORD /d 10 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrDdiDelay" /t REG_DWORD /d 10 /f

echo [3/3] 충돌 원인 Mirage 가상 디스플레이 드라이버(dfmirage) 중지 및 비활성화 중...
net stop dfmirage >nul 2>&1
sc config dfmirage start= disabled >nul 2>&1
powershell -Command "Disable-PnpDevice -InstanceId 'ROOT\DISPLAY\0000' -Confirm:$false" >nul 2>&1

echo.
echo ========================================================
echo  설정이 모두 완료되었습니다!
echo  수정된 설정을 완벽하게 적용하기 위해 PC를 재부팅해 주세요.
echo ========================================================
echo.
pause
