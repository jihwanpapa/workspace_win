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
    $binary = (($hash[$offset] -band 0x7F) -shl 24) -bor
              (($hash[$offset + 1] -band 0xFF) -shl 16) -bor
              (($hash[$offset + 2] -band 0xFF) -shl 8) -bor
              ($hash[$offset + 3] -band 0xFF)
              
    $otp = $binary % 1000000
    return $otp.ToString("D6")
}

# Test with a dummy secret "JBSWY3DPEHPK3PXP" (base32 for "Hello!")
$otp = Get-TOTP "JBSWY3DPEHPK3PXP"
Write-Host "Generated OTP: $otp"
