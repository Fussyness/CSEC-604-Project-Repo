"# CSEC-604-Project-Repo" 
Enryption_Script.ps1:
This script allows a user to encrypt a drive/folder/file. It goes through all the items to be encrypted by using a for loop and calling the function Protect-AesFile on the object, encrypting it. The encrypted contents are temporarily stored in a file, before overwriting the original file with the storage file's contents. At the end of the process, a message is displayed to the user that their files have been encrypted. 

Decryption_Script.ps1:
This script allows a user to decrypt a drive/folder/file. It goes through all the items to be decrypted by using a for loop and calling the function Unprotect-AesFile on the object, decrypting it. The decrypted contents are temporarily stored in another file, before overwriting the original file with the storage file's contents. The user now has their files back in their original form. At the end of the process, a message is displayed to the user that their files have been decrypted. 

Testing:
In order to test the code these parts must be replaced by the user in both the scripts: 
1) for this line of code ----> $FilesToEncrypt = "C:\Path\Example_Test_Files" or $FilesToDecrypt = "C:\Path\Example_Test_Files"
Add the path which leads to the drive/folder/file you want to encrypt in replacement of 'Path', and add the name of your drive/folder/file in place of "Example_Test_Files"
2) for this line of code ---> $Storage = "C:\Path\Storage"
Add the path, in replacement of 'Path', which leads to the drive/folder/file where you want the temporary contents to be stored. A folder by the name "Storage" will automatically be created there once the script is run  
