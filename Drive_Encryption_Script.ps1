# Load the single-file encryption function
. "C:\Path\Protect-AesFile.ps1" 

# Define source drive and destination root
$SourceDir = "C:\"
$DestDir = "Path\Encrypted_Drive_Data" 
$Password = "add password here"

#exclude critical and useless files from being encrypting so program can run smoothly 
$ExcludePattern = "^C:\\Windows|^C:\\Program Files|^C:\\Program Files \(x86\)|^C:\\$Recycle.Bin|^C:\\System Volume Information|^C:\\Config.Msi|^C:\\MSOCache|^C:\\hiberfil.sys|^C:\\pagefile.sys|^C:\\swapfile.sys"

# Use Get-ChildItem and filter out system paths before processing
Get-ChildItem -Path $SourceDir -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch $ExcludePattern } | 
    ForEach-Object {
        # Calculate new path, preserving folder structure in the output folder 
        $relativePath = $_.FullName.Substring($SourceDir.Length)
        $newFilePath   = Join-Path -Path $DestDir -ChildPath ($relativePath + ".enc")
        
        # Ensure the destination subdirectory exists
        $newFileDir = Split-Path -Path $newFilePath -Parent
        if (-not (Test-Path $newFileDir)) {
            New-Item -Path $newFileDir -ItemType Directory | Out-Null
        }
        
        # Call the existing function
        try {
            Write-Host "Encrypting: $($_.FullName)"
            Protect-AesFile -InFile $_.FullName -OutFile $newFilePath -Password $Password
        }
        catch {
            Write-Warning "Unable to encrypt: $($_.FullName). Receiving error: $($_.Message)"
        }
}

Write-Output "Mission accomplished!"