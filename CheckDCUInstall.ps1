Start-Transcript -Path "C:\windows\temp\DCUTransscript.txt" -Append

$DCUInstallCheck = $null
$DSAInstallCheck = $null
$DCUCurrentVersion = "5.0.0"
$DCUCurrentVersionURI = "https://dl.dell.com/FOLDER10408469M/1/Dell-Command-Update-Application_HYR95_WIN_5.0.0_A00.EXE"


$delllogs = 'C:\dell\logs\'
$scanlog = "$($delllogs)\scan.log"
$updatelog = "$($delllogs)\ApplyUpdates.log"


function CheckDCUInstall {
    #$DCUInstallCheck = ((gp HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Dell Command | Update").Length -gt 0.
    $Global:DCUInstallCheck = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Command | Update*"}
}

function CheckDSAInstall {
    #$DSAInstallCheck = ((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Match "Dell SupportAssist").Length -gt 0
    $Global:DSAInstallCheck = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -eq "Dell SupportAssist"} 
}

function UninstallDSA {
    $program = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -eq "Dell SupportAssist"} 
    #$program.IdentifyingNumber #IdentifyingNumber is the guid
    msiexec.exe /x $program.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
} 
function UninstallDSU {
    $program = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Command | Update*"} 
    #$program.IdentifyingNumber #IdentifyingNumber is the guid
    msiexec.exe /x $program.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
}
function UninstallDellUpdate {
        $program = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Update"} 
        #$program.IdentifyingNumber #IdentifyingNumber is the guid
        msiexec.exe /x $program.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
} 
function UninstallDellClientUpdate {
        $program = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -eq "Dell Client System Update"} 
        #$program.IdentifyingNumber #IdentifyingNumber is the guid
        msiexec.exe /x $program.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
} 
function InstallUpdateDCU {
    [System.IO.Directory]::CreateDirectory('C:\Temp')
    Invoke-WebRequest -Uri $DCUCurrentVersionURI -OutFile C:\Temp\DCU.exe -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    Start-Process C:\Temp\DCU.exe -Wait -ArgumentList @("/s") 
}
function UpdateDrivers {
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/configure","-silent","-autoSuspendBitLocker=enable","-userConsent=disable")
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/scan","-silent","-outputLog=C:\dell\logs\scan.log")
    get-content $scanlog | Select-String "Number of applicable updates for the current system configuration"| forEach-object { Write-Host $_ }
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/ApplyUpdates","-silent","-reboot=disable","-outputLog=C:\dell\logs\ApplyUpdates.log")
    get-content $updatelog | select-string "Finished installing the updates."  | forEach-object { Write-Host $_ } 
    get-content $updatelog | select-string "The program exited with return code"  | forEach-object { Write-Host $_ }
}

#CheckDCUInstall
#CheckDSAInstall
$DSAInstallCheck = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -eq "Dell SupportAssist"} 
$DCUInstallCheck = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Command | Update*"}
$UninstallDellUpdate = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Update*"}
$UninstallDellClientUpdate = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Update*"}
$DetectorCheck = $DSAInstallCheck,$DCUInstallCheck,$UninstallDellClientUpdate,$UninstallDellClientUpdate

If ($null -ne $DetectorCheck )
{
 foreach ($i in $DetectorCheck)
 {
    if ($null -ne $i -and $i -like "Dell Command | Update*")
    {
        Write-Host "$($i.name) Version $($i.version) found. Now Uninstallng"
        #Write-Host "**********************************"
        #Write-Host "$($i.name) Version $($i.version)"
        #Write-Host "**********************************"
        msiexec.exe /x $($i.IdentifyingNumber) /passive /quiet /norestart | Write-Verbose
    }
    elseif ($null -ne $i -contains "Dell Command | Update*")
    {
    Write-Host "DCU Installed. Checking Version..."
    if($DCUInstallCheck.version -ne $DCUCurrentVersion)
        {
            Write-Host "DCU Installed. Version $DCUInstallCheck.version found. Uninstalling to Install newer version"
            msiexec.exe /x $($i.IdentifyingNumber) /passive /quiet /norestart | Write-Verbose
            #Write-Host "**********************************"
            #Write-Host "$($i.name) Version $($i.version)"
            #Write-Host "**********************************"
        }
    else
        {
            Write-Host "Version up to date."
            #Write-Host "**********************************"
            #Write-Host "$($i.name) Version $($i.version)"
            #Write-Host "**********************************"
        } 
    }
 }
}


Write-Host "
|=========================================|

  Checking Version of Dell Command Update

|=========================================|

"


$DCUInstallCheck = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "Dell Command | Update*"}
if($null -eq $DCUInstallCheck)
{
    Write-Host "No Conflicting Dell Update software found. Installing Dell Command Update"
    InstallUpdateDCU
    UpdateDrivers

    Write-Host "Rerun Updates to Ensure that they are up to date."
    UpdateDrivers
}
else 
{
    Write-Host "Latest version DCU Installed. Starting Update Process..."
    UpdateDrivers

    Write-Host "Rerun Updates to Ensure that they are up to date."
    UpdateDrivers

}


#if ($null -ne $DSAInstallCheck) {
#    Write-Host "SupportAssit Found. Now Uninstalling..."
#    UninstallDSA
#    Write-Host "Now Installing DCU"
#    InstallUpdateDCU
#    Write-Host "DCU Installed. Starting Update Process..."
#    UpdateDrivers
#}
#elseif ($null -ne $UninstallDellUpdate) {
#    Write-Host "Dell Update Found. Now Uninstalling..."
#    UninstallDellUpdate
#    Write-Host "Now Installing DCU"
#    InstallUpdateDCU
#    Write-Host "DCU Installed. Starting Update Process..."
#    UpdateDrivers
#}
#elseif ($null -ne $UninstallDellClientUpdate) {
#    Write-Host "Dell Client Update Found. Now Uninstalling..."
#    UninstallDellClientUpdate
#    Write-Host "Now Installing DCU"
#    InstallUpdateDCU
#    Write-Host "DCU Installed. Starting Update Process..."
#    UpdateDrivers
#}
#elseif ($null -ne $DCUInstallCheck) {
#    Write-Host "DCU Installed. Checking Version..."
#    if($DCUInstallCheck.version -ne $DCUCurrentVersion)
#        {
#            Write-Host "DCU Installed. Version $DCUInstallCheck.version found. Uninstalling to Install newer version"
#            UninstallDSU
#            Write-Host "Now Installing Current Version"
#            InstallUpdateDCU
#            Write-Host "Installing Updates..."
#            UpdateDrivers
#        }
#    else
#        {
#            Write-Host "Version up to date. Installing Updates..."
#            UpdateDrivers
#        } 
# }


Stop-Transcript