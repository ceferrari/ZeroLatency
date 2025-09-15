# Request administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Writes all output to a .log file in the same directory as the script
Start-Transcript -Path (Join-Path -Path $PSScriptRoot -ChildPath "ZeroLatencyReset.log") -Append

#########################################################
# BEGIN - Start modifying
#########################################################

# Add folders to not be excluded from Windows Defender Scan
$ExcludedFolders = @(
    # Copy and paste from your ZeroLatency.ps1
)

# Add processes to not be excluded from Windows Defender Scan and Exploit Protection
$ExcludedProcesses = @(
    # Copy and paste from your ZeroLatency.ps1
)

# Add services to be set to manual
$DisabledServices = @(
    # Copy and paste from your ZeroLatency.ps1
)

#########################################################
# END - Stop modifying
#########################################################

# Suppress progress bars
$ProgressPreference = "SilentlyContinue"

# Functions
function Invoke-Custom {
    param([string]$Command)
    Write-Host "`n`e[0;36m==> `e[1;36m$Command`e[0m"
    Invoke-Expression $Command
}

function Write-Custom {
    param([string]$Text)
    Write-Host "`n`e[0;34m==> `e[1;34m$Text`e[0m"
}

function Remove-Task {
    param ([string]$Name)
    Unregister-ScheduledTask -TaskName $Name -Confirm:$False -ErrorAction SilentlyContinue
}

# Windows Defender settings
@{
    "PerformanceModeStatus" = "Enabled"             # Virus & threat protection > Virus & threat protection settings > Dev Drive protection
    "MAPSReporting" = "Enabled"                     # Virus & threat protection > Virus & threat protection settings > Cloud-delivered protection
    "SubmitSamplesConsent" = "AlwaysPrompt"         # Virus & threat protection > Virus & threat protection settings > Automatic sample submission
    "EnableControlledFolderAccess" = "Enabled"      # Virus & threat protection > Ransomware protection > Controlled folder access
    "PUAProtection" = "Enabled"                     # App & browser control > Reputation-based protection > Potentially unwanted app blocking
}.GetEnumerator() | ForEach-Object {
    Invoke-Custom "Set-MpPreference -$($_.Key) $($_.Value)"
}

# Windows Defender Scan folders to not exclude
$ExcludedFolders | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Remove-MpPreference -ExclusionPath $_"
}

# Windows Defender Scan and Exploit Protection processes to not exclude
$ExcludedProcesses | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Remove-MpPreference -ExclusionProcess $_"
    Invoke-Custom "Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$_' -Recurse"
}

# Services to set to manual
$DisabledServices | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Set-Service $_ -StartupType Manual"
}

# PowerShell
@("User", "Machine") | ForEach-Object {
    Invoke-Custom "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', `$Null, '$_')"
}

# Timers and Data Execution Prevention
@(
    "bcdedit /deletevalue useplatformclock"
    "bcdedit /deletevalue useplatformtick"
    "bcdedit /deletevalue disabledynamictick"
    "bcdedit /set ``{current``} nx OptIn"
    "Get-PnpDevice -FriendlyName 'High Precision Event Timer' | Enable-PnpDevice -Confirm:`$False"
    "Get-PnpDevice -FriendlyName 'Remote Desktop Device Redirector Bus' | Enable-PnpDevice -Confirm:`$False"
) | ForEach-Object {
    Invoke-Custom $_
}

# Pagefile
@(
    "Set-CimInstance -CimInstance (Get-CimInstance -ClassName Win32_ComputerSystem) -Arguments @{ AutomaticManagedPagefile = `$True }"
) | ForEach-Object {
    Invoke-Custom $_
}

# Windows Memory Management Agent
@(
    "Enable-MMAgent -ApplicationLaunchPrefetching"
    "Enable-MMAgent -ApplicationPreLaunch"
    "Enable-MMAgent -MemoryCompression"
    "Enable-MMAgent -OperationAPI"
    "Disable-MMAgent -PageCombining"
    "Set-MMAgent -MaxOperationAPIFiles 512"
) | ForEach-Object {
    Invoke-Custom $_
}

# Global network settings
@(
    "Set-NetOffloadGlobalSetting -Chimney Disabled"
    "Set-NetOffloadGlobalSetting -NetworkDirect Enabled"
    "Set-NetOffloadGlobalSetting -NetworkDirectAcrossIPSubnets Blocked"
    "Set-NetOffloadGlobalSetting -PacketCoalescingFilter Enabled"
    "Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled"
    "Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled"
    "Set-NetOffloadGlobalSetting -TaskOffload Enabled"
) | ForEach-Object {
    Invoke-Custom $_
}

# Network settings reset
@(
    "netsh int ip set dynamicport tcp start=49152 num=16384"
    "netsh int ip set dynamicport udp start=49152 num=16384"
    "netsh int tcp set supplemental template=none"
    "netsh int teredo set state default"
    "netsh int ip reset"
    "netsh int ipv4 reset"
    "netsh int ipv6 reset"
    "netsh int tcp reset"
    "netsh int udp reset"
    "netsh winsock reset"
    "netsh winhttp reset proxy"
    "ipconfig /flushdns"
    "ipconfig /release"
    "ipconfig /renew"
) | ForEach-Object {
    Invoke-Custom $_
}; Write-Host ""

