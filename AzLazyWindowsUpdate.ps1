Install-Module Az -Force
Login-AzAccount
Get-AzVM | Invoke-AzVMRunCommand -ScriptString {Install-Module PSWindowsUpdate -Force}
Get-AzVM | Invoke-AzVMRunCommand -ScriptString (Set-ExecutionPolicy Unrestricted; Import-Module PSWindowsUpdate; Get-WUInstall –AcceptAll -Verbose -IgnoreReboot}
Sleep 30
Get-AzVM | Invoke-AzVMRunCommand -ScriptString {$time = "20:00:00" ; $date = "02/4/2019" ; schtasks /create /tn “Scheduled Reboot” /tr “shutdown /r /t 0” /sc once /st $time /sd $date /ru “System”]
