# Request administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Writes all output to a .log file in the same directory as the script
Start-Transcript -Path (Join-Path -Path $PSScriptRoot -ChildPath "ZeroLatencyReset.log") -Append

#########################################################
# BEGIN - Start modifying
#########################################################

#########################################################
# STEP 1 - Add or remove folders to be excluded from Windows Defender Scan
$ExcludedFolders = @(
    "C:\Games"
    "C:\ProgramData"
    "$env:UserProfile\AppData"
    "$env:SystemRoot\System32\config\systemprofile\AppData"
    "$env:SystemRoot\Temp"
)
#########################################################

#########################################################
# STEP 2 - Add or remove processes to be excluded from Windows Defender Scan and Control Flow Guard
$ExcludedProcesses = @(
    # System
    "audiodg.exe"
    "csrss.exe"
    "ctfmon.exe"
    "dwm.exe"
    "lsass.exe"
    "smss.exe"
    # Drivers
    "nvcontainer.exe"
    "nvdisplay.container.exe"
    "razerappengine.exe"
    "rzenginemon.exe"
    # Tools
    "bitsumsessionagent.exe"
    "latmon.exe"
    "mousetester.exe"
    "msiafterburner.exe"
    "presentmondataprovider.exe"
    "processgovernor.exe"
    "processlasso.exe"
    "rtss.exe"
    "rtsshooksloader64.exe"
    # Steam
    "cs2.exe"
    "pathofexile_x64steam.exe"
    "pathofexilesteam.exe"
    "steam.exe"
    "steamservice.exe"
    "steamwebhelper.exe"
    # Riot
    "riotclientservices.exe"
    "valorant-win64-shipping.exe"
    "vgc.exe"
)
#########################################################

