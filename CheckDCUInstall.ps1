Start-Transcript -Path "C:\windows\temp\DCUTransscript.txt" -Append

$DCULink = "https://dl.dell.com/FOLDER10408469M/1/Dell-Command-Update-Application_HYR95_WIN_5.0.0_A00.EXE"
$DCUVersion = "5.0.0"
$DCUCurrentInstall = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "*Dell Command*"}

function DCUUninstall{
    #Start-Process "msiexec.exe" -ArgumentList "/x", $DCUCurrentInstall.IdentifyingNumber, "/passive", "/quiet", "/norestart" -Wait -NoNewWindow
    msiexec.exe /x $DCUCurrentInstall.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
    Write-Host "Uninstall completed."

}
function DCUInstall {
    Write-Host "Downloading and installing Dell Command Updater. Please wait while the process is being completed."
    [System.IO.Directory]::CreateDirectory('C:\Temp')
    Invoke-WebRequest -Uri $DCULink -OutFile C:\Temp\DCU.exe -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    Start-Process C:\Temp\DCU.exe -Wait -ArgumentList @("/s") 
}
function UpdateDrivers {
    $delllogs = 'C:\dell\logs\'

    Write-Host "Begin Update Process"
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/configure","-silent","-autoSuspendBitLocker=enable","-userConsent=disable")
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/scan","-silent","-outputLog=C:\dell\logs\scan.log")
    Write-Host (Get-Content "$delllogs\scan.log"  | Select-String "Number of applicable updates for the current system configuration")
    Start-Process "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe" -WindowStyle Hidden -Wait -ArgumentList @("/ApplyUpdates","-silent","-reboot=disable","-outputLog=C:\dell\logs\ApplyUpdates.log")
    Write-Host (Get-Content "$delllogs\ApplyUpdates.log" | Select-String "Finished installing the updates.")
    Write-Host (Get-Content "$delllogs\ApplyUpdates.log" | Select-String "The program exited with return code")
}

if ($DCUCurrentInstall.Version -notlike $DCUVersion) {
        Write-Host "Outdated version detected. Uninstalling said version now..."
        DCUUninstall

        DCUInstall
    }
else {
        Write-Host "Version is Up-To-Date"
    }

UpdateDrivers