# Adapter settings optimization
Get-NetAdapter -Physical | ForEach-Object {
    $Adapter = $_
    Invoke-Custom "Reset-NetAdapterAdvancedProperty -NoRestart -Name '$($Adapter.Name)' -DisplayName '*'"
    Invoke-Custom "Get-NetAdapterBinding -Name '$($Adapter.Name)' | Where-Object { `$_.ComponentID -notin @('ms_implat') } | Enable-NetAdapterBinding"
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object {
        if ("Tcpip_$($Adapter.InterfaceGuid)" -ne $_.PSChildName) { return }
        Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Type "DWord" -Value 0
        Write-Custom "Successfully reset NetBIOS on $($Adapter.Name) $($Adapter.InterfaceGuid)"
    }
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
        if ($Adapter.InterfaceGuid -ne $_.PSChildName) { return }
        Remove-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        Write-Custom "Successfully reset Nagle's on $($Adapter.Name) $($Adapter.InterfaceGuid)"
        Remove-ItemProperty -Path $_.PSPath -Name "TCPInitialRtt" -ErrorAction SilentlyContinue
        Write-Custom "Successfully reset InitialRTO on $($Adapter.Name) $($Adapter.InterfaceGuid)"
    }
    @("ipv4", "ipv6") | ForEach-Object {
        $X = "netsh int $_ set subinterface $($Adapter.ifIndex) mtu=1500"; Invoke-Custom "$X store=persistent"; Invoke-Custom $X
        $Y = "netsh int $_ set dns $($Adapter.ifIndex) dhcp"; Invoke-Custom $Y
    }
    Write-Custom "Successfully reset MTU and DNS on $($Adapter.Name) $($Adapter.InterfaceGuid)"
}

# Power Plan download, import and activation
$GuidRegex = "[0-9a-fA-F-]{36}"
powercfg /setactive ((powercfg /list | Where-Object { $_ -notmatch "ZeroLatency" } | Select-Object -Last 1) -match $GuidRegex | ForEach-Object { $matches[0] })
powercfg /list | Select-String "ZeroLatency" | ForEach-Object { if ($_ -match $GuidRegex) { powercfg /delete $matches[0] } }
powercfg /hibernate on
Write-Custom "Successfully removed ZeroLatency Power Plan"

# Power-Saving and Wake on Magic Packet
$WompInstances = Get-CimInstance -ClassName MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
$WakeInstances = Get-CimInstance -ClassName MSPower_DeviceWakeEnable -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
$PwsvInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
Get-CimInstance Win32_PnPEntity | ForEach-Object {
    $Pattern = "(?i)$([regex]::Escape($_.PNPDeviceID))"
    $WompInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $WompInstances[$_][0] -Property @{ EnableWakeOnMagicPacketOnly = $True }
    }
    $WakeInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $WakeInstances[$_][0] -Property @{ Enable = $True }
    }
    $PwsvInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $PwsvInstances[$_][0] -Property @{ Enable = $True }
    }
}
Write-Custom "Successfully reset Power-Saving and Wake on Magic Packet for applicable devices"

# Selective Suspend
Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*\Device Parameters" | ForEach-Object {
    $Path = $_.PSPath
    $Props = Get-ItemProperty -Path $Path
    @(
        "AllowIdleIrpInD3"
        "DeviceSelectiveSuspended"
        "EnhancedPowerManagementEnabled"
        "SelectiveSuspendEnabled"
        "SelectiveSuspendOn"
    ) | ForEach-Object {
        if ($Props.PSObject.Properties.Name -notcontains $_) { return }
        Remove-ItemProperty -Path $Path -Name $_ -ErrorAction SilentlyContinue
    }
}
Write-Custom "Successfully reset Selective Suspend for applicable devices"

# Background Access for UWP applications
Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" | Where-Object { $_.PSChildName -notmatch "NVIDIA|Realtek|OneDrive" } | ForEach-Object {
    $Path = $_.PSPath
    @(
        "Disabled"
        "DisabledBySystem"
        "DisabledByUser"
        "IgnoreBatterySaver"
        "NCBEnabled"
        "SleepDisabled"
        "SleepIgnoreBatterySaver"
    ) | ForEach-Object {
        Remove-ItemProperty -Path $Path -Name $_ -ErrorAction SilentlyContinue
    }
}
Write-Custom "Successfully reset Background Access for UWP applications"

# TODO: Reset Registry

# Network settings task
Remove-Task -Name "ZeroLatency (netsh)" -Command $NetshCommands
Write-Custom "Successfully removed the task with netsh commands"

# Network adapters restart
Get-NetAdapter -Physical | ForEach-Object { Restart-NetAdapter -Name "$($_.Name)" }
Write-Custom "Successfully restarted all physical network adapters"

# Final message
Write-Host "`n`e[1;35mScript complete! Restart recommended to apply all changes`n`nPress any key to exit...`e[0m"
$Null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# End logging
Stop-Transcript
