##Install and Import AD Modules For Powershell v6
Import-Module -Name WindowsCompatibility 
Import-WinModule -Name ActiveDirectory

#Install and Import Powershell AD Module
Import-Module ActiveDirectory

$updatelist = (Get-ADComputer -Filter *).Name

#####Install Latest Windows Updates#####
ForEach ($Computer in $updatelist){
    Invoke-Command -Computer $Computer -ScriptBlock {
        Set-ExecutionPolicy Unrestricted; Import-Module PSWindowsUpdate; 
        Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false;
        Get-WUInstall -AcceptAll -Install –MicrosoftUpdate -Verbose -IgnoreReboot
        Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -IgnoreReboot
        #Get-WUInstall –MicrosoftUpdate –AcceptAll –AutoReboot
        #Install-WindowsUpdate -AcceptAll -MicrosoftUpdate -AutoReboot
        } 
    Invoke-Command -Computer $Computer -ScriptBlock {
        $time = "18:00:00" ; $date = "12/16/2020" ;
        schtasks /create /tn "ScheduledReboot20200715" /tr "Shutdown -r -t 0" /sc once /st $time /sd $date /ru "System"
        }

}

