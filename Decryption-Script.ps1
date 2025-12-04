param(
    [Parameter(Mandatory = $true)]
    [string]$InFile,

    [Parameter(Mandatory = $true)]
    [string]$OutFile,

    [Parameter(Mandatory = $true)]
    [string]$Password
)

# --- Default AES Settings (match encryption script) ---
$KeySize   = 256
$BlockSize = 128
$Mode      = "CBC"
$Padding   = "PKCS7"

# --- Read encrypted file (Salt + IV + Ciphertext) ---
$Bytes = [System.IO.File]::ReadAllBytes($InFile)

# Salt is first 16 bytes
$Salt = $Bytes[0..15]

# IV is next 16 bytes
$IV   = $Bytes[16..31]

# Ciphertext is everything after
$CipherText = $Bytes[32..($Bytes.Length - 1)]

# --- Derive Key using PBKDF2 (must match encryption script) ---
$Derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 100000)
$Key = $Derive.GetBytes($KeySize / 8)

# --- Create AES decryptor ---
$AES = [System.Security.Cryptography.Aes]::Create()
$AES.KeySize  = $KeySize
$AES.BlockSize = $BlockSize
$AES.Mode = $Mode
$AES.Padding = $Padding
$AES.Key = $Key
$AES.IV  = $IV

$Decryptor = $AES.CreateDecryptor()

# --- Perform Decryption ---
$PlainBytes = $Decryptor.TransformFinalBlock($CipherText, 0, $CipherText.Length)

# --- Write output file ---
[System.IO.File]::WriteAllBytes($OutFile, $PlainBytes)

Write-Host "Decrypted $InFile → $OutFile"
