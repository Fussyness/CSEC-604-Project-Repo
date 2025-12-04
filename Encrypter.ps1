<#
.SYNOPSIS
  Bulk AES file encryptor (non-destructive) + decryptor.
.DESCRIPTION
  Combines Protect-AesFile and Unprotect-AesFile into one script and runs a bulk
  encryption loop that writes encrypted copies (.enc) into a storage folder,
  preserving folder structure. Originals remain unchanged.
.NOTES
  - Requires PowerShell 5.0+
  - For legitimate backup/archival use only.
  - Keep your password or Key/IV safe. If lost, files cannot be recovered.
#>

# --- Configuration: edit these paths and options as needed ---
$ScriptPasswordFile = "C:\Path\Password.txt"   # contains password (first line)
$FilesToEncrypt      = "C:\Path\Example_Test_Files"  # source root to scan
$StorageRoot         = "C:\Path\Storage"  # destination root for encrypted copies
$KeySize             = 256
$CipherMode          = 'CBC' # 'CBC' or 'ECB' (CBC recommended)
$Iterations          = 10000
$ExcludePattern      = '^C:\\Windows(\\|$)|^C:\\Program Files(\\|$)|^C:\\Program Files \(x86\)(\\|$)|^C:\\\$Recycle\.Bin(\\|$)|^C:\\System Volume Information(\\|$)|^C:\\Config\.Msi(\\|$)|^C:\\MSOCache(\\|$)|^C:\\hiberfil\.sys$|^C:\\pagefile\.sys$|^C:\\swapfile\.sys$'
# ----------------------------------------------------------------

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

################################################################################
# Helper functions: hex convert & format
################################################################################
function ConvertFrom-HexString {
    param([Parameter(Mandatory)] [ValidatePattern('^[0-9A-Fa-f]+$')] [string] $String)
    [Byte[]]($String -replace '..', '0x$&,' -split ',' -ne '')
}
function ConvertTo-HexString {
    param([Parameter(Mandatory)] [byte[]] $Bytes)
    ($Bytes | ForEach-Object { $_.ToString('X2') }) -join ''
}
function Format-HexString {
    param(
        [Parameter(Mandatory)] [ValidatePattern('^[0-9A-Fa-f]+$')] [string] $String,
        [int] $Bytes = 8
    )
    $hexLength = $Bytes * 2
    switch ($String) {
        { $_.Length -lt $hexLength } { $_.PadRight($hexLength, '0') }
        { $_.Length -gt $hexLength } { $_.Substring(0, $hexLength) }
        default { $_ }
    }
}

################################################################################
# Protect-AesFile: encrypt one file to an output path (OpenSSL-compatible salted prefix)
# Usage: Protect-AesFile -InFile <path> -OutFile <path> -Password <string> -KeySize <128|192|256> -CipherMode <CBC|ECB> -Iter <int>
################################################################################
function Protect-AesFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-Path -Path $_ -PathType Leaf })][string] $InFile,
        [Parameter(Mandatory)][string] $OutFile,
        [Parameter(Mandatory)][string] $Password,
        [ValidateSet(128,192,256)][int] $KeySize = 256,
        [ValidateSet('CBC','ECB')][string] $CipherMode = 'CBC',
        [int] $Iter = 10000,
        [string] $SaltHex
    )

    # Read file
    $inStream = [System.IO.File]::OpenRead($InFile)
    try {
        # salt (8 bytes)
        if ($SaltHex) {
            $saltBytes = $SaltHex | Format-HexString -Bytes 8 | ConvertFrom-HexString
        } else {
            $saltBytes = New-Object byte[] 8
            $prng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
            $prng.GetBytes($saltBytes)
            $prng.Dispose()
        }

        # derive key & iv via PBKDF2 (Rfc2898DeriveBytes). Use SHA256 when available
        try {
            $pbkdf2 = New-Object -TypeName System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList $Password, $saltBytes, $Iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256
        } catch {
            $pbkdf2 = New-Object -TypeName System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList $Password, $saltBytes, $Iter
        }
        $keyBytes = $pbkdf2.GetBytes($KeySize / 8)
        $ivBytes  = $pbkdf2.GetBytes(16)

        # Build output bytes: OpenSSL "Salted__" + salt, then ciphertext
        $outStream = New-Object System.IO.MemoryStream
        $outStream.Write([System.Text.Encoding]::UTF8.GetBytes('Salted__'), 0, 8)
        $outStream.Write($saltBytes, 0, $saltBytes.Length)

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.BlockSize = 128
        $aes.KeySize = $KeySize
        $aes.Mode = $CipherMode
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $keyBytes
        $aes.IV  = $ivBytes

        $encryptor = $aes.CreateEncryptor()
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        try {
            $inStream.CopyTo($cryptoStream)
            $cryptoStream.FlushFinalBlock()
            $bytes = $outStream.ToArray()
            # Ensure destination directory exists
            $destDir = Split-Path $OutFile -Parent
            if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            [System.IO.File]::WriteAllBytes($OutFile, $bytes)
        } finally {
            $cryptoStream.Dispose()
        }
    } finally {
        $inStream.Dispose()
        if ($aes -and ($aes -is [IDisposable])) { $aes.Dispose() }
    }
}

