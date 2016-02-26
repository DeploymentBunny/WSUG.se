<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   SMA Runbook that deletes AD Users in specified OU
.DESCRIPTION
   Deletes AD accounts in specified OU with Password age older than specified age
.Perquisites
   In SMA you need to have a Credential Asset that has privileges in AD to delete the Account.
   On the SMA Runbook servers you need to have the AD PowerShell CMDLET installed. 
#> 

workflow Monitor-ADDS-UsersToDelete{
    PARAM(
        [Parameter(Mandatory=$True)]
        [string]$OU,
        [Parameter(Mandatory=$True)]
        [string]$PasswordAge,
        [Parameter(Mandatory=$True)]
        [string]$CredentialAssetName
    )
    #Credentials
    $Credential = Get-AutomationPSCredential -name $CredentialAssetName
    
    #Get Users
    $Users = Get-ADUser -Filter * -SearchBase $OU -Properties PasswordLastSet -Credential $Credential

    #Check Users to be deleted
    ForEach($User in $users){
        IF($User.PasswordLastSet -le ((get-date).AddDays(-$PasswordAge))){
            Remove-ADUser -Identity $User.SamAccountName -Confirm:$false -Credential $Credential
            $UserSAM = $User.SamAccountName
            Write-Output "User $UserSAM has been deleted"
        }
        Else{
            $UserSAM = $User.SamAccountName
            $UserPWage = $User.PasswordLastSet
            Write-Output "User $UserSAM last Password change $UserPWage"
        }
    }
}