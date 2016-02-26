<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   Sends an E-mail if a failed login happens for a User Account in specifed OU
.DESCRIPTION
   If event 4771 is recorded in the Security Eventlog on the Domain Controller a E-mail will be sent to the AD Users Mail.
   If a mail entry is missing on the AD User a mail will be sent to the AdminMail.
.EXAMPLE
   To run the script to search OU 'Admin Accounts' with support@domain.com as sender and use mailserver mail.domain.com on port 25 and admins mail is admins@domain.com
   .\FailedADLogInMail.ps1 -OUSearchbase "OU=Admin Accounts,DC=domain,DC=com" -AdminMail "admins@domain.com" -MailFrom "support@domain.com" -SMTPServer "mail.domain.com" -SMTPPort 25
#>
PARAM(
    [Parameter(Mandatory=$True)]
    [string]$OUSearchbase,
    [Parameter(Mandatory=$True)]
    [string]$AdminMail,
    [Parameter(Mandatory=$True)]
    [string]$MailFrom,
    [Parameter(Mandatory=$True)]
    [string]$SMTPServer,
    [Parameter(Mandatory=$True)]
    [int]$SMTPPort
)

#Variables
$EventlogName = "Security"
$EventID = "4771"
$Date = get-date
$DomainControllers = [system.directoryservices.activedirectory.domain]::GetCurrentDomain() | ForEach-Object {$_.DomainControllers}

#Get Event
$Event = Get-EventLog -LogName $EventlogName -InstanceId $EventID -Newest 1 -Before $date
$EventTime = $event.TimeGenerated

#Get User and Computer information

#User Name and Mail
$UserName = $Event.ReplacementStrings[0]
$ADUser = Get-ADUser -SearchBase $OUSearchbase -filter {SamAccountName -eq $UserName} -Properties mail
IF($ADUser.count -eq 0){exit}
$UserEmail = $ADUser.mail

#Computer DNS Name
$ComputerIP = $Event.ReplacementStrings[6].Replace(":","").Replace("f","")
$ComputerName = ([System.Net.dns]::GetHostbyAddress($ComputerIP)).HostName

#Check if computer is domain controller and check with other Domain Controller if the failed login is made on the domaincontroller or other computer
ForEach($DomainController in $DomainControllers){
    IF($ComputerIP -eq $DomainController.ipaddress){
       $Event = Get-EventLog -LogName $EventlogName -InstanceId $EventID -Newest 1 -Before $date -ComputerName $ComputerName
       $ComputerIP = $Event.ReplacementStrings[6].Replace(":","").Replace("f","")
       $ComputerName = ([System.Net.dns]::GetHostbyAddress($ComputerIP)).HostName
    }
}

#Send E-mail
IF($UserEmail.count -eq 0){
    $Subject = "Admin Account Failed login and Missing E-mail address"
    $Body = @"
    Failed Logon for user $UserName on computer $ComputerName with IP $ComputerIP on $EventTime

    The Admin Account is missing E-mail address, please add e-mail address to account $UserName
"@
    Send-MailMessage -From $MailFrom -to $AdminMail -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort
}
IF($UserEmail.count -ne 0){
    $Subject = "Failed Admin Account Login"
    $Body = @"
    Failed Logon for user $UserName on computer $ComputerName with IP $ComputerIP on $EventTime
"@
    Send-MailMessage -From $MailFrom -to $UserEmail -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort
}