#Parameters for file to encrypt, where to send the encryption, and the password for key generation
param(
    [Parameter(Mandatory = $true)]
    [string]$InFile,

    [Parameter(Mandatory = $true)]
    [string]$OutFile,

    [Parameter(Mandatory = $true)]
    [string]$Password
)

#Constants
$Algorithm = "AES"
$KeySize   = 256
$BlockSize = 128
$Mode      = "CBC"
$Padding   = "PKCS7"

# Key gen
$Salt = New-Object byte[] 16
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($Salt)

$Derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 100000)
$Key  = $Derive.GetBytes($KeySize / 8)
$IV   = $Derive.GetBytes($BlockSize / 8)

#Create encrytion obj
$AES = [System.Security.Cryptography.Aes]::Create()
$AES.KeySize  = $KeySize
$AES.BlockSize = $BlockSize
$AES.Mode = $Mode
$AES.Padding = $Padding
$AES.Key = $Key
$AES.IV  = $IV

$Encryptor = $AES.CreateEncryptor()

# Execution
$InBytes  = [System.IO.File]::ReadAllBytes($InFile)
$OutBytes = $Encryptor.TransformFinalBlock($InBytes, 0, $InBytes.Length)

# (needed for decryption)
$Final = $Salt + $IV + $OutBytes
[System.IO.File]::WriteAllBytes($OutFile, $Final)


