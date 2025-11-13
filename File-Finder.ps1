#Script to find all files in specified folder. In this case the TargetFiles Folder

$FolderPath = "C:\Users\Jonathan\CSEC-604-Project-Repo\TargetFiles"

$OutputFile = "EncryptionTargets.txt"

Get-ChildItem -Path $FolderPath -File -Recurse -Force | Select-Object -ExpandProperty FullName | Out-File -FilePath $OutputFile
