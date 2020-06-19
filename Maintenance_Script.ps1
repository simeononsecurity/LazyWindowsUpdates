##Install and Import AD Modules For Powershell v6
Install-Module -Name WindowsCompatibility
Import-Module -Name WindowsCompatibility 
Import-WinModule -Name ActiveDirectory

#Install and Import Powershell AD Module
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory

$updatelist = Get-ADComputer -Filter * | Select -ExpandProperty Name

#####Install Latest Windows Updates#####
Invoke-Command -Computer $updatelist -ScriptBlock {Set-ExecutionPolicy Unrestricted; Import-Module PSWindowsUpdate; Get-WUInstall –AcceptAll -Verbose -IgnoreReboot} -asjob

###SCHEDULE A REBOOT AT 1800###
##Schedule Update for EoD
Invoke-Command -Computer $updatelist -ScriptBlock {$time = "20:00:00" ; $date = "02/4/2019" ; schtasks /create /tn “Scheduled Reboot” /tr “shutdown /r /t 0” /sc once /st $time /sd $date /ru “System”}
