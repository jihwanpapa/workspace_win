# Redesign: Separated SSH Credentials

The `Permission denied` error occurred because `jinyoung.hur` was used to log into the intermediate Work PC (10.110.1.182), which only recognizes the local or domain account (e.g., `hjy_p`).

## User Review Required
> [!IMPORTANT]
> **Work PC User vs Remote User**
> - **Work PC User**: The account you use to log into the physical PC via RDP or SSH (Check `whoami` on the Remote Desktop).
> - **Remote User**: The account (`jinyoung.hur`) used for the final destination (52.78.116.245).

## Proposed Changes

### [connect_work.ps1](file:///c:/Dev/workspace/connect_work.ps1)

#### [MODIFY] [connect_work.ps1](file:///c:/Dev/workspace/connect_work.ps1)
- Introduce `$WorkPCUser`, `$WorkPCPass`, and `$RemoteUser`.
- Use `plink.exe` (PuTTY) for auto-authentication with the `-pw` flag.
- Add logic to check if `plink` is installed and fall back to manual SSH if not.

## Verification Plan
1. Install PuTTY via `choco install putty -y`.
2. Run `connect_work.ps1` and verify the tunnel establishes without a password prompt.
3. Verify the final connection via the tunnel.
