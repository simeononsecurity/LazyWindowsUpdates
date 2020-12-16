##Install and Import AD Modules For Powershell v6
Import-Module -Name WindowsCompatibility 
Import-WinModule -Name ActiveDirectory

#Install and Import Powershell AD Module
Import-Module ActiveDirectory

$updatelist = Get-ADComputer -Filter * | Select -ExpandProperty Name

#####Install Latest Windows Updates#####
Invoke-Command -Computer $updatelist -ScriptBlock {Set-ExecutionPolicy Unrestricted; Import-Module PSWindowsUpdate; 
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d;
Get-WUInstall -AcceptAll -Install –MicrosoftUpdate -Verbose -IgnoreReboot} 

##Schedule Update for EoD
Invoke-Command -Computer $updatelist -ScriptBlock {$time = "20:00:00" ; $date = "07/15/2020" ; schtasks /create /tn "ScheduledReboot20200715" /tr "Shutdown -r -t 0" /sc once /st $time /sd $date /ru "System"}

