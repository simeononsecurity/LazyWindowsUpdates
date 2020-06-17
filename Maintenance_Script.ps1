##Install and Import AD Modules For Powershell v6
Install-Module -Name WindowsCompatibility
Import-Module -Name WindowsCompatibility 
Import-WinModule -Name ActiveDirectory

#Install and Import Powershell AD Module
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory

####RUN GPUPDATE ON ALL ONLINE DOMAIN MEMBERS#####
#DEFINE ALL SYSTEMS IN DOMAIN
$gpupdatelist = Get-ADComputer -Filter * | Select -ExpandProperty Name
#RUN GPUPDATE AND PROVIDE FEEDBACK
Invoke-Command -Computer $gpupdatelist -ScriptBlock {gpupdate /force ; gpupdate /force ; gpupdate /force /boot} -AsJob
Echo "Waiting 30 Seconds for Policy Update..."
Echo "Expect the script to fail, but don't worry it worked"

#Waiting
Start-Sleep 30
Get-Job

#####Install Latest Windows Updates#####
Invoke-Command -Computer $updatelist -ScriptBlock {Import-Module PSWindowsUpdate; Get-WUInstall –AcceptAll -Verbose -IgnoreReboot}

###SCHEDULE A REBOOT AT 1800###
##Schedule Update for EoD
Invoke-Command -Computer $updatelist -ScriptBlock {$time = "20:00:00" ; $date = "02/4/2019" ; schtasks /create /tn “Scheduled Reboot” /tr “shutdown /r /t 0” /sc once /st $time /sd $date /ru “System”}
