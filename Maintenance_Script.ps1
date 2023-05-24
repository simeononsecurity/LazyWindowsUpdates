# Install and Import AD Modules For PowerShell v6
Import-Module -Name WindowsCompatibility -Force
Import-WinModule -Name ActiveDirectory -Force

# Install and Import PowerShell AD Module
Import-Module ActiveDirectory -Force

# Get the list of computers to update
$updatelist = Get-ADComputer -Filter "Enabled -eq 'True'" | Select-Object -ExpandProperty Name

# Install the latest Windows updates and schedule a reboot
foreach ($computer in $updatelist) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
        Import-Module -Name PSWindowsUpdate -Force
        Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false
        Write-Host "Installing latest Windows updates on $env:COMPUTERNAME" -ForegroundColor Green
        Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose
        Write-Host "Scheduling a reboot on $env:COMPUTERNAME" -ForegroundColor Green
        $time = "18:00:00"
        $date = Get-Date -Year 2020 -Month 12 -Day 16
        schtasks /create /tn "ScheduledReboot20200715" /tr "Shutdown -r -t 0" /sc once /st $time /sd $date /ru "System"
    }
}
