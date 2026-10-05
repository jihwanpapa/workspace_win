param([string]$Server)

$ConfigFile = Join-Path (Split-Path -Parent $PSScriptRoot) "config.txt"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Error: config.txt not found!" -ForegroundColor Red
    exit
}

# Parse config.txt
$config = @{}
Get-Content $ConfigFile | Where-Object { $_ -match "^[^#]" -and $_ -match "=" } | ForEach-Object {
    $parts = $_.Split("=", 2)
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

$User = $config["SSH_USER"]
$Password = $config["SSH_PASS"]
$Secret = $config["OTP_SECRET"]

if (-not $User -or -not $Password -or -not $Secret) {
    Write-Host "Error: Missing configuration in config.txt" -ForegroundColor Red
    exit
}

$Ports = @{
    "stg-kr" = 50022
    "stg-us" = 50023
    "prd-kr" = 60022
    "prd-us" = 60023
    "prd-cn" = 60024
    "dev" = 30022
}

if (-not $Server) {
    $Server = Read-Host "접속할 서버를 입력하세요 (stg-kr, stg-us, prd-kr, prd-us, prd-cn, dev)"
}

if (-not $Ports.ContainsKey($Server)) {
    Write-Host "Invalid server!" -ForegroundColor Red
    exit
}
$Port = $Ports[$Server]

function Get-Base32DecodedBytes($Base32String) {
    $alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $Base32String = $Base32String.ToUpper().Replace("=", "")
    $bytes = New-Object byte[] (($Base32String.Length * 5) / 8)
    $buffer = 0
    $bitsLeft = 0
    $byteIndex = 0
    foreach ($char in $Base32String.ToCharArray()) {
        $charValue = $alphabet.IndexOf($char)
        $buffer = ($buffer -shl 5) -bor $charValue
        $bitsLeft += 5
        if ($bitsLeft -ge 8) {
            $bytes[$byteIndex] = ($buffer -shr ($bitsLeft - 8)) -band 255
            $byteIndex++
            $bitsLeft -= 8
        }
    }
    return $bytes
}

function Get-TOTP($SecretBase32) {
    $secretBytes = Get-Base32DecodedBytes $SecretBase32
    $unixEpoch = (New-TimeSpan -Start (Get-Date "1970-01-01 00:00:00Z") -End (Get-Date).ToUniversalTime()).TotalSeconds
    $timeStep = [Math]::Floor($unixEpoch / 30)
    
    $timeBytes = [BitConverter]::GetBytes([long]$timeStep)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($timeBytes) }
    
    $hmac = New-Object System.Security.Cryptography.HMACSHA1
    $hmac.Key = $secretBytes
    $hash = $hmac.ComputeHash($timeBytes)
    
    $offset = $hash[$hash.Length - 1] -band 0x0F
    $binary = (($hash[$offset] -band 0x7F) -shl 24) -bor (($hash[$offset + 1] -band 0xFF) -shl 16) -bor (($hash[$offset + 2] -band 0xFF) -shl 8) -bor ($hash[$offset + 3] -band 0xFF)
    $otp = $binary % 1000000
    return $otp.ToString("D6")
}

Write-Host "Starting SSH connection to $Server ($User@127.0.0.1:$Port) ..." -ForegroundColor Cyan
Write-Host "Please DO NOT touch the keyboard or mouse while authenticating!" -ForegroundColor Yellow

$wshell = New-Object -ComObject wscript.shell
# Launch SSH (using 127.0.0.1 since the tunnel is on the local Windows machine)
$wshell.Run("cmd.exe /c ssh -p $Port -o StrictHostKeyChecking=accept-new $User@127.0.0.1")

# Wait for Password prompt
Start-Sleep -Seconds 2
$wshell.SendKeys("$Password{ENTER}")

# Wait for OTP prompt
Start-Sleep -Seconds 2
$otp = Get-TOTP $Secret
$wshell.SendKeys("$otp{ENTER}")

Write-Host "Done!" -ForegroundColor Green