#########################################################
# STEP 3 - Add or remove Windows services to set to manual (if you already chose to set them to manual in the default script, skip this step)
$ManualServices = @(
    "ADPSvc"                                            # ADPSvc
    "ALG"                                               # Application Layer Gateway Service
    "ApxSvc"                                            # Windows Virtual Audio Device Proxy Service
    "autotimesvc"                                       # Cellular Time
    "AxInstSV"                                          # ActiveX Installer (AxInstSV)
    "BDESVC"                                            # BitLocker Drive Encryption Service
    "BTAGService"                                       # Bluetooth Audio Gateway Service
    "BthAvctpSvc"                                       # AVCTP service
    "bthserv"                                           # Bluetooth Support Service
    "CertPropSvc"                                       # Certificate Propagation
    "dcsvc"                                             # Declared Configuration(DC) service
    "defragsvc"                                         # Optimize drives
    "DeviceAssociationService"                          # Device Association Service
    "diagsvc"                                           # Diagnostic Execution Service
    "DiagTrack"                                         # Connected User Experiences and Telemetry
    "DisplayEnhancementService"                         # Display Enhancement Service
    "DmEnrollmentSvc"                                   # Device Management Enrollment Service
    "dmwappushservice"                                  # Device Management Wireless Application Protocol (WAP) Push message Routing Service
    "dot3svc"                                           # Wired AutoConfig
    "DPS"                                               # Diagnostic Policy Service
    "DsSvc"                                             # Data Sharing Service
    "DusmSvc"                                           # Data Usage
    "EapHost"                                           # Extensible Authentication Protocol
    "edgeupdate"                                        # Microsoft Edge Update Service (edgeupdate)
    "edgeupdatem"                                       # Microsoft Edge Update Service (edgeupdatem)
    "EFS"                                               # Encrypting File System (EFS)
    "fdPHost"                                           # Function Discovery Provider Host
    "FDResPub"                                          # Function Discovery Resource Publication
    "fhsvc"                                             # File History Service
    "GameInputSvc"                                      # GameInput Service
    "GraphicsPerfSvc"                                   # GraphicsPerfSvc
    "hidserv"                                           # Human Interface Device Service
    "icssvc"                                            # Windows Mobile Hotspot Service
    "InventorySvc"                                      # Inventory and Compatibility Appraisal service
    "iphlpsvc"                                          # IP Helper
    "IpxlatCfgSvc"                                      # IP Translation Configuration Service
    "lltdsvc"                                           # Link-Layer Topology Discovery Mapper
    "lmhosts"                                           # TCP/IP NetBIOS Helper
    "LxpSvc"                                            # Language Experience Service
    "MapsBroker"                                        # Downloaded Maps Manager
    "McmSvc"                                            # This service provides profile management for mobile connectivity modules
    "McpManagementService"                              # McpManagementService
    "MicrosoftEdgeElevationService"                     # Microsoft Edge Elevation Service (MicrosoftEdgeElevationService)
    "MSDTC"                                             # Distributed Transaction Coordinator
    "MSiSCSI"                                           # Microsoft iSCSI Initiator Service
    "NaturalAuthentication"                             # Natural Authentication
    "NcaSvc"                                            # Network Connectivity Assistant
    "NcdAutoSetup"                                      # Network Connected Devices Auto-Setup
    "Netlogon"                                          # Netlogon
    "NetTcpPortSharing"                                 # Net.Tcp Port Sharing Service
    "PcaSvc"                                            # Program Compatibility Assistant Service
    "perceptionsimulation"                              # Windows Perception Simulation Service
    "PhoneSvc"                                          # Phone Service
    "pla"                                               # Performance Logs & Alerts
    "PrintDeviceConfigurationService"                   # Print Device Configuration Service
    "PrintNotify"                                       # Printer Extensions and Notifications
    "PrintScanBrokerService"                            # PrintScanBrokerService
    "QWAVE"                                             # Quality Windows Audio Video Experience
    "RasAuto"                                           # Remote Access Auto Connection Manager
    "RasMan"                                            # Remote Access Connection Manager
    "refsdedupsvc"                                      # ReFS Dedup Service
    "RemoteAccess"                                      # Routing and Remote Access
    "RemoteRegistry"                                    # Remote Registry
    "RetailDemo"                                        # Retail Demo Service
    "RmSvc"                                             # Radio Management Service
    "RpcLocator"                                        # Remote Procedure Call (RPC) Locator
    "SCardSvr"                                          # Smart Card
    "ScDeviceEnum"                                      # Smart Card Device Enumeration Service
    "SCPolicySvc"                                       # Smart Card Removal Policy
    "SDRSVC"                                            # Windows Backup
    "seclogon"                                          # Secondary Logon
    "SEMgrSvc"                                          # Payments and NFC/SE Manager
    "SensorDataService"                                 # Sensor Data Service
    "SensrSvc"                                          # Sensor Monitoring Service
    "SessionEnv"                                        # Remote Desktop Configuration
    "shpamsvc"                                          # Shared PC Account Manager
    "smphost"                                           # Microsoft Storage Spaces SMP
    "SmsRouter"                                         # Microsoft Windows SMS Router Service.
    "SNMPTrap"                                          # SNMP Trap
    "Spooler"                                           # Print Spooler
    "SSDPSRV"                                           # SSDP Discovery
    "ssh-agent"                                         # OpenSSH Authentication Agent
    "SstpSvc"                                           # Secure Socket Tunneling Protocol Service
    "svsvc"                                             # Spot Verifier
    "SysMain"                                           # SysMain
    "TapiSrv"                                           # Telephony
    "TermService"                                       # Remote Desktop Services
    "TieringEngineService"                              # Storage Tiers Management
    "TrkWks"                                            # Distributed Link Tracking Client
    "TroubleshootingSvc"                                # Recommended Troubleshooting Service
    "tzautoupdate"                                      # Auto Time Zone Updater
    "UmRdpService"                                      # Remote Desktop Services UserMode Port Redirector
    "upnphost"                                          # UPnP Device Host
    "WalletService"                                     # WalletService
    "WarpJITSvc"                                        # Warp JIT Service
    "wbengine"                                          # Block Level Backup Engine Service
    "WbioSrvc"                                          # Windows Biometric Service
    "wcncsvc"                                           # Windows Connect Now - Config Registrar
    "WebClient"                                         # WebClient
    "Wecsvc"                                            # Windows Event Collector
    "WEPHOSTSVC"                                        # Windows Encryption Provider Host Service
    "wercplsupport"                                     # Problem Reports Control Panel Support
    "WerSvc"                                            # Windows Error Reporting Service
    "WFDSConMgrSvc"                                     # Wi-Fi Direct Services Connection Manager Service
    "whesvc"                                            # Windows Health and Optimized Experiences
    "WiaRpc"                                            # Still Image Acquisition Events
    "WinRM"                                             # Windows Remote Management (WS-Management)
    "wisvc"                                             # Windows Insider Service
    "WlanSvc"                                           # WLAN AutoConfig
    "wlpasvc"                                           # Local Profile Assistant Service
    "WManSvc"                                           # Windows Management Service
    "wmiApSrv"                                          # WMI Performance Adapter
    "WMPNetworkSvc"                                     # Windows Media Player Network Sharing Service
    "workfolderssvc"                                    # Work Folders
    "WpcMonSvc"                                         # Parental Controls
    "WPDBusEnum"                                        # Portable Device Enumerator Service
    "WSAIFabricSvc"                                     # WSAIFabricSvc
    "WSearch"                                           # Windows Search
    "WwanSvc"                                           # WWAN AutoConfig
    "XblAuthManager"                                    # Xbox Live Auth Manager
    "XblGameSave"                                       # Xbox Live Game Save
    "XboxGipSvc"                                        # Xbox Accessory Management Service
    "XboxNetApiSvc"                                     # Xbox Live Networking Service
    "ZTHELPER"                                          # ZTDNS Helper service
)
#########################################################

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

