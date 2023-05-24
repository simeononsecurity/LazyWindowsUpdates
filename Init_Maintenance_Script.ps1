# Install and Import AD Modules For PowerShell v6
Install-Module -Name WindowsCompatibility -Force
Import-Module -Name WindowsCompatibility -Force
Import-WinModule -Name ActiveDirectory -Force

# Install and Import PowerShell AD Module
if (-not (Get-WindowsFeature -Name RSAT-AD-PowerShell -ErrorAction SilentlyContinue)) {
    Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -IncludeManagementTools
}
Import-Module -Name ActiveDirectory -Force

# Run GPUPDATE on all online domain members
$gpupdateList = Get-ADComputer -Filter "Enabled -eq 'True'" | Select-Object -ExpandProperty Name

Write-Host "Running GPUPDATE on all online domain members..." -ForegroundColor Green
$jobResults = Invoke-Command -ComputerName $gpupdateList -ScriptBlock {
    Write-Host "Running GPUPDATE on $env:COMPUTERNAME" -ForegroundColor Yellow
    gpupdate /force /boot
} -AsJob

Write-Host "Waiting 30 seconds for policy update..." -ForegroundColor Green
Start-Sleep -Seconds 30
Get-Job $jobResults.Id

# Update Server 2012 to WMI 5.1
$server2012List = Get-ADComputer -Filter "OperatingSystem -like '*Windows Server 2012*'" | Select-Object -ExpandProperty Name

Write-Host "Updating Server 2012 machines to WMI 5.1..." -ForegroundColor Green
foreach ($computer in $server2012List) {
    if (Test-Connection -ComputerName $computer -Quiet) {
        Write-Host "Copying Win8.1AndW2K12R2-KB3191564-x64.msu to $computer" -ForegroundColor Yellow
        Copy-Item -Path "C:\temp\Win8.1AndW2K12R2-KB3191564-x64.msu" -Destination "\\$computer\C$\temp" -Force
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Installing WMI 5.1 on $env:COMPUTERNAME" -ForegroundColor Yellow
            wusa.exe "C:\temp\Win8.1AndW2K12R2-KB3191564-x64.msu" /quiet /norestart
        } -AsJob
    } else {
        Write-Host "$computer is not online" -ForegroundColor Red
    }
}

Write-Host "Waiting 30 seconds to install PSWINDOWSUPDATE Module..." -ForegroundColor Green
Start-Sleep -Seconds 30

# Install PSWindowsUpdate module
Write-Host "Installing PSWindowsUpdate module on all machines in the domain..." -ForegroundColor Green
$domainMachines = Get-ADComputer -Filter "Enabled -eq 'True'" | Select-Object -ExpandProperty Name

foreach ($computer in $domainMachines) {
    if (Test-Connection -ComputerName $computer -Quiet) {
        Write-Host "Copying PSWindowsUpdate to $computer" -ForegroundColor Yellow
        Copy-Item -Path "C:\temp\PSWindowsUpdate*" -Destination "\\$computer\c$\temp" -Recurse -Force
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Unzipping PSWindowsUpdate on $env:COMPUTERNAME" -ForegroundColor Yellow
            Expand-Archive -Force -LiteralPath 'C:\temp\PSWindowsUpdate.zip' -DestinationPath "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
        }
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Installing latest Windows updates on $env:COMPUTERNAME" -ForegroundColor Yellow
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force
            Import-Module -Name PSWindowsUpdate -Force
            Get-WUInstall –AcceptAll -Verbose -IgnoreReboot
        }
        Invoke-Command -ComputerName $computer -ScriptBlock {
            Write-Host "Scheduling update for EoD on $env:COMPUTERNAME" -ForegroundColor Yellow
            $time = "20:00:00"
            $date = Get-Date -Year 2019 -Month 2 -Day 4
            schtasks /create /tn "Scheduled Reboot" /tr "shutdown /r /t 0" /sc once /st $time /sd $date /ru "System"
        }
    } else {
        Write-Host "$computer is not online" -ForegroundColor Red
    }
}
