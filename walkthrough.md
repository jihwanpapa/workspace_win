# Walkthrough - SSH Tunneling Setup (Multi-Credential)

The script has been updated to handle separate credentials for the jump host and the final destination.

## Changes Made

### 1. Multi-Credential Support
- **Work PC User**: `bizjyheo` (used to establish the bridge to 10.110.1.182).
- **Remote User**: `jinyoung.hur` (used to log into the target 52.78.116.245).

### 2. Script UI Improvements
- Added a clear step-by-step guide in the console output.
- Included the exact command to run in a second terminal.

## Final Steps to Connect
1. Run the `connect_work.ps1` script on your Local PC.
2. **First Password**: Enter the Windows/Domain password for `bizjyheo` (Work PC).
3. Once the tunnel is established, run: `ssh -p 40022 jinyoung.hur@localhost` in a new terminal.
4. **Second Password**: Enter the password for `jinyoung.hur` (Remote Server).

> [!TIP]
> SSH 터미널에서 암호를 입력할 때는 보안을 위해 입력 내용이 화면에 표시되지 않습니다. (별표 `*`도 나오지 않음)
