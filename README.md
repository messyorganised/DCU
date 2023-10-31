# DCU

A Powershell script that handles the process of Dell Command Update from start to finish. The script does the following:

- Scan for installed version of dell command update
- Uninstall old and install current version of Dell Command Updater
- Scan for latest Dell Command Updates
- Install all Dell Command Updates

This powershell script requires admin rights. Manual modification of the code is needed for any new versions of Dell Command Updater

Plans:
1. Configure a process where it automatically assess the latest version number on Dell's website
2. Search and grab the latest version download link
