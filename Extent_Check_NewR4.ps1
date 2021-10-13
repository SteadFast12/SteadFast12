<#
Configured for Testing
This Powershell script determines if Varible extents are larger then 1GB. Then prompts or sends email to administrator.
Mike Nowak Revsion 1 8/10/21
Mike Nowak Revsion 4 8/10/21  Added Function for sending email using Send-MailMessage.
#>
Set-Variable -Name "strPath" -Value "C:\VBS\productiontesting" # Location of database extents
Set-Variable -Name "LogPath" -Value "C:\VBS\extents_log.txt" # Location of Script Log file


# Change $OutPutStyle variable to select type of output.
# Setting OutPutStyle to "Prompt" Will prompt will prompt user showing Extents over 1GB.  Used if running script manually  Default
# Setting OutPutStyle to "EmailAdmin" Will email the administrator for Extents over 1GB.  Used if Administraor would liked to be emailed if an extent problem arises.
# Setting OutPutStyle to "Prompt_and_Email" Will prompt user and email administrator for Extents over 1GB.  Used if run manally and would like to be emailed. 
$OutPutStyle="Prompt_and_Email"

# Set $EmailAdmin = "Relay" if using an Email Relay server
# Set $EmailAdmin = "Authenticated" if using Email Authentication Login Name and Password to send email
$EmailStaff="Authenticated"
 
Set-Variable -Name "LargeExt" -Value "False"
Set-Variable -Name "Item" -Value ""
Set-Variable -Name "ExtentArea" -Value ""
Set-Variable -Name "ExtentVarNum" -Value 0
Set-Variable -Name "ExtentCaseName" -Value ""
Set-Variable -Name "FileExtention" -Value ""
Set-Variable -Name "ExtentNumber" -Value 0
Set-Variable -Name "sExtentNumber" -Value ""
$The_MAX_FILE_SIZE=1073741823 # Do not change this value for testing enable below.
#$The_MAX_FILE_SIZE=1000000  #Test Value

# Array that holds the Default file types [0] and the value of the Variable Extent Number [1]
$ExtentFileType = @((
"fdb.b","fdb.d","fdb_7.d","fdb_8.d","production.b","production.d","production_12.d","production_100.d","production_101.d","production_102.d","production_103.d"),
(0,0,0,0,0,0,0,0,0,0,0))

 # Array that holds Variable file path [0]
$file = @(" "," "," "," "," "," "," "," "," "," "," "," ")
$file[11]="path to file"

#Holds the Variable File size [0] and if it is Larger then MAX_FILE_SIZE [1]
$filez = @((0,0,0,0,0,0,0,0,0,0,0,0),("","","","","","","","","","","",""))

$FileNames = Get-ChildItem -Path $strPath -Name  -File

ForEach ($Item in $fileNames){
    $ExtentArea=$Item.substring(0,$Item.IndexOf(".")+2)
    for($i=0; $i -le 10; $i++){
    $ExtentCaseName = $ExtentFileType[0][$i]
        If ($ExtentCaseName -eq $ExtentArea){
        # Add additional bad file types if needed - "File Types you don't want to process" see end of file.
        $FileExtension=$Item.Split(".")[1]
            If ($FileExtension -ne "db" -And $FileExtension -ne "bat") {
            $ExtentNumber = $Item.substring($Item.IndexOf(".")+2)
            $Tempextnum=$ExtentFileType[1][$i]
            $Tempextnum=$Tempextnum/1
            $ExtentNumber=$ExtentNumber/1
                If ($Tempextnum -lt $ExtentNumber){
                $ExtentFileType[1][$i]=$ExtentNumber
                $file[$i]=$strpath + "\" + $Item
                $filez[0][$i]=(Get-Item $file[$i]).length
                }
            }
        }
    }
}

