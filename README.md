"# CSEC-604-Project-Repo" 

Testing-
In order to test the code these parts must be replaced by the user in both the scripts: 

1) for this line of code ---> . "C:\Path\Protect-AesFile.ps1" in Encryption_Script.ps1 
Add the path, in replacement of 'Path', which leads to the folder where the Protect-AesFile.ps1 is located

2) for this line of code ---> . "C:\Path\Unprotect-AesFile.ps1" in Decryption_Script.ps1 
Add the path, in replacement of 'Path', which leads to the folder where the Unprotect-AesFile.ps1 is located

3) for this line of code ----> $FilesToEncrypt = "C:\Path\Example_Test_Files" in Encryption_Script.ps1
Add the path which leads to the drive/folder/file you want to encrypt in replacement of 'Path', and add the name of your drive/folder/file you want to encrypt in place of "Example_Test_Files"

4) for this line of code ----> $FilesToDecrypt = "C:\Path\Example_Test_Files" in Decryption_Script.ps1
Add the path which leads to the drive/folder/file you want to decrypt in replacement of 'Path', and add the name of your drive/folder/file you want to decrypt in place of "Example_Test_Files"

5) for this line of code ---> $Storage = "C:\Path\Storage" in Encryption_Script.ps1 and Decryption_Script.ps1
Add the path, in replacement of 'Path', which leads to the drive/folder/file where you want the temporary contents to be stored. A folder by the name "Storage" will be created there once the script (and the related code to create a directory by the name of Storage), is run.  

6) OPTIONAL: Change the pasword in Password.txt to a strong password of your choice 


Enryption_Script.ps1:
This scripts allows a user to encrypt a drive/folder/file. It goes through all the items to be encrypted by using a for loop and calling the function Protect-AesFile on the object, encrypting it. The encrypted contents are temporarily stored in a file, before overwriting the original file with the storage file's contents. At the end of the process, a message is displayed to the user that their files have been encrypted. 

Decryption_Script.ps1:
This scripts allows a user to decrypt a drive/folder/file. It goes through all the items to be decrypted by using a for loop and calling the function Unprotect-AesFile on the object, decrypting it. The decrypted contents are temporarily stored in another file, before overwriting the original file with the storage file's contents. The user now has their files back in their original form. At the end of the process, a message is displayed to the user that their files have been decrypted. 

Password.txt:
A strong value for the password variable required in the Protect-AesFile and UnprotectAesFile functions. 

Protect-AesFile.ps1:
Taken from Powershell AES Encryption Set https://github.com/mnghsn/powershell-aes. A slight change was implemented to the file in order to use it as a function. 

Unprotect-Aesfile.ps1:
Taken from Powershell AES Encryption Set https://github.com/mnghsn/powershell-aes. A slight change was implemented to the file in order to use it as a function. 
