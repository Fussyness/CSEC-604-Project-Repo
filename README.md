"# CSEC-604-Project-Repo"
Enryption\_Script.ps1:
This script allows a user to encrypt text files in a folder. It goes through all the items to be encrypted by using a for loop. The encrypted contents are temporarily stored in a file, before overwriting the original file with the storage file's contents. At the end of the process, a message is displayed to the user that their files have been encrypted.



Decryption\_Script.ps1:
This script allows a user to decrypt text files in a folder. It goes through all the items to be decrypted by using a for loop. The decrypted contents are temporarily stored in another file, before overwriting the original file with the storage file's contents. The user now has their files back in their original form. At the end of the process, a message is displayed to the user that their files have been decrypted.

Testing:
These scripts were tested and successfully run in Powershell with admin privileges on a Windows 11 VM. To run, navigate to the file location within Powershell and call the script in the following manner:

1. run 'powershell.exe -ExecutionPolicy Bypass -File' followed by the path to either Encryption\_Script.ps1 or Decryption\_Script.ps1 in quotation marks. The path name for the file can be obtained quickly by right-clicking on the file inside file manager and pressing the "Copy as path" button, then copying the path to Powershell with crtl+c
2. The variables for the files you want to encrypt/decrypt, the temporary storage space for the files, and the file containing the password used to generate the Keys must be added onto the command as well by giving the path to the folder/files. This would like -FilesToEncrypt / -FilestoDecrypt, -Storage, and -Password, followed by the respective file paths in quotes.
3. For example, a working command to encrypt the folder of test files inside the project folder would look like this: powershell.exe -ExecutionPolicy Bypass -File "C:\\CSEC-604-Project-Repo\\Encryption\_Script.ps1" -FilesToEncrypt "C:\\CSEC-604-Project-Repo\\Example\_Test\_Files" -Storage "C:\\CSEC-604-Project-Repo\storage.txt" -Password "C:\\CSEC-604-Project-Repo\\Password.txt"
4. Doing the same to decrypt them would look like this: powershell.exe -ExecutionPolicy Bypass -File "C:\\CSEC-604-Project-Repo\\Decryption\_Script.ps1" -FilesToDecrypt "C:\\CSEC-604-Project-Repo\\Example\_Test\_Files" -Storage "C:\\CSEC-604-Project-Repo\storage.txt" -Password "C:\\CSEC-604-Project-Repo\\Password.txt"
5. For examples of working calls to Windows Powershell, look inside the Demo_images folder