function Set-ControlFlowGuard {
    param ([string]$Content)
    $TempFile = [System.IO.Path]::GetTempFileName() + ".xml"
    $Content | Out-File "$TempFile" -Encoding UTF8
    Set-ProcessMitigation -PolicyFilePath "$TempFile"
    Remove-Item "$TempFile" -Force
}

# Windows Defender settings
@(
    Set-MpPreference -PerformanceModeStatus Enabled             # Virus & threat protection > Virus & threat protection settings > Dev Drive protection
    Set-MpPreference -MAPSReporting Disabled                    # Virus & threat protection > Virus & threat protection settings > Cloud-delivered protection
    Set-MpPreference -SubmitSamplesConsent NeverSend            # Virus & threat protection > Virus & threat protection settings > Automatic sample submission
    Set-MpPreference -EnableControlledFolderAccess Disabled     # Virus & threat protection > Ransomware protection > Controlled folder access
    # > Registry (Security)                                     # App & browser control > Smart App Control
    # > Registry (Security)                                     # App & browser control > Reputation-based protection > Check apps and files
    # > Registry (Security)                                     # App & browser control > Reputation-based protection > SmartScreen for Microsoft Edge
    # TODO: Find the correspondent registry                     # App & browser control > Reputation-based protection > Phishing protection
    Set-MpPreference -PUAProtection Disabled                    # App & browser control > Reputation-based protection > Potentially unwanted app blocking
    # > Registry (Security)                                     # App & browser control > Reputation-based protection > SmartScreen for Microsoft Store Apps
) | ForEach-Object {
    & $_
}
Write-Custom "Successfully disabled less critical Windows Defender settings"

# Windows Defender Scan folders to exclude
$ExcludedFolders | Where-Object { $_ } | ForEach-Object {
    Add-MpPreference -ExclusionPath $_
}
Write-Custom "Successfully added to exclude Windows Defender folders"

# Windows Defender Scan and Control Flow Guard processes to exclude
$ExcludedProcesses | Where-Object { $_ } | ForEach-Object {
    Add-MpPreference -ExclusionProcess $_
    $CFGRules += "  <AppConfig Executable=`"$_`">`n$($CFGRule.TrimEnd())`n  </AppConfig>`n"
}
Write-Custom "Successfully added to exclude Windows Defender processes"

# Control Flow Guard settings
Set-ControlFlowGuard -Content @"
<?xml version="1.0" encoding="UTF-8"?>
<MitigationPolicy>
$CFGRules
</MitigationPolicy>
"@
Write-Custom "Successfully added to exclude Control Flow Guard processes"

# Services to set to manual
$ManualServices | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Set-Service $_ -StartupType Manual"
}

# WinGet and PowerShell
@(
    "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', $Null, 'User')"
    "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', $Null, 'Machine')"
) | ForEach-Object {
    Invoke-Custom $_
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
    "Disable-MMAgent -ApplicationLaunchPrefetching"
    "Disable-MMAgent -ApplicationPreLaunch"
    "Disable-MMAgent -MemoryCompression"
    "Disable-MMAgent -OperationAPI"
    "Disable-MMAgent -PageCombining"
    "Set-MMAgent -MaxOperationAPIFiles 1"
) | ForEach-Object {
    Invoke-Custom ($_ -match "^Disable-MMAgent" ? "$_ -ErrorAction SilentlyContinue" : $_)
}

