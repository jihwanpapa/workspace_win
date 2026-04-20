# 업무 자원 원격 접속(SSH 터널링) 설정 가이드

이 가이드는 회사 RDP(원격 데스크톱)를 사용하지 않고도 로컬 PC에서 업무 사이트 및 서버에 직접 접속할 수 있는 SSH 터널링 환경을 구축하는 방법을 설명합니다.

---

## 1. 업무용 PC 설정 (Work PC / Jump Host)

터널링의 관문 역할을 할 업무용 PC에서 SSH 서버를 활성화해야 합니다. 모든 작업은 **관리자 권한 파워쉘(PowerShell)**에서 진행합니다.

### 1-1. OpenSSH 서버 설치
아래 명령어를 입력하여 OpenSSH 서버 기능을 설치합니다.
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### 1-2. 서비스 시작 및 자동 실행 설정
설치가 완료되면 서비스를 시작하고, PC 재부팅 시에도 자동으로 실행되도록 설정합니다.
```powershell
# 서비스 시작
Start-Service sshd

# 자동 실행 설정
Set-Service -Name sshd -StartupType 'Automatic'
```

### 1-3. 방화벽 포트 허용
SSH 접속 포트(기본 22번 또는 커스텀 포트)를 외부에서 접근할 수 있도록 허용합니다.
```powershell
# 22번 포트 허용 (기본값)
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow

# 만약 40022 포트를 사용한다면:
# New-NetFirewallRule -Name sshd_40022 -DisplayName 'SSH Tunnel 40022' -Enabled True -Direction Inbound -Protocol TCP -LocalPort 40022 -Action Allow
```

---

## 2. 로컬 PC 설정 (Local PC / Client)

업무용 PC에 접속하여 터널을 생성할 로컬 PC 설정입니다. **아래 순서대로** 진행해야 정상적으로 작동합니다.

### 2-1. [필수] plink(PuTTY) 설치
암호 자동 입력 지원 및 백그라운드 터널링을 위해 PuTTY의 `plink`가 필요합니다.

1.  **설치 (PowerShell 관리자 권한)**:
    ```powershell
    # Chocolatey 사용 시
    choco install putty -y

    # 수동 설치: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html (64-bit MSI 추천)
    ```
2.  **설치 확인**: 터미널에서 `plink -V`를 입력해 버전 정보가 출력되는지 확인합니다.

### 2-2. [준비] 인증 설정 (Pageant 또는 암호 확인)
스크립트 실행 전, 업무용 PC에 접속하기 위한 인증 수단이 준비되어야 합니다.

-   **추천 (Pageant 사용)**: `pageant.exe`를 실행하고 본인의 SSH Key를 등록해두면, 스크립트 실행 시 암호를 묻지 않고 즉시 터널이 열립니다. (가장 편리하고 안전함)
    -   **[참고] Pageant 인증 정보 관리**:
        1. 시스템 트레이(시계 옆)에서 Pageant 아이콘(모자 쓴 컴퓨터 모양)을 찾아 **우클릭**합니다.
        2. **View Keys**: 현재 등록된 키 목록을 확인합니다.
        3. **Add Key**: 새로운 `.ppk` 키 파일을 추가합니다. (이때 키의 암호를 한 번 입력해야 합니다.)
        4. **Remove Key**: 기존 키를 삭제하고 다시 등록하여 암호를 업데이트할 수 있습니다.
    -   **[참고] Pageant용 .ppk 파일 생성 방법 (PuTTYgen)**:
        1. **PuTTYgen** 실행 (PuTTY 설치 시 함께 설치됨)
        2. **Generate** 버튼 클릭 후 빈 영역에서 마우스를 계속 움직여 키 생성
        3. **Key passphrase** 입력 (필수 아님, 입력하면 키 로드 시마다 암호 확인)
        4. **Save private key** 클릭하여 `.ppk` 파일로 저장 (이 파일을 Pageant에 등록)
        5. 상단의 **"Public key for pasting into OpenSSH authorized_keys file"** 박스 안의 텍스트를 모두 복사 (중요!)
    -   **[참고] 업무용 PC에 내 키 등록하기 (최초 1회)**:
        1. 업무용 PC에 접속 (ID/PW 사용)
        2. `C:\Users\계정명\.ssh\authorized_keys` 파일을 메모장으로 엽니다. (없으면 생성)
        3. 새 줄을 만들고 위에서 복사한 **Public Key 텍스트를 붙여넣기** 합니다.
        4. 저장하면 이제 암호 없이 터널을 열 수 있습니다!
-   **대안 (스크립트 내 암호 입력)**: Pageant 사용이 어렵다면, `connect_work.ps1` 파일 상단의 `$WorkPCPassword` 변수에 업무용 PC의 암호를 직접 입력할 수 있습니다. 
    > [!WARNING]
    > 스크립트 파일에 암호를 직접 적어두는 것은 보안상 권장되지 않습니다. 가급적 Pageant를 사용해 주세요.
-   **주의**: 위 두 가지 방법 중 하나라도 설정되어 있지 않으면, 백그라운드 모드에서 암호를 입력할 수 없어 터널 연결에 실패합니다.

### 2-3. [준비] 최초 연결 수락 (Host Key 등록)
**처음 한 번은** 직접 업무용 PC에 접속하여 신뢰할 수 있는 호스트로 등록해야 스크립트가 멈추지 않습니다.
1. 터미널(CMD/PowerShell)에서 아래 명령어를 입력합니다.
   ```powershell
   plink 계정명@업무PC_IP
   ```