#  Evalueate file Array for Large Files.
for($i=0; $i -le 11; $i++){
if ($file[$i] -eq  "path to file"){Break}
$tempfile=$file[$i]
$tempfilez=$filez[0][$i]
$tempfilez=$tempfilez/1
    If ($tempfilez -gt $The_MAX_FILE_SIZE){
	    $filez[1][$i]="Large"
    }    
    		Else{
		    $filez[1][$i]="OK"
            }
    
}

$file
$filez
get-date | Out-file $LogPath 
$file + $filez | Out-file -append $LogPath

$LargeExt="False"		
$EmailText="----------------" + "`r`n"
for($i=0; $i -le 10; $i++){
	if ($filez[1][$i] -eq "Large"){
			$EmailText=$EmailText + "`r`n" + $file[$i] + " " + "Size " + $filez[0][$i]
			$LargeExt="True"
	}
}
$EmailBody=$EmailText #Includes Email Extents to Large

$LargeExt | Out-file -append $LogPath


  
switch -Exact ($OutPutStyle)
{

    'Prompt'{
                If ($LargeExt -eq "True"){
		        [System.Windows.MessageBox]::Show("File to large. Please Notify Suncoast Support" + $EmailText)
		        }
		
		        if ($LargeExt -eq "False"){ 
		        [System.Windows.MessageBox]::Show("No Extents are Greater then 1GB. You are safe")
		        }

            }

    'EmailAdmin'{
                If ($LargeExt -eq "True"){
                MailSend $EmailStaff $EmailBody}
                }

  'Prompt_and_Email'{
                     If ($LargeExt -eq "True"){                              
			          [System.Windows.MessageBox]::Show("An email will be sent to administrator." + $EmailText + "`r`n" + "Email must be configured for this to work")
                        MailSend $EmailStaff $EmailBody
                      [System.Windows.MessageBox]::Show("An email has been sent." + $EmailText + "`r`n" + "Email must be configured for this to work")}
                         
			                IF ($LargeExt -eq "False"){ 
				            [System.Windows.MessageBox]::Show("No Extents are Greater then 1GB. You are safe")
			                }
                     
                    }                                              
}

Function MailSend([string]$Arg1, [string]$Arg2){

#Uncomment and add information to send email
$EmailFrom="newton_BK@compliahealth.com" 
$EmailTo="YourUser@yourdomain.com"
$EmailSubject="Suncoast Database Extents too Large"
$SMTPServer="mail.yourdomain.com"
$EmailStaff=$Arg1
$EmailBody=$Arg2

    If($EmailStaff -eq "Relay") {
    
Send-MailMessage -ErrorAction Stop -from "$EmailFrom" -to "$EmailTo" -subject "$EmailSubject" -body "$EmailBody" -SmtpServer "$SMTPserver" -Priority  "Normal" -Port 25

Return
}

    if($EmailStaff -eq "Authenticated"){
    
# Add this information if you need to use a paasword to authenticate to SMTP server

 $EncryptedPasswordFile="C:\VBS\MailJet.txt" # The CMDlet below creates a password encryption file that holds the encrypted password.
# Set the $EncryptedPasswordFile variable to the MailJet.txt file.

    # Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File -FilePath "Full path to file"\MailJet.txt" 

 $username="YourUser@YourDomain.com"
 $password=Get-Content -Path $EncryptedPasswordFile | ConvertTo-SecureString
 $credential = New-Object System.Management.Automation.PSCredential($username, $password)

 Send-MailMessage -ErrorAction Stop -from $EmailFrom -to $EmailTo -subject $EmailSubject -body $EmailBody -SmtpServer $SMTPserver -Priority  Normal -Credential $credential -Port 587 -UseSsl
 
 Return
 }
Return
}

<#
# Bad file types
 "ST File" .st
 Data Base File" .db
 "LG File" .lg
 "LIC File" .lic
 "LK File" .lk
 "Text Document" .txt, .log
 "Compressed (zipped) Folder" .zip
 "Properties Source File" .properties
 "Application" .exe
 "XML Document" .xml
 "Adobe Acrobat Document" .pdf
 "Microsoft Word Document" .xdoc
 "Microsoft Office Word 97 - 2003 Document" .doc
#>