Start-Transcript -Path "C:\windows\temp\DCUTransscript.txt" -Append

$DCULink = "https://dl.dell.com/FOLDER10408469M/1/Dell-Command-Update-Application_HYR95_WIN_5.0.0_A00.EXE"
$DCUVersion = "5.0.0"
$DCUCurrentInstall = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -like "*Dell Command*"}

function DCUUninstall{
    Write-Host "Outdated version detected. Uninstalling said version now..."
    msiexec.exe /x $DCUCurrentInstall.IdentifyingNumber /passive /quiet /norestart | Write-Verbose
    Write-Host "Uninstall completed."

}
function DCUInstall {
    Write-Host "Downloading and installing Dell Command Updater. Please wait while the process is being completed."
    [System.IO.Directory]::CreateDirectory('C:\Temp')
    Invoke-WebRequest -Uri $DCULink -OutFile C:\Temp\DCU.exe -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer)
    Start-Process C:\Temp\DCU.exe -Wait -ArgumentList @("/s") 
    Write-Host "Installation completed successfully."
}

function UpdateDrivers {
    param (
        [string]$DCUCLI = "C:\Program Files (X86)\Dell\CommandUpdate\dcu-cli.exe",
    )

    Writ-Host "Starting Dell Updates..."
    # Define the commands and their corresponding arguments using the variables
    $DCUCommands = @{
        Configure = @("/configure","-silent","-autoSuspendBitLocker=enable","-userConsent=disable")
        Scan = @("/scan","-silent","-outputLog="C:\dell\logs\scan.log")
        ApplyUpdates = @("/ApplyUpdates","-silent","-reboot=disable","-outputLog="C:\dell\logs\ApplyUpdates.log")
    }

    foreach ($command in $DCUCommands.GetEnumerator()) {
        # Replace placeholders with actual paths
        Start-Process $DCUCLI -WindowStyle Hidden -Wait -ArgumentList $arguments

        # Additional processing specific to the scan log
        if ($command.Key -eq 'Scan') {
            Write-Host (Get-Content ""C:\dell\logs\scan.log" | Select-String "Number of applicable updates for the current system configuration")
        }
    }
}

if ($DCUCurrentInstall.Version -notlike $DCUVersion) {
        DCUUninstall
        DCUInstall
    }
else {
        Write-Host "Version is Up-To-Date"
    }

UpdateDrivers
