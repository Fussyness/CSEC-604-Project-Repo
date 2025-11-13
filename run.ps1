#main executable file for encryption

$FilesToEncrypt = "C:\Users\Jonathan\CSEC-604-Project-Repo\EncryptionTargets.txt"
$Script = "C:\Users\Jonathan\CSEC-604-Project-Repo\Protect-AESFile.ps1"

Get-Content $FilesToEncrypt | Where-Object {$_.Trim() -ne ""} | ForEach-Object{
	$FilePath = $_.Trim()

	if (Test-Path $FilePath) {
		
		Write-Host "Encrypting file: $FilePath"
		& $Script -InFile $FilePath -OutFile $FilePath -Password Password
	}
	else{
		Write-Warning "File not found: $FilePath"
	}

}