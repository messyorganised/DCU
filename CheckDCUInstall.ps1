Start-Transcript -Path "C:\windows\temp\DCUTranscript.txt" -Append

$DCULink = "https://dl.dell.com/FOLDER10791703M/1/Dell-Command-Update-Application_44TH5_WIN_5.1.0_A00.EXE?uid=5ad66d7a-e2bf-4eff-cfb8-bd59bb7d60f5&fn=Dell-Command-Update-Application_44TH5_WIN_5.1.0_A00.EXE"
$DCUVersion = "5.1.0"
$DCUCurrentInstall = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "*Dell Command*"}

function DCUUninstall {
    Write-Host "Outdated version detected. Uninstalling said version now..."  -Seperator "`n"
    msiexec.exe /x $DCUCurrentInstall.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
    Write-Host "Uninstall completed."  -Seperator "`n"
}

function DCUInstall {
    Write-Host "Downloading and installing Dell Command Updater. Please wait while the process is being completed."  -Seperator "`n"
    [System.IO.Directory]::CreateDirectory('C:\Temp')
    Invoke-WebRequest -Uri $DCULink -OutFile "C:\Temp\DCU.exe" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    Start-Process "C:\Temp\DCU.exe" -Wait -ArgumentList "/s"
    Write-Host "Installation completed successfully."  -Seperator "`n"
}

function UpdateDrivers {
    param (
        [string]$DCUCLI = "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe"
    )
    Write-Host "Starting Dell Updates..."  -Seperator "`n"
    $DCUCommands = @{
        Configure = @("/configure","-silent","-autoSuspendBitLocker=enable","-userConsent=disable")
        Scan = @("/scan","-silent","-outputLog=C:\dell\logs\scan.log")
        ApplyUpdates = @("/ApplyUpdates","-silent","-reboot=disable","-outputLog=C:\dell\logs\ApplyUpdates.log")
    }
    
    foreach ($command in $DCUCommands.GetEnumerator()) {
        Start-Process $DCUCLI -WindowStyle Hidden -Wait -ArgumentList $command.Value

        if ($command.Key -eq 'Scan') {
            $scanResults = Get-Content "C:\dell\logs\scan.log" | Select-String "Number of applicable updates for the current system configuration"
            Write-Host $scanResults
        }
    }
    
        Write-Host (Get-Content "C:\dell\logs\ApplyUpdates.log" | Select-String "The program exited with return code")  -Seperator "`n"
}

if ($DCUCurrentInstall.Version -notlike $DCUVersion) {
    DCUUninstall
    DCUInstall
} 

else {

    Write-Host "No updates required. Current version is up to date."  -Seperator "`n"
}

UpdateDrivers

Stop-Transcript
