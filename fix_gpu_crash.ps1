# NVIDIA Dual Monitor Crash Fix Script
[CmdletBinding()]
param()

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " NVIDIA 듀얼 모니터 충돌 및 다운 현상 자동 해결 시작" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. HAGS (하드웨어 가속 GPU 일정 예약) 비활성화
Write-Host "[1/3] HAGS (하드웨어 가속 GPU 일정 예약) 비활성화 설정 중..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

# 2. TDR Delay 10초 설정 (GPU 순간 재설정 튕김 방지)
Write-Host "[2/3] TDR 타임아웃 연장 (10초) 설정 중..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -Value 10 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDdiDelay" -Value 10 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

# 3. dfmirage 서비스 및 PnP 장치 비활성화
Write-Host "[3/3] dfmirage 가상 드라이버 서비스 중지 및 비활성화 중..." -ForegroundColor Yellow
Stop-Service -Name "dfmirage" -Force -ErrorAction SilentlyContinue
Set-Service -Name "dfmirage" -StartupType Disabled -ErrorAction SilentlyContinue
Get-PnpDevice -InstanceId "ROOT\DISPLAY\0000" -ErrorAction SilentlyContinue | Disable-PnpDevice -Confirm:$false -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host " 모든 최적화 설정이 작업 파일로 준비되었습니다!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
