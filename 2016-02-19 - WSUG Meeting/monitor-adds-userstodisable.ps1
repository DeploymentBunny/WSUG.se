<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   SMA Runbook that disables AD User account
.DESCRIPTION
   Disables AD user accounts in specified OU with Last Logon older than specified age and moves them to another Specified OU
.Perquisites
   In SMA you need to have a Credential Asset that has privileges in AD to delete the Account.
   On the SMA Runbook servers you need to have the AD PowerShell CMDLET installed. 
#> 

workflow Monitor-ADDS-UsersToDisable
{
    PARAM(
        [Parameter(Mandatory=$True)]
        [String]$Age,
        [Parameter(Mandatory=$True)]
        [String]$SearchOUDN,        
        [Parameter(Mandatory=$True)]
        [String]$DisabelOUDN,
        [Parameter(Mandatory=$True)]
        [String]$CredentialAssetName 
    )
    #Credentials
    $Credentials = Get-AutomationPSCredential -name $CredentialAssetName
    
    #Variables
    $AgeDate = (get-date).AddDays(-$age)
    
    #Get Users
    $Users = Get-ADUser -Filter * -SearchBase $SearchOUDN -Properties lastLogon -Credential $Credentials
    
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
                Disable-ADAccount -Identity $User.DistinguishedName -Credential $Credentials
                Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabelOUDN -Credential $Credentials
                $User = $User.UserPrincipalName
                Write-Output "Account $User is disabled"
            }
        }
    }   
}