# 한글 깨짐 방지를 위한 인코딩 설정 (UTF-8 with BOM으로 저장 권장)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

<#
.SYNOPSIS
    업무용 PC(10.110.1.182)를 경유하여 내부 자원에 접속하기 위한 SSH 터널링 스크립트입니다.

.DESCRIPTION
    1. 로컬 1080 포트에 SOCKS5 프록시를 생성하여 업무 사이트(*.mcsvc.samsung.com) 접속을 가능하게 합니다.
    2. 로컬 40022 포트를 원격 보안 서버(52.78.116.245:40022)로 포워딩합니다.

.PARAMETER WorkPCUser
    업무용 PC의 SSH 접속 계정명 (기본값: 현재 사용자명)
#>

$WorkPC = "10.110.1.182"
$WorkPCPort = 40022
$WorkPCUser = "bizjyheo"       # 업무용 PC(182) 접속 계정
$WorkPCPassword = ""           # (선택) 업무용 PC 암호 (Pageant 미사용 시 입력)
$RemoteUser = "jinyoung.hur"   # 최종 목적지(245) 접속 계정

$SocksPort = 1080

# 원격 서버 1 (stg-kr)
$RemoteSshHost1 = "52.78.116.245"
$RemoteSshPort1 = 40022
$LocalSshPort1 = 50022

# 원격 서버 2 (stg-us)
$RemoteSshHost2 = "34.215.245.92"
$RemoteSshPort2 = 40022
$LocalSshPort2 = 50023

# 원격 서버 3 (prd-kr)
$RemoteSshHost3 = "13.209.114.38"
$RemoteSshPort3 = 40022
$LocalSshPort3 = 60022

# 원격 서버 4 (prd-us)
$RemoteSshHost4 = "52.206.216.205"
$RemoteSshPort4 = 40022
$LocalSshPort4 = 60023

# 원격 서버 5 (prd-cn)
$RemoteSshHost5 = "54.223.227.233"
$RemoteSshPort5 = 40022
$LocalSshPort5 = 60024

# 원격 서버 6 (dev)
$RemoteSshHost6 = "3.35.117.172"
$RemoteSshPort6 = 40022
$LocalSshPort6 = 30022


Write-Host ">>> 업무 터널링을 시작합니다..." -ForegroundColor Cyan
Write-Host ">>> [Step 1] 업무용 PC 접속: ${WorkPC}:${WorkPCPort} ($WorkPCUser)"
Write-Host ">>> [Step 2] 터널 구성:"
Write-Host "    - 서버 1 (stg-kr): localhost:$LocalSshPort1 -> ${RemoteSshHost1}:${RemoteSshPort1}"
Write-Host "    - 서버 2 (stg-us): localhost:$LocalSshPort2 -> ${RemoteSshHost2}:${RemoteSshPort2}"
Write-Host "    - 서버 3 (prd-kr): localhost:$LocalSshPort3 -> ${RemoteSshHost3}:${RemoteSshPort3}"
Write-Host "    - 서버 4 (prd-us): localhost:$LocalSshPort4 -> ${RemoteSshHost4}:${RemoteSshPort4}"
Write-Host "    - 서버 5 (prd-cn): localhost:$LocalSshPort5 -> ${RemoteSshHost5}:${RemoteSshPort5}"
Write-Host "    - 서버 6 (dev): localhost:$LocalSshPort6 -> ${RemoteSshHost6}:${RemoteSshPort6}"
Write-Host ">>> [Step 3] SOCKS5 프록시: localhost:$SocksPort"
Write-Host ""
Write-Host "연결을 유지하려면 이 창을 닫지 마세요. (종료: Ctrl+C)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
Write-Host "터널이 열린 후, 서버 접속 명령어 예시 (새 터미널 권장):" -ForegroundColor Green
Write-Host "서버 1 (stg-kr): ssh -p $LocalSshPort1 ${RemoteUser}@localhost" -ForegroundColor White
Write-Host "서버 6 (dev): ssh -p $LocalSshPort6 ${RemoteUser}@localhost" -ForegroundColor White
Write-Host "------------------------------------------------------------"

# SSH 터널 실행 명령
# choco install putty -y 로 설치가 필요합니다.

