<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   Script disables AD User account
.DESCRIPTION
   Disables AD user accounts in specified OU with Last Logon older than specified age and moves them to another Specified OU
.EXAMPLE
   To run the script to disable AD Users in OU Accounts that hasn’t logged in for 90 days and moves them to Disabled Accounts
   .\DisableADUserAccounts.ps1 -Age 90 -SearchOUDN "OU=User Accounts,DC=domain,DC=com" -DisabelOUDN "OU=Disabled Accounts,DC=domain,DC=com"
#>

PARAM(
    [Parameter(Mandatory=$True)]
    [String]$Age,
    [Parameter(Mandatory=$True)]
    [String]$SearchOUDN,        
    [Parameter(Mandatory=$True)]
    [String]$DisabelOUDN
)

#Variables
$AgeDate = (get-date).AddDays(-$age)

#Get Users
$Users = Get-ADUser -Filter * -SearchBase $SearchOUDN -Properties lastLogon
    
#Check Users Last Logon and disable if logon older than agedate
ForEach($User in $Users){
    #Get Users Last Logon
    $LastLogonTimestamp = $user.lastLogon
    
    #Check if user has a LastLogonTimeStamp
    IF($LastLogonTimestamp.count -ne 0 -and $LastLogonTimestamp -ne 0){
        #Convert LongInteger to DateTime
        $LastLogon = [DateTime]::FromFiletime([Int64]::Parse($lastLogonTimestamp))
        #Check If user should be disabled
        IF($LastLogon -le $AgeDate){
            Disable-ADAccount -Identity $User.DistinguishedName
            Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabelOUDN
            $User = $User.UserPrincipalName
            Write-Output "Account $User is disabled"
        }
    }
}