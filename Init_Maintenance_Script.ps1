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

#####PART 1 UPDATE SERVER 2012 to WMI 5.1#####

#DEFINE ALL SERVER 2012 MACHINES IN DOMAIN
$2012list = Get-ADComputer -Filter { OperatingSystem -Like '*Windows Server 2012*' } | Select -ExpandProperty Name

#SOURCE FILE FOR SERVER 2012 WMI 5.1 UPGRADE
$source = "c:\temp\Win8.1AndW2K12R2-KB3191564-x64.msu"

#DESTINATION FOR THE FILE TO BE COPIED TO ON REMOTE MACHINE RELETIVE TO "C:\"
$dest = "temp\"

#Copy Win8.1AndW2K12R2-KB3191564-x64.msu to all Server 2012 machines in domain
foreach ($computer in $2012list) {
    if (test-Connection -Cn $computer -quiet) {
        Copy-Item $source -Destination \\$computer\"c$"\$dest -Recurse
    } else {
        "$computer is not online"
    }

}

####INSTALL WMI 5.1

Invoke-Command -Computer $2012list -ScriptBlock {wusa.exe "C:\temp\Win8.1AndW2K12R2-KB3191564-x64.msu" /quiet /norestart}

##Waiting
Start-Sleep 30
Echo "Waiting to install PSWINDOWSUPDATE Module"

#####PART 2 INSTALL PSWINDOWSUPDATEMODULES#####

#DEFINE ALL MACHINES IN DOMAIN
$updatelist = Get-ADComputer -Filter * | Select -ExpandProperty Name

#SOURCE FILE FOR PSWINDOWSUPDATE MODULE
$psupdatesource = "c:\temp\PSWindowsUpdate.zip"

#DESTINATION FOR THE FILE TO BE COPIED TO ON REMOTE MACHINE RELETIVE TO "C:\"
$psupdatedest = "temp\"

#Copy Win8.1AndW2K12R2-KB3191564-x64.msu to all Server 2012 machines in domain
foreach ($computer in $updatelist) {
    if (test-Connection -Cn $computer -quiet) {
        Copy-Item $psupdatesource -Destination \\$computer\"c$"\$psupdatedest -Recurse
    } else {
        "$computer is not online"
    }

}

####Unzip PSWindowsUpdate
Invoke-Command -Computer $updatelist -ScriptBlock {Expand-Archive - Force -LiteralPath 'c:\temp\PSWindowsUpdate.zip' -DestinationPath "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"}

#####Install Latest Windows Updates#####
Invoke-Command -Computer $updatelist -ScriptBlock {Import-Module PSWindowsUpdate; Get-WUInstall –AcceptAll -Verbose -IgnoreReboot}

###SCHEDULE A REBOOT AT 1800###
##Schedule Update for EoD
Invoke-Command -Computer $updatelist -ScriptBlock {$time = "20:00:00" ; $date = "02/4/2019" ; schtasks /create /tn “Scheduled Reboot” /tr “shutdown /r /t 0” /sc once /st $time /sd $date /ru “System”}
