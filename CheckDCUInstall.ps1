Start-Transcript -Path "C:\windows\temp\DCUTranscript.txt" -Append

$DCULink = "https://dl.dell.com/FOLDER11914075M/1/Dell-Command-Update-Application_6VFWW_WIN_5.4.0_A00.EXE"
$DCUVersion = "5.4.0"
$DCUCurrentInstall = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "*Dell Command*"}

function DCUUninstall {
    Write-Host "Outdated version detected. Uninstalling said version now..."   "`n"
    msiexec.exe /x $DCUCurrentInstall.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
    Write-Host "Uninstall completed."   "`n"
}

function DCUInstall {
    Write-Host "Downloading and installing Dell Command Updater. Please wait while the process is being completed."   "`n"
    [System.IO.Directory]::CreateDirectory('C:\Temp')
    Invoke-WebRequest -Uri $DCULink -OutFile "C:\Temp\DCU.exe" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    Start-Process "C:\Temp\DCU.exe" -Wait -ArgumentList "/s"
    Write-Host "Installation completed successfully."   "`n"
}

function UpdateDrivers {
    param (
        [string]$DCUCLI = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
    )
    Write-Host "Starting Dell Updates..."   "`n"
    $DCUCommands = @{
        Configure = @("/configure","-silent","-autoSuspendBitLocker=enable","-userConsent=disable")
        Scan = @("/scan","-silent")
        ApplyUpdates = @("/ApplyUpdates","-silent","-reboot=disable","-outputLog=C:\dell\logs\ApplyUpdates.log")
    }
    
    foreach ($command in $DCUCommands.GetEnumerator()) {
        Start-Process $DCUCLI -WindowStyle Hidden -Wait -ArgumentList $command.Value
    }
    
    Write-Host (Get-Content "C:\dell\logs\ApplyUpdates.log" | Select-String "The program exited with return code")   "`n"
    
}

if ($DCUCurrentInstall.Version -notlike $DCUVersion) {
    DCUUninstall -wait
    DCUInstall -wait
} 

else {

    Write-Host "No updates required. Current version is up to date."   "`n"
}

UpdateDrivers -Wait


Stop-Transcript