function Test-Port {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# 1. 기존 터널 확인 및 포트 정리
$AllPorts = @($SocksPort, $LocalSshPort1, $LocalSshPort2, $LocalSshPort3, $LocalSshPort4, $LocalSshPort5, $LocalSshPort6)
$UsedPorts = $AllPorts | Where-Object { Test-Port $_ }

if ($UsedPorts) {
    Write-Host "![주의] 이미 일부 포트($($UsedPorts -join ', '))가 사용 중입니다. 관련 프로세스를 종료합니다..." -ForegroundColor Yellow
    foreach ($port in $UsedPorts) {
        $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connections) {
            $pids = $connections.OwningProcess | Select-Object -Unique
            foreach ($pidNum in $pids) {
                if ($pidNum -ne 0 -and $pidNum -ne $PID) {
                    Write-Host "    - 포트 ${port}를 사용 중인 프로세스(PID: $pidNum) 종료 중..."
                    Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    # 프로세스 종료 대기
    Start-Sleep -Seconds 2
    
    # 다시 확인
    $UsedPorts = $AllPorts | Where-Object { Test-Port $_ }
    if ($UsedPorts) {
        Write-Host "![오류] 포트를 닫지 못했습니다. 시스템을 재부팅하거나 수동으로 프로세스를 종료해 주세요." -ForegroundColor Red
        exit
    } else {
        Write-Host ">>> 포트 정리가 완료되었습니다. 연결을 계속 진행합니다." -ForegroundColor Green
    }
}

$UsePlink = $false
if (Get-Command plink -ErrorAction SilentlyContinue) {
    $UsePlink = $true
}

if ($UsePlink) {
    Write-Host ">>> plink를 사용하여 백그라운드 연결을 시작합니다..." -ForegroundColor Green
    
    # plink 플래그 구성
    $plinkArgs = @("-P", "$WorkPCPort", "-N", "-D", "$SocksPort")

    $plinkArgs += @(
        "-L", "${LocalSshPort1}:${RemoteSshHost1}:${RemoteSshPort1}",
        "-L", "${LocalSshPort2}:${RemoteSshHost2}:${RemoteSshPort2}",
        "-L", "${LocalSshPort3}:${RemoteSshHost3}:${RemoteSshPort3}",
        "-L", "${LocalSshPort4}:${RemoteSshHost4}:${RemoteSshPort4}",
        "-L", "${LocalSshPort5}:${RemoteSshHost5}:${RemoteSshPort5}",
        "-L", "${LocalSshPort6}:${RemoteSshHost6}:${RemoteSshPort6}"
    )

    if ($WorkPCPassword) {
        $UsePassword = $WorkPCPassword
    }
    else {
        # 매번 실행 시 수동으로 암호를 입력받도록 수정 (Pageant 무시)
        $InputPass = Read-Host -Prompt "업무용 PC($WorkPC) 접속 암호를 입력하세요" -AsSecureString
        if ($InputPass) {
            # SecureString을 일반 문자열로 변환 (plink 전달용)
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($InputPass)
            $UsePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }

    if ($UsePassword) {
        $encodedPass = "`"$($UsePassword -replace '`"', '\"')`""
        $plinkArgs += "-pw", $encodedPass
        $plinkArgs += "-batch"
    }
    else {
        Write-Host "![오류] 암호가 입력되지 않았습니다. 연결을 중단합니다." -ForegroundColor Red
        exit
    }
    
    $plinkArgs += "${WorkPCUser}@${WorkPC}"
    
    $logCmd = "plink $($plinkArgs -join ' ')"
    if ($UsePassword) { $logCmd = $logCmd.Replace($UsePassword, "********") }
    
    # 프로세스 실행 (AppLocker 등 정책 차단 대비 try-catch)
    try {
        $process = Start-Process plink -ArgumentList $plinkArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
    } catch {
        Write-Host "![오류] plink 실행이 차단되었거나 실패했습니다: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ">>> ssh(OpenSSH)로 대체 접속을 시도합니다..." -ForegroundColor Yellow
        $process = $null
        $UsePlink = $false
    }

    if ($UsePlink -and $null -ne $process) {
        # 2. 터널 대기
        Write-Host ">>> 터널이 열리기를 기다리는 중..." -NoNewline
        $timeout = 15
        $failed = $false
        while ($timeout -gt 0 -and -not (Test-Port $SocksPort)) {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 1
            
            if ($process.HasExited) {
                $failed = $true
                break
            }
            $timeout--
        }
        
        # 타임아웃이 지났는데도 포트가 안 열렸다면 백그라운드 plink 오류 가능성 큼
        if (-not (Test-Port $SocksPort)) {
            $failed = $true
            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
        
        if ($failed -and -not (Test-Port $SocksPort)) {
            Write-Host " (연결 실패)" -ForegroundColor Red
            Write-Host ">>> [안내] 접속에 실패했습니다. 암호가 틀렸거나 네트워크 연결(VPN 등)에 문제가 있을 수 있습니다." -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

if (-not $UsePlink) {
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Host "![오류] plink와 ssh가 모두 설치되어 있지 않아 연결할 수 없습니다." -ForegroundColor Red
        exit
    }

    Write-Host ">>> ssh(OpenSSH)를 사용하여 수동 연결을 시도합니다." -ForegroundColor Yellow
    # OpenSSH 사용 시 KeepAlive 및 백그라운드 옵션
    $sshArgs = "-N -p $WorkPCPort -D $SocksPort " + `
        "-L ${LocalSshPort1}:${RemoteSshHost1}:${RemoteSshPort1} " + `
        "-L ${LocalSshPort2}:${RemoteSshHost2}:${RemoteSshPort2} " + `
        "-L ${LocalSshPort3}:${RemoteSshHost3}:${RemoteSshPort3} " + `
        "-L ${LocalSshPort4}:${RemoteSshHost4}:${RemoteSshPort4} " + `
        "-L ${LocalSshPort5}:${RemoteSshHost5}:${RemoteSshPort5} " + `
        "-L ${LocalSshPort6}:${RemoteSshHost6}:${RemoteSshPort6} " + `
        "-o ServerAliveInterval=30 -o ServerAliveCountMax=3 " + `
        "-o StrictHostKeyChecking=accept-new " + `
        "${WorkPCUser}@${WorkPC}"
    
    Start-Process ssh -ArgumentList $sshArgs -NoNewWindow
    
    Write-Host ">>> 터널이 열리기를 기다리는 중..." -NoNewline
    $timeout = 15
    while ($timeout -gt 0 -and -not (Test-Port $SocksPort)) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        $timeout--
    }
    Write-Host ""
}

# 3. 최종 상태 확인
if (Test-Port $SocksPort) {
    Write-Host ">>> [성공] 업무 터널이 활성화되었습니다!" -ForegroundColor Green
    Write-Host ">>> SOCKS5 프록시: localhost:$SocksPort"
    Write-Host "------------------------------------------------------------"
    Write-Host "터널 상태 (Local Port -> Remote Host):" -ForegroundColor Cyan
    Write-Host "    $LocalSshPort1 -> $RemoteSshHost1 (stg-kr)"
    Write-Host "    $LocalSshPort2 -> $RemoteSshHost2 (stg-us)"
    Write-Host "    $LocalSshPort3 -> $RemoteSshHost3 (prd-kr)"
    Write-Host "    $LocalSshPort4 -> $RemoteSshHost4 (prd-us)"
    Write-Host "    $LocalSshPort5 -> $RemoteSshHost5 (prd-cn)"
    Write-Host "    $LocalSshPort6 -> $RemoteSshHost6 (dev)"
    Write-Host "------------------------------------------------------------"
    Write-Host ">>> [설정 가이드] 특정 도메인만 프록시 사용하기" -ForegroundColor Yellow
    Write-Host "    1. 브라우저 설정에서 '자동 프록시 구성(PAC)'을 찾아 선택하세요."
    Write-Host "    2. 다음 경로를 입력하세요: file://C:/Dev/workspace/proxy.pac"
    Write-Host "    3. 이제 *.mcsvc.samsung.com 접속 시에만 터널을 사용합니다."
    Write-Host "------------------------------------------------------------"
}
else {
    Write-Host "![실패] 터널 연결에 실패했습니다. 수동으로 확인해 주세요." -ForegroundColor Red
}