2. "Store key in cache? (y/n)" 질문이 나오면 **`y`**를 입력합니다.
3. 접속이 완료(또는 암호를 물어보면)되면 창을 닫아도 됩니다.

### 2-4. 터널링 스크립트 작성 (`connect_work.ps1`)
이제 준비가 끝났습니다. 아래 코드를 복사하여 파일을 만듭니다. 상단 **[정보 수정 영역]**만 본인의 환경에 맞게 수정하세요.

```powershell
# 한글 깨짐 방지를 위한 인코딩 설정 (UTF-8 with BOM으로 저장 권장)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ... (중략: connect_work.ps1의 전체 소스코드는 실제 파일을 참조하세요)
```

### 2-5. 스크립트 실행
1. 파워쉘을 실행합니다.
2. `.\connect_work.ps1`을 실행합니다.
3. "성공" 메시지가 뜨면 터미널 창을 그대로 둡니다. (이후 백그라운드에서 동작합니다.)

---

## 3. 리소스 이용 방법

### 3-1. 서버 접속 (SSH)
새 터미널을 열고 스크립트에서 설정한 로컬 포트로 접속합니다.
```powershell
ssh -p 50022 서버계정@localhost
```

### 3-2. 업무 사이트 접속 (웹 브라우저 및 FoxyProxy 설정)
로컬 브라우저에서 `*.mcsvc.samsung.com` 등의 업무 주소를 그대로 사용하려면 **FoxyProxy Standard** 확장 프로그램을 추천합니다.

#### FoxyProxy 설정 순서:
1.  **확장 프로그램 설치**: Chrome 웹 스토어 또는 Edge 추가 기능에서 `FoxyProxy Standard` 검색 후 설치
2.  **프록시 추가 (Add)**:
    - **Title**: 업무 터널링 (임의 지정)
    - **Proxy Type**: `SOCKS5`
    - **Proxy IP**: `localhost` (또는 `127.0.0.1`)
    - **Port**: `1080`
    - **DNS via Proxy**: **ON** (반드시 체크해야 업무 도메인 주소를 찾을 수 있습니다.)
3.  **자동 전환 패턴 설정 (Patterns)**:
    - **Add New Pattern** 클릭
    - **Pattern Name**: Samsung 업무망
    - **URL Pattern**: `*.mcsvc.samsung.com*` (별표 포함)
    - **Type**: Wildcard
4.  **모드 선택**: FoxyProxy 아이콘 클릭 후 **"Use Enabled Proxies by Patterns and Order"**를 선택합니다.

---

## 4. 트러블슈팅 (Troubleshooting)

### 4-1. "이미 포트가 사용 중입니다" 메시지
- **원인**: 이전 실행 건이 남아있거나 다른 프로그램이 같은 포트를 쓰고 있음
- **해결**: 모든 파워쉘 창을 닫아도 소용없다면, 아래 명령어로 백그라운드 프로세스를 직접 강제 종료하세요.
  ```powershell
  Stop-Process -Name plink -Force
  ```

### 4-2. "연결 중..."에서 점만 찍히고 실패하는 경우
- **원인 1 (네트워크)**: 업무용 PC가 꺼져 있거나 VPN이 연결되지 않음
- **원인 2 (인증)**: Pageant에 키가 등록되지 않았거나, 업무용 PC 로그인 암호가 틀림
- **확정적 확인**: 백그라운드 대신 터미널에서 직접 `plink 계정명@업무PC_ IP`를 입력하여 어디서 막히는지 확인하세요.

### 4-3. "Host key has changed" 또는 "Server's host key is not cached"
- **원인**: 업무용 PC의 SSH 설정이 바뀌었거나 가이드 2-3 단계를 건너뜜
- **해결**: 가이드 2-3의 명령어를 다시 실행하여 `y`를 눌러 캐시를 업데이트하세요.

### 4-4. 수동 연결 확인 방법 (디버깅)
스크립트가 "실패"를 출력하고 원인을 알 수 없을 때, 아래 명령어를 통해 직접 에러 메시지를 확인할 수 있습니다.

1. **디버깅 명령어**:
   ```powershell
   plink -v -P 40022 -N -D 1080 -L 50022:52.78.116.245:40022 bizjyheo@10.110.1.182
   ```
   *(주의: 위 명령어의 계정명과 IP, 포트는 본인의 환경에 맞게 수정하세요.)*

2. **주요 체크 포인트**:
   - `Access denied`: 암호가 틀렸거나 인증 키(Pageant) 문제
   - `Unable to open connection`: 업무용 PC IP/포트가 틀렸거나 네트워크(VPN) 차단
   - `Could not set up port forwarding`: 로컬 포트(1080, 50022 등)가 이미 사용 중임
   - `FATAL ERROR: Network error`: 업무용 PC의 SSH 서버(sshd)가 작동 중인지 확인

---

## 5. 최종 활용 예시 (Cheat Sheet)

### ✅ 매일 아침 출근 루틴
1. 업무용 PC 전원 및 VPN 상태 확인
2. 로컬 PC에서 `connect_work.ps1` 우클릭 -> **PowerShell로 실행** 선택
3. "성공" 메시지 확인 후 창 닫기

### 🚀 서버 접속 명령어
- **STG**: `ssh -p 50022 계정명@localhost`
- **PRD(KR)**: `ssh -p 60022 계정명@localhost`
- **DEV**: `ssh -p 30022 계정명@localhost`