################################################################################
# Unprotect-AesFile: decrypt file produced by Protect-AesFile
# Usage: Unprotect-AesFile -InFile <path> -OutFile <path> -Password <string>
################################################################################
function Unprotect-AesFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateScript({ Test-Path -Path $_ -PathType Leaf })][string] $InFile,
        [Parameter(Mandatory)][string] $OutFile,
        [Parameter(Mandatory)][string] $Password,
        [ValidateSet(128,192,256)][int] $KeySize = 256,
        [ValidateSet('CBC','ECB')][string] $CipherMode = 'CBC',
        [int] $Iter = 10000
    )

    $raw = [System.IO.File]::ReadAllBytes($InFile)

    # Expecting OpenSSL salted format: "Salted__" + 8 bytes salt + ciphertext
    if ($raw.Length -lt 16) { throw "Input file too short / invalid format." }

    $prefix = [System.Text.Encoding]::UTF8.GetString($raw, 0, 8)
    if ($prefix -ne 'Salted__') { throw "Unrecognized input format (missing Salted__ prefix)." }

    $saltBytes = $raw[8..15]
    $ciphertext = $raw[16..($raw.Length - 1)]

    try {
        $pbkdf2 = New-Object -TypeName System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList $Password, $saltBytes, $Iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256
    } catch {
        $pbkdf2 = New-Object -TypeName System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList $Password, $saltBytes, $Iter
    }
    $keyBytes = $pbkdf2.GetBytes($KeySize / 8)
    $ivBytes  = $pbkdf2.GetBytes(16)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.BlockSize = 128
    $aes.KeySize = $KeySize
    $aes.Mode = $CipherMode
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = $keyBytes
    $aes.IV  = $ivBytes

    $inStream = New-Object System.IO.MemoryStream(,$ciphertext)
    $outStream = New-Object System.IO.MemoryStream
    $decryptor = $aes.CreateDecryptor()
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($inStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
    try {
        $buffer = New-Object byte[] 4096
        while (($read = $cryptoStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outStream.Write($buffer, 0, $read)
        }
        $plaintext = $outStream.ToArray()
        $destDir = Split-Path $OutFile -Parent
        if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes($OutFile, $plaintext)
    } finally {
        $cryptoStream.Dispose()
        if ($aes -and ($aes -is [IDisposable])) { $aes.Dispose() }
    }
}

################################################################################
# Bulk encryption loop (non-destructive)
################################################################################
# Load password
if (!(Test-Path -Path $ScriptPasswordFile -PathType Leaf)) {
    Write-Error "Password file not found: $ScriptPasswordFile"
    return
}
$Password = (Get-Content -Path $ScriptPasswordFile -ErrorAction Stop | Select-Object -First 1).Trim()
if ([string]::IsNullOrEmpty($Password)) { Write-Error "Password file is empty."; return }

# create storage root if needed
if (!(Test-Path $StorageRoot)) { New-Item -ItemType Directory -Path $StorageRoot -Force | Out-Null }

# enumerate files
$items = Get-ChildItem -Path $FilesToEncrypt -File -Recurse -Force -ErrorAction SilentlyContinue
$count = 0
$errors = 0

foreach ($item in $items) {
    try {
        if ($item.FullName -match $ExcludePattern) {
            Write-Verbose "Skipping excluded: $($item.FullName)"
            continue
        }

        # compute relative path and output path
        $relativePath = $item.FullName.Substring($FilesToEncrypt.Length).TrimStart('\','/')
        if ([string]::IsNullOrEmpty($relativePath)) { $relativePath = $item.Name }
        $outPath = Join-Path -Path $StorageRoot -ChildPath ($relativePath + ".enc")

        Write-Host "Encrypting -> $outPath"
        Protect-AesFile -InFile $item.FullName -OutFile $outPath -Password $Password -KeySize $KeySize -CipherMode $CipherMode -Iter $Iterations

        $count++
    } catch {
        Write-Warning "Failed to encrypt $($item.FullName): $($_.Exception.Message)"
        $errors++
    }
}

Write-Host "This is a model ransom note. Your files can be safely decrypted with the matching decryption script"

# Example: how to decrypt a single file (uncomment & edit to use)
# Unprotect-AesFile -InFile "C:\Path\Storage\some\file.txt.enc" -OutFile "C:\Path\Restored\file.txt" -Password (Get-Content $ScriptPasswordFile | Select-Object -First 1)

# End of script
