<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   Script that cleans up the OS drive
.DESCRIPTION
   Cleans up the SoftwareDistribution folder under C:\Windows and also runs a DISM cleanup.
   You can also define folders that should be cleaned.
.EXAMPLE
   To run the script to clean the local computers OSDrive if free space is below 1GB
   .\CleanUpOSDisk.ps1 -ComputerName localhost -FreeSizeMB 1000
.EXAMPLE
   To run script to clean another computers OSDrive if free space is below 1GB and also clean folders C:\Temp and C:\Tools
   .\CleanUpOSDisk.ps1 -ComputerName Computer01.domain.com -FreeSizeMB 1000 -Folder "C:\Temp,C:\Tools"
#>

PARAM(
    [Parameter(Mandatory=$True)]
    [string]$ComputerName,
    [Parameter(Mandatory=$True)]
    [int]$FreeSizeMB,
    [Parameter(Mandatory=$false)]
    [string]$Folder
)

#Functions
Function Invoke-CleanSoftwareDistFolder{
<#
.Author
   mikael.nystrom@truesec.se
.Date
   2015-10-29
.Version
   1.0
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    param(
        $ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Stop-Service -Name wuauserv -Force -Verbose
        $path = "c:\windows\SoftwareDistribution"
        if (Test-Path $path -Verbose)
        {
                Remove-Item -Path $path -Recurse -Verbose
                Start-Service -Name wuauserv -Verbose
                Invoke-Command {wuauclt.exe /detectnow} -Verbose
        }
        else
        {
                Start-Service wuauserv -Verbose
                Invoke-Command {wuauclt.exe /detectnow} -Verbose
        }
    }
}
Function Invoke-DISMClenaup{
<#
.Author
   mikael.nystrom@truesec.se
.Date
   2015-10-29
.Version
   1.0
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    param(
        $Computer
    )
    Invoke-Command -ComputerName $Computer -ScriptBlock{
        Function Invoke-Exe{
            [CmdletBinding(SupportsShouldProcess=$true)]

            param(
            [parameter(mandatory=$true,position=0)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Executable,

            [parameter(mandatory=$false,position=1)]
            [string]
            $Arguments
            )

            if($Arguments -eq "")
            {
                Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
                $ReturnFromEXE = Start-Process -FilePath $Executable -NoNewWindow -Wait -Passthru
            }else{
                Write-Verbose "Running $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru"
                $ReturnFromEXE = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -Wait -Passthru
            }
            Write-Verbose "Returncode is $($ReturnFromEXE.ExitCode)"
            Return $ReturnFromEXE.ExitCode
        }
        Invoke-Exe -Executable DISM.exe -Arguments "/online /Cleanup-Image /StartComponentCleanup"
        }
}
Function Invoke-ClenaupFolder{
<#
.Author
   mattias.lehmus@truesec.se
.Date
   2016-02-16
.Version
   1.0
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    param(
        $Computer,
        $Folders
    )
    Invoke-Command -ComputerName $Computer -ScriptBlock{
        ForEach($Folder in $Using:Folders){
            Get-ChildItem -Path $Folder | foreach{Remove-Item -Path $_.FullName -Recurse -Verbose}
        }
    }
}

#Create Array of folders
[array]$Folders = $Folder.split(",")

#Check if C: should be cleaned
IF((Get-Volume -DriveLetter C).SizeRemaining -le (1024*1000*$FreeSizeMB)){
    #Clean Computer
    Invoke-CleanSoftwareDistFolder -ComputerName $ComputerName
    Invoke-DISMClenaup -Computer $ComputerName
    IF($Folders.Count -ne 0){
        Invoke-ClenaupFolder -Computer $ComputerName -Folders $Folders
    }
}