# Global network settings
@(
    "Set-NetOffloadGlobalSetting -Chimney Disabled"
    "Set-NetOffloadGlobalSetting -NetworkDirect Enabled"
    "Set-NetOffloadGlobalSetting -NetworkDirectAcrossIPSubnets Blocked"
    "Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled"
    "Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled"
    "Set-NetOffloadGlobalSetting -ReceiveSideScaling $($RSSQueues -gt 0 ? 'Enabled' : 'Disabled')"
    "Set-NetOffloadGlobalSetting -TaskOffload $($Offloads -gt 0 ? 'Enabled' : 'Disabled')"
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
    @("ipv4", "ipv6") | ForEach-Object {
        $X = "netsh int $_ set dns $($Adapter.ifIndex) static $($DNS["$_-1"]) primary"; Invoke-Custom $X; $NetshCommands += "$X`n"
        $Y = "netsh int $_ add dns $($Adapter.ifIndex) $($DNS["$_-2"]) index=2"; Invoke-Custom $Y; $NetshCommands += "$Y`n"
        $Z = "netsh int $_ set subinterface $($Adapter.ifIndex) mtu=$MTU"; Invoke-Custom "$Z store=persistent"; Invoke-Custom $Z; $NetshCommands += "$Z`n"
    }
    Invoke-Custom "Get-NetAdapterBinding -Name '$($Adapter.Name)' | Where-Object { `$_.ComponentID -notin @('ms_tcpip', 'ms_tcpip6') } | Disable-NetAdapterBinding"
    Invoke-Custom "Reset-NetAdapterAdvancedProperty -NoRestart -Name '$($Adapter.Name)' -DisplayName '*'"
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" | ForEach-Object {
        if ("Tcpip_$($Adapter.InterfaceGuid)" -ne $_.PSChildName) { return }
        Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Type "DWord" -Value 2
        Write-Custom "Successfully disabled NetBIOS on $($Adapter.Name) $($Adapter.InterfaceGuid)"
    }
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
        if ($Adapter.InterfaceGuid -ne $_.PSChildName) { return }
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Type "DWord" -Value 1
        Set-ItemProperty -Path $_.PSPath -Name "TcpDelAckTicks"  -Type "DWord" -Value 0
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay"      -Type "DWord" -Value 1
        Write-Custom "Successfully disabled Nagle's on $($Adapter.Name) $($Adapter.InterfaceGuid)"
        Set-ItemProperty -Path $_.PSPath -Name "TCPInitialRtt"   -Type "DWord" -Value $InitialRTO
        Write-Custom "Successfully fixed InitialRTO on $($Adapter.Name) $($Adapter.InterfaceGuid)"
    }
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
$SelsusProps = @{
    "AllowIdleIrpInD3"               = @{ Type = "DWord";  Value = 0 }
    "DeviceSelectiveSuspended"       = @{ Type = "DWord";  Value = 0 }
    "EnhancedPowerManagementEnabled" = @{ Type = "DWord";  Value = 0 }
    "SelectiveSuspendEnabled"        = @{ Type = "Binary"; Value = ([byte[]](0x00)) }
    "SelectiveSuspendOn"             = @{ Type = "DWord";  Value = 0 }
}
Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*\Device Parameters" | ForEach-Object {
    $Path = $_.PSPath
    $DeviceProps = Get-ItemProperty -Path $Path
    $SelsusProps.Keys | ForEach-Object {
        if ($DeviceProps.PSObject.Properties.Name -contains $_) {
            Set-ItemProperty -Path $Path -Name $_ -Type $SelsusProps[$_].Type -Value $SelsusProps[$_].Value
        }
    }
}
Write-Custom "Successfully reset Selective Suspend for applicable devices"

# Background Access for UWP applications
Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" | Where-Object { $_.PSChildName -notmatch "NVIDIA|Realtek|OneDrive" } | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "Disabled"                -Type "DWord" -Value 1
    Set-ItemProperty -Path $_.PSPath -Name "DisabledBySystem"        -Type "DWord" -Value 1
    Set-ItemProperty -Path $_.PSPath -Name "DisabledByUser"          -Type "DWord" -Value 1
    Set-ItemProperty -Path $_.PSPath -Name "IgnoreBatterySaver"      -Type "DWord" -Value 0
    Set-ItemProperty -Path $_.PSPath -Name "NCBEnabled"              -Type "DWord" -Value 0
    Set-ItemProperty -Path $_.PSPath -Name "SleepDisabled"           -Type "DWord" -Value 1
    Set-ItemProperty -Path $_.PSPath -Name "SleepIgnoreBatterySaver" -Type "DWord" -Value 0
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
