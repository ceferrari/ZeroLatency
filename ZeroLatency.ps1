# Request administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Writes all output to a .log file in the same directory as the script
Start-Transcript -Path (Join-Path -Path $PSScriptRoot -ChildPath "ZeroLatency.log") -Append

#########################################################
# BEGIN - Start modifying
#########################################################

#########################################################
# STEP 1 - Variables to modify (system)
$HAGS = 0               # Hardware Accelerated GPU Sched.  0 = Off, 1 = On
$GameMode = 1           # Windows Game Mode                0 = Off, 1 = On
$Pagefile = 16384       # Pagefile (Virtual Memory)        X = Fixed size in MB (e.g., 16384 for 16GB)
$Win32PrioSep = 36      # Win32PrioritySeparation          X = Decimal value to set the priority scheduling, which controls how the system distributes CPU time between foreground and background processes
                        # * F.B. = Foreground Boost
                        # Short Quantum, Fixed Policy
                        # - 42 Dec = 2A Hex → F.B. High
                        # - 41 Dec = 29 Hex → F.B. Medium
                        # - 40 Dec = 28 Hex → F.B. None
                        # Short Quantum, Variable Policy
                        # - 38 Dec = 26 Hex → F.B. High
                        # - 37 Dec = 25 Hex → F.B. Medium
                        # - 36 Dec = 24 Hex → F.B. None
                        # Long Quantum, Fixed Policy
                        # - 26 Dec = 1A Hex → F.B. High
                        # - 25 Dec = 19 Hex → F.B. Medium
                        # - 24 Dec = 18 Hex → F.B. None
                        # Long Quantum, Variable Policy
                        # - 22 Dec = 16 Hex → F.B. High
                        # - 21 Dec = 15 Hex → F.B. Medium
                        # - 20 Dec = 14 Hex → F.B. None
                        # References
                        # - https://www.youtube.com/watch?v=bqDMG1ZS-Yw
                        # - https://www.youtube.com/watch?v=5MF8XjDdr64

# STEP 1 - Variables to modify (network basic)
$NICBrand = 1           # Network Interface Card Brand     1 = Realtek, 2 = Intel
$DNSProvider = 1        # Domain Name System Provider      1 = Cloudflare, 2 = Google
$RBuffers = 32          # Receive Buffers                  32 = Min, 4096 = Max (Increments of 8; may vary by NIC)
$TBuffers = 64          # Transmit Buffers                 64 = Min, 4096 = Max (Increments of 8; may vary by NIC)
$Offloads = 3           # Checksum Offloads                0 = Off, 1 = Tx only, 2 = Rx only, 3 = Both
$RSSQueues = 4          # Number of RSS Queues             0 = Off, X = Number of RSS Queues (Available values: 1, 2, 4; may vary by NIC)
$RSSCore = 4            # Core to start assigning Queues   X = Physical core (e.g., 0, 2, 4, 6... with HT/SMT on; 0, 1, 2, 3... otherwise), -1 = Assign from last core backwards

# STEP 1 - Variables to modify (network advanced)
$AutoTuning = 0         # TCP Auto-Tuning Level            0 = Off, 1 = Normal, 2 = Restricted, 3 = HighlyRestricted, 4 = Experimental
$TCPOptions = 1         # TCP Options                      0 = Off, 1 = Window Scaling, 2 = Timestamps, 3 = Both
$TCPRetries = 2         # TCP Retransmission Limits        2 = Min, X = Value of TcpMaxDupAcks, TcpMaxConnectRetransmissions, TcpMaxDataRetransmissions, MaxSynRetransmissions
$InitialRTO = 2000      # Initial Retransmission Timeout   300 = Min, 65535 = Max (In milliseconds)
$ROOLimit = 10          # Reassembly Out of Order Limit    X = How many out-of-order packets TCP can store before reassembly
#########################################################

#########################################################
# STEP 2 - Add or remove folders to be excluded from Windows Defender Scan
$ExcludedFolders = @(
    "C:\Games"
    "C:\ProgramData"
    "$env:UserProfile\AppData"
    "$env:SystemRoot\System32\config\systemprofile\AppData"
    "$env:SystemRoot\Temp"
)
#########################################################

#########################################################
# STEP 3 - Add or remove processes to be excluded from Windows Defender Scan and Exploit Protection
$ExcludedProcesses = @(
    # System
    "audiodg.exe"
    "csrss.exe"
    "ctfmon.exe"
    "dwm.exe"
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
# STEP 4 - Add or remove services to be disabled
$DisabledServices = @(
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
# STEP 5 - Add or remove packages and apps to be uninstalled (ref: https://github.com/Raphire/Win11Debloat/blob/master/Appslist.txt)
$UninstalledPackages = @(
    "Clipchamp.Clipchamp"                               # Video editor from Microsoft
    "Microsoft.3DBuilder"                               # Basic 3D modeling software
    "Microsoft.549981C3F5F10"                           # Cortana app (Voice assistant)
    "Microsoft.BingFinance"                             # Finance news and tracking via Bing (Discontinued)
    "Microsoft.BingFoodAndDrink"                        # Recipes and food news via Bing (Discontinued)
    "Microsoft.BingHealthAndFitness"                    # Health and fitness tracking/news via Bing (Discontinued)
    "Microsoft.BingNews"                                # News aggregator via Bing (Replaced by Microsoft News/Start)
    "Microsoft.BingSearch"                              # Web Search from Microsoft Bing (Integrates into Windows Search)
    "Microsoft.BingSports"                              # Sports news and scores via Bing (Discontinued)
    "Microsoft.BingTranslator"                          # Translation service via Bing
    "Microsoft.BingTravel"                              # Travel planning and news via Bing (Discontinued)
    "Microsoft.BingWeather"                             # Weather forecast via Bing
    "Microsoft.Copilot"                                 # AI assistant integrated into Windows
    "Microsoft.Edge"                                    # Edge browser (Can only be uninstalled in European Economic Area)
    "Microsoft.GamingApp"                               # Modern Xbox Gaming App, required for installing some PC games
    "Microsoft.GetHelp"                                 # Required for some Windows 11 Troubleshooters and support interactions
    "Microsoft.Getstarted"                              # Tips and introductory guide for Windows (Cannot be uninstalled in Windows 11)
    "Microsoft.Messaging"                               # Messaging app, often integrates with Skype (Largely deprecated)
    "Microsoft.Microsoft3DViewer"                       # Viewer for 3D models
    "Microsoft.MicrosoftJournal"                        # Digital note-taking app optimized for pen input
    "Microsoft.MicrosoftOfficeHub"                      # Hub to access Microsoft Office apps and documents (Precursor to Microsoft 365 app)
    "Microsoft.MicrosoftPowerBIForWindows"              # Business analytics service client
    "Microsoft.MicrosoftSolitaireCollection"            # Collection of solitaire card games
    "Microsoft.MicrosoftStickyNotes"                    # Digital sticky notes app
    "Microsoft.MixedReality.Portal"                     # Portal for Windows Mixed Reality headsets
    "Microsoft.NetworkSpeedTest"                        # Internet connection speed test utility
    "Microsoft.News"                                    # News aggregator (Replaced Bing News, now part of Microsoft Start)
    "Microsoft.Office.OneNote"                          # Digital note-taking app (Universal Windows Platform version)
    "Microsoft.Office.Sway"                             # Presentation and storytelling app
    "Microsoft.OneConnect"                              # Mobile Operator management app (Replaced by Mobile Plans)
    "Microsoft.OutlookForWindows"                       # New mail app: Outlook for Windows
    "Microsoft.People"                                  # Required for & included with Mail & Calendar (Contacts management)
    "Microsoft.PowerAutomateDesktop"                    # Desktop automation tool (RPA)
    "Microsoft.Print3D"                                 # 3D printing preparation software
    "Microsoft.RemoteDesktop"                           # Remote Desktop client app
    "Microsoft.SkypeApp"                                # Skype communication app (Universal Windows Platform version)
    "Microsoft.StartExperiencesApp"                     # This app powers Windows Widgets My Feed
    "Microsoft.Todos"                                   # To-do list and task management app
    "Microsoft.Whiteboard"                              # Digital collaborative whiteboard app
    "Microsoft.WindowsAlarms"                           # Alarms & Clock app
    "Microsoft.windowscommunicationsapps"               # Mail & Calendar app suite
    "Microsoft.WindowsFeedbackHub"                      # App for providing feedback to Microsoft on Windows
    "Microsoft.WindowsMaps"                             # Mapping and navigation app
    "Microsoft.WindowsSoundRecorder"                    # Basic audio recording app
    "Microsoft.Xbox.TCUI"                               # UI framework, seems to be required for MS store, photos and certain games
    "Microsoft.XboxApp"                                 # Old Xbox Console Companion App, no longer supported
    "Microsoft.XboxGameOverlay"                         # Game overlay, required/useful for some games (Part of Xbox Game Bar)
    "Microsoft.XboxGamingOverlay"                       # Game overlay, required/useful for some games (Part of Xbox Game Bar)
    "Microsoft.XboxIdentityProvider"                    # Xbox sign-in framework, required for some games and Xbox services
    "Microsoft.XboxSpeechToTextOverlay"                 # Might be required for some games, WARNING: This app cannot be reinstalled easily! (Accessibility feature)
    "Microsoft.YourPhone"                               # Phone link (Connects Android/iOS phone to PC)
    "Microsoft.ZuneMusic"                               # Modern Media Player (Replaced Groove Music, plays local audio/video)
    "Microsoft.ZuneVideo"                               # Movies & TV app for renting/buying/playing video content (Rebranded as "Films & TV")
    "MicrosoftCorporationII.MicrosoftFamily"            # Family Safety App for managing family accounts and settings
    "MicrosoftCorporationII.QuickAssist"                # Remote assistance tool
    "MicrosoftTeams"                                    # Old MS Teams personal (MS Store version)
    "MicrosoftWindows.CrossDevice"                      # Phone integration within File Explorer, Camera and more (Part of Phone Link features)
    "MSTeams"                                           # New MS Teams app (Work/School or Personal)
    #####################################################
    "ACGMediaPlayer"                                    # Media player app
    "ActiproSoftwareLLC"                                # Potentially UI controls or software components, often bundled by OEMs
    "AdobeSystemsIncorporated.AdobePhotoshopExpress"    # Basic photo editing app from Adobe
    "Amazon.com.Amazon"                                 # Amazon shopping app
    "AmazonVideo.PrimeVideo"                            # Amazon Prime Video streaming service app
    "Asphalt8Airborne"                                  # Racing game
    "AutodeskSketchBook"                                # Digital drawing and sketching app
    "CaesarsSlotsFreeCasino"                            # Casino slot machine game
    "COOKINGFEVER"                                      # Restaurant simulation game
    "CyberLinkMediaSuiteEssentials"                     # Multimedia software suite (often preinstalled by OEMs)
    "Disney"                                            # General Disney content app (may vary by region/OEM, often Disney+)
    "DisneyMagicKingdoms"                               # Disney theme park building game
    "DrawboardPDF"                                      # PDF viewing and annotation app, often focused on pen input
    "Duolingo-LearnLanguagesforFree"                    # Language learning app
    "EclipseManager"                                    # Often related to specific OEM software or utilities (e.g., for managing screen settings)
    "Facebook"                                          # Facebook social media app
    "FarmVille2CountryEscape"                           # Farming simulation game
    "fitbit"                                            # Fitbit activity tracker companion app
    "Flipboard"                                         # News and social network aggregator styled as a magazine
    "HiddenCity"                                        # Hidden object puzzle adventure game
    "HULULLC.HULUPLUS"                                  # Hulu streaming service app
    "iHeartRadio"                                       # Internet radio streaming app
    "Instagram"                                         # Instagram social media app
    "king.com.BubbleWitch3Saga"                         # Puzzle game from King
    "king.com.CandyCrushSaga"                           # Puzzle game from King
    "king.com.CandyCrushSodaSaga"                       # Puzzle game from King
    "LinkedInforWindows"                                # LinkedIn professional networking app
    "MarchofEmpires"                                    # Strategy game
    "Netflix"                                           # Netflix streaming service app
    "NYTCrossword"                                      # New York Times crossword puzzle app
    "OneCalendar"                                       # Calendar aggregation app
    "PandoraMediaInc"                                   # Pandora music streaming app
    "PhototasticCollage"                                # Photo collage creation app
    "PicsArt-PhotoStudio"                               # Photo editing and creative app
    "Plex"                                              # Media server and player app
    "PolarrPhotoEditorAcademicEdition"                  # Photo editing app (Academic Edition)
    "Royal Revolt"                                      # Tower defense / strategy game
    "Shazam"                                            # Music identification app
    "Sidia.LiveWallpaper"                               # Live wallpaper app
    "SlingTV"                                           # Live TV streaming service app
    "TikTok"                                            # TikTok short-form video app
    "TuneInRadio"                                       # Internet radio streaming app
    "Twitter"                                           # Twitter (now X) social media app
    "Viber"                                             # Messaging and calling app
    "WinZipUniversal"                                   # File compression and extraction utility (Universal Windows Platform version)
    "Wunderlist"                                        # To-do list app (Acquired by Microsoft, functionality moved to Microsoft To Do)
    "XING"                                              # Professional networking platform popular in German-speaking countries
    "Yousician"                                         # Music learning app
)
#########################################################

#########################################################
# END - Stop modifying
#########################################################

# Exploit Protections to be disabled
$ExploitProtections = @(
    "AllowStoreSignedBinaries"
    "AllowThreadsToOptOut"
    "AuditChildProcess"
    "AuditDynamicCode"
    "AuditEnableExportAddressFilter"
    "AuditEnableExportAddressFilterPlus"
    "AuditEnableImportAddressFilter"
    "AuditEnableRopCallerCheck"
    "AuditEnableRopSimExec"
    "AuditEnableRopStackPivot"
    "AuditFont"
    "AuditLowLabelImageLoads"
    "AuditMicrosoftSigned"
    "AuditPreferSystem32"
    "AuditRemoteImageLoads"
    "AuditSEHOP"
    "AuditStoreSigned"
    "AuditSystemCall"
    "AuditUserShadowStack"
    "BlockDynamicCode"
    "BlockLowLabelImageLoads"
    "BlockRemoteImageLoads"
    "BottomUp"
    "CFG"
    "DEP"
    "DisableExtensionPoints"
    "DisableFsctlSystemCalls"
    "DisableNonSystemFonts"
    "DisableWin32kSystemCalls"
    "DisallowChildProcessCreation"
    "EmulateAtlThunks"
    "EnableExportAddressFilter"
    "EnableExportAddressFilterPlus"
    "EnableImportAddressFilter"
    "EnableRopCallerCheck"
    "EnableRopSimExec"
    "EnableRopStackPivot"
    "EnforceModuleDependencySigning"
    "ForceRelocateImages"
    "HighEntropy"
    "MicrosoftSignedOnly"
    "PreferSystem32"
    "RequireInfo"
    "SEHOP"
    "SEHOPTelemetry"
    "StrictCFG"
    "StrictHandle"
    "SuppressExports"
    "TerminateOnError"
    "UserShadowStack"
    "UserShadowStackStrictMode"
)

# Number of *physical* cores of the CPU (e.g., 6 for a 6C/12T model)
$NumCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum

# TCP Auto-Tuning Level
$ATL = @{
    0 = "disabled"
    1 = "normal"
    2 = "restricted"
    3 = "highlyrestricted"
    4 = "experimental"
}

# NIC Advanced Properties
# Get-NetAdapterAdvancedProperty -AllProperties |
#     Where-Object { $_.DisplayName -ne $null -and $_.DisplayValue -ne $null } |
#     Sort-Object -Property RegistryKeyword |
#     Select-Object -Property Name, RegistryKeyword, DisplayValue, DisplayName
$NIC = @{
    1 = [ordered]@{ # Realtek
        "*EEE" = 0
        "*FlowControl" = 0
        "*InterruptModeration" = 0
        "*IPChecksumOffloadIPv4" = $Offloads
        "*JumboPacket" = 1514
        "*LsoV2IPv4" = 0
        "*LsoV2IPv6" = 0
        "*ModernStandbyWoLMagicPacket" = 0
        "*NumRssQueues" = [Math]::Max(1, $RSSQueues)
        "*PMARPOffload" = 0
        "*PMNSOffload" = 0
        "*PriorityVLANTag" = 0
        "*ReceiveBuffers" = $RBuffers
        "*RSS" = [Math]::Min(1, $RSSQueues)
        "*SelectiveSuspend" = 0
        "*SpeedDuplex" = 0
        "*SSIdleTimeout" = 50
        "*TCPChecksumOffloadIPv4" = $Offloads
        "*TCPChecksumOffloadIPv6" = $Offloads
        "*TransmitBuffers" = $TBuffers
        "*UDPChecksumOffloadIPv4" = $Offloads
        "*UDPChecksumOffloadIPv6" = $Offloads
        "*WakeOnMagicPacket" = 0
        "*WakeOnPattern" = 0
        "AdvancedEEE" = 0
        "EEEMaxSupportSpeed" = 5000
        "EnableGreenEthernet" = 0
        "GigaLite" = 0
        "PowerSavingMode" = 0
        "RegVlanid" = 0
        "S5WakeOnLan" = 0
        "WolShutdownLinkSpeed" = 2
    }
    2 = [ordered]@{ # Intel
        "*EEE" = 0
        "*FlowControl" = 0
        "*InterruptModeration" = 0
        "*IPChecksumOffloadIPv4" = $Offloads
        "*JumboPacket" = 1514
        "*LsoV2IPv4" = 0
        "*LsoV2IPv6" = 0
        "*PMARPOffload" = 0
        "*PMNSOffload" = 0
        "*PriorityVLANTag" = 0
        "*ReceiveBuffers" = $RBuffers
        "*SpeedDuplex" = 0
        "*TCPChecksumOffloadIPv4" = $Offloads
        "*TCPChecksumOffloadIPv6" = $Offloads
        "*TransmitBuffers" = $TBuffers
        "*UDPChecksumOffloadIPv4" = $Offloads
        "*UDPChecksumOffloadIPv6" = $Offloads
        "*WakeOnMagicPacket" = 0
        "*WakeOnPattern" = 0
        "AdvancedEEE" = 0
        "EnableGreenEthernet" = 0
        "GigaLite" = 0
        "PowerSavingMode" = 0
        "RegVlanid" = 0
        "S5WakeOnLan" = 0
        "WolShutdownLinkSpeed" = 2
    }
}[$NICBrand]

# DNS Providers
$DNS = @{
    1 = @{ # Cloudflare
        "ipv4-1" = "1.1.1.1"
        "ipv4-2" = "1.0.0.1"
        "ipv6-1" = "2606:4700:4700::1111"
        "ipv6-2" = "2606:4700:4700::1001"
    }
    2 = @{ # Google
        "ipv4-1" = "8.8.8.8"
        "ipv4-2" = "8.8.4.4"
        "ipv6-1" = "2001:4860:4860::8888"
        "ipv6-2" = "2001:4860:4860::8844"
    }
}[$DNSProvider]

# Maximum Transmission Unit (576 = Min, 1500 = Max - Common values: 1500 for Ethernet, 1492 for PPPoE, 1472 for VPN)
$MTU = 1500..576 | Where-Object { ping $DNS["ipv4-1"] -f -l ($_-28) -n 1 -w 300 | Select-String "TTL" } | Select-Object -First 1

# Maximum Segment Size (MTU minus 40 bytes for TCP/IP header minus 0 or 12 bytes for TCP Options)
$MSS = $MTU - 40 - ($TCPOptions -le 1 ? 0 : 12)

# TCP Window Size (Largest multiple of MSS that doesn't exceed 65535 - Limit defined by RFC 1323)
$TWS = [math]::Floor(65535 / $MSS) * $MSS

# Auxiliary variables
$NetshCommands = ""

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

function New-Task {
    param ([string]$Name, [string]$Command)
    $Argument = "-NoProfile -ExecutionPolicy Bypass -Command `"& { $Command }`""
    $Action = New-ScheduledTaskAction -Execute "pwsh" -Argument $Argument
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    Unregister-ScheduledTask -TaskName $Name -Confirm:$False -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null
    Start-ScheduledTask -TaskName $Name
}

function Split-Registry {
    param ([string]$Content)
    $Pattern = "^\[.*\]$"
    $Lines = $Content -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $Paths = $Lines | Where-Object { $_ -match $Pattern }
    $Entries = $Lines | Where-Object { $_ -notmatch $Pattern }
    return ($Paths | ForEach-Object { @($_) + $Entries -join "`n" }) -join "`n`n"
}

function Set-Registry {
    param ([string]$Content)
    $TempFile = [System.IO.Path]::GetTempFileName() + ".reg"
    $Content | Out-File "$TempFile" -Encoding ASCII
    reg import "$TempFile" > $Null 2>&1
    Remove-Item "$TempFile" -Force
}

function Get-RSSCommand {
    param([int]$RSSQueues, [int]$RSSCore, [int]$NumCores)
    $Limit = $NumCores * 2 - 2
    if ($RSSCore -eq -1) {
        $Base = $NumCores * 2 - $RSSQueues * 2
        $Max = $Limit
    } else {
        $Base = $Max = $RSSCore
        if ($RSSQueues -gt 0) { $Max += ($RSSQueues - 1) * 2 }
    }
    return "Set-NetAdapterRss -Profile 'ClosestStatic' -NumberOfReceiveQueues $([Math]::Max(1, $RSSQueues)) -BaseProcessorNumber $([Math]::Min($Base, $Limit)) -MaxProcessorNumber $([Math]::Min($Max, $Limit)) -Enabled `$$($RSSQueues -gt 0)"
}

# Disk Cleanup and Optimization
$SagerunProfile = 5555
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" | ForEach-Object {
    Set-ItemProperty -Path $_.PsPath -Name "StateFlags$SagerunProfile" -Type "DWord" -Value 2 -Force
}
@{
    "defrag" = "/AllVolumes /Optimize /Retrim /PrintProgress /Verbose"
    "dism" = "/Online /Cleanup-Image /StartComponentCleanup /ResetBase"
    "cleanmgr" = "/sagerun:$SagerunProfile"
}.GetEnumerator() | ForEach-Object {
    Get-Process $_.Key -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process -FilePath ($_.Key + ".exe") -ArgumentList $_.Value
}

# Temporary files
@(
    "$env:LocalAppData\Temp"
    "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
    "$env:ProgramData\Microsoft\Windows\WSUS\UpdateServicesPackages"
    "$env:SystemRoot\Logs"
    "$env:SystemRoot\Minidump"
    "$env:SystemRoot\Prefetch"
    "$env:SystemRoot\SoftwareDistribution\Download"
    "$env:SystemRoot\Temp"
    "$env:UserProfile\AppData\Local\CrashDumps"
    "$env:UserProfile\AppData\Local\Microsoft\Windows\Explorer"
    "$env:UserProfile\AppData\Local\Microsoft\Windows\History"
    "$env:UserProfile\AppData\Local\Microsoft\Windows\INetCache"
    "$env:UserProfile\AppData\Local\Microsoft\Windows\INetCookies"
    "$env:UserProfile\AppData\Local\Packages\Microsoft.Windows.Caches"
    "$env:UserProfile\AppData\Local\Temp"
    "$env:UserProfile\AppData\LocalLow\Temp"
) + (
    Get-ChildItem -Path "$env:UserProfile\AppData\Local\Packages" -Directory | Where-Object { $_.Name -like "Microsoft.Windows.ContentDeliveryManager_*" } | ForEach-Object { Join-Path $_.FullName "LocalState\Assets" }
) | ForEach-Object {
    if (Test-Path $_) { Remove-Item -Path "$_\*" -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Custom "Successfully cleared temporary files"

# DirectX shader cache
@("$env:UserProfile\AppData", "$env:SystemRoot\System32\config\systemprofile\AppData") | ForEach-Object {
    $X = $_
    @("Local", "LocalLow", "Roaming") | ForEach-Object {
        $Y = $_
        @("AMD", "NVIDIA") | ForEach-Object {
            $Path = "$X\$Y\$_"
            if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue }
        }
        if ($Y -eq "Local") {
            $Path = "$X\$Y\D3DSCache"
            if (Test-Path $Path) { Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
if (Test-Path "HKCU:\Software\Valve\Steam") { Remove-Item "$((Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam').SteamPath)\steamapps\shadercache" -Recurse -Force -ErrorAction SilentlyContinue }
Write-Custom "Successfully cleared DirectX shader cache"

# Windows Defender settings
@{
    "PerformanceModeStatus" = "Disabled"            # Virus & threat protection > Virus & threat protection settings > Dev Drive protection
    "MAPSReporting" = "Disabled"                    # Virus & threat protection > Virus & threat protection settings > Cloud-delivered protection
    "SubmitSamplesConsent" = "NeverSend"            # Virus & threat protection > Virus & threat protection settings > Automatic sample submission
    "EnableControlledFolderAccess" = "Disabled"     # Virus & threat protection > Ransomware protection > Controlled folder access
    # > Registry (Security)                         # App & browser control > Smart App Control
    # > Registry (Security)                         # App & browser control > Reputation-based protection > Check apps and files
    # > Registry (Security)                         # App & browser control > Reputation-based protection > SmartScreen for Microsoft Edge
    # TODO: Find the correspondent setting          # App & browser control > Reputation-based protection > Phishing protection
    "PUAProtection" = "Disabled"                    # App & browser control > Reputation-based protection > Potentially unwanted app blocking
    # > Registry (Security)                         # App & browser control > Reputation-based protection > SmartScreen for Microsoft Store Apps
}.GetEnumerator() | ForEach-Object {
    Invoke-Custom "Set-MpPreference -$($_.Key) $($_.Value)"
}

# Windows Defender Scan folders to exclude
$ExcludedFolders | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Add-MpPreference -ExclusionPath $_"
}

# Windows Defender Scan and Exploit Protection processes to exclude
$ExcludedProcesses | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Add-MpPreference -ExclusionProcess $_"
    Invoke-Custom "Set-ProcessMitigation -Name $_ -Disable $($ExploitProtections -join ",")"
}

# Services to stop and disable
$DisabledServices | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Stop-Service $_ -Force"
    Invoke-Custom "Set-Service $_ -StartupType Disabled"
}

# Packages and apps to uninstall
$UninstalledPackages | Where-Object { $_ } | ForEach-Object {
    Invoke-Custom "Get-AppxProvisionedPackage -Online | Where-Object { `$_.DisplayName -like '*$_*' } | ForEach-Object { Remove-AppxProvisionedPackage -Online -AllUsers -PackageName `$_.PackageName }"
    Invoke-Custom "Get-AppxPackage -AllUsers | Where-Object { `$_.Name -like '*$_*' } | ForEach-Object { Remove-AppxPackage -AllUsers -Package `$_.PackageFullName }"
}

# WinGet and PowerShell
@(
    "winget upgrade --all --accept-package-agreements --accept-source-agreements"
    "setx POWERSHELL_TELEMETRY_OPTOUT 1"
) | ForEach-Object {
    Invoke-Custom $_
}

# Timers and Data Execution Prevention
@(
    "bcdedit /set useplatformclock no"
    "bcdedit /set useplatformtick no"
    "bcdedit /set disabledynamictick yes"
    "bcdedit /set ``{current``} nx OptIn"
    "Get-PnpDevice -FriendlyName 'High Precision Event Timer' | Disable-PnpDevice -Confirm:`$False"
    "Get-PnpDevice -FriendlyName 'Remote Desktop Device Redirector Bus' | Disable-PnpDevice -Confirm:`$False"
) | ForEach-Object {
    Invoke-Custom $_
}

# Pagefile
@(
    "Set-CimInstance -CimInstance (Get-CimInstance -ClassName Win32_ComputerSystem) -Arguments @{ AutomaticManagedPagefile = `$False }"
    "Set-CimInstance -CimInstance (Get-CimInstance -ClassName Win32_PageFileSetting) -Arguments @{ InitialSize=$($Pagefile); MaximumSize=$($Pagefile) }"
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
    Invoke-Custom $_
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

# Adapter network settings
$AdapterProperties = @(
    "Disable-NetAdapterEncapsulatedPacketTaskOffload"
    "Disable-NetAdapterIPsecOffload"
    "Disable-NetAdapterLso"
    "Disable-NetAdapterPowerManagement"
    "Disable-NetAdapterQos"
    "Disable-NetAdapterRsc"
    "Disable-NetAdapterSriov"
    "Disable-NetAdapterUso"
    "Disable-NetAdapterVmq"
    "$($Offloads -gt 0 ? 'Enable' : 'Disable')-NetAdapterChecksumOffload"
    "$($RSSQueues -gt 0 ? 'Enable' : 'Disable')-NetAdapterRss"
    Get-RSSCommand -RSSQueues $RSSQueues -RSSCore $RSSCore -NumCores $NumCores
)

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

# Network settings optimization
@(
    "netsh int ip set dynamicport tcp start=32769 num=32766"
    "netsh int ip set dynamicport udp start=32769 num=32766"
    "netsh int ip set global addressmaskreply=disabled"
    "netsh int ip set global defaultcurhoplimit=64"
    "netsh int ip set global dhcpmediasense=enabled"
    "netsh int ip set global flowlabel=disabled"
    "netsh int ip set global groupforwardedfragments=disabled"
    "netsh int ip set global icmpredirects=disabled"
    "netsh int ip set global loopbackexecutionmode=inline"
    "netsh int ip set global loopbacklargemtu=enabled"
    "netsh int ip set global loopbackworkercount=$($NumCores - 2)"
    "netsh int ip set global mediasenseeventlog=disabled"
    "netsh int ip set global minmtu=576"
    "netsh int ip set global mldlevel=all"
    "netsh int ip set global mldversion=version3"
    "netsh int ip set global multicastforwarding=disabled"
    "netsh int ip set global multiplearpannounce=enabled"
    "netsh int ip set global neighborcachelimit=16384"
    "netsh int ip set global randomizeidentifiers=disabled"
    "netsh int ip set global reassemblylimit=$([Math]::Pow(2, [Math]::Ceiling([Math]::Log2($MSS * $ROOLimit))))"
    "netsh int ip set global reassemblyoutoforderlimit=$($ROOLimit)"
    "netsh int ip set global routecachelimit=16384"
    "netsh int ip set global routepolicies=disabled"
    "netsh int ip set global slaacmaxdadattempts=1"
    "netsh int ip set global sourcebasedecmp=enabled"
    "netsh int ip set global sourceroutingbehavior=drop"
    "netsh int ip set global taskoffload=$($Offloads -gt 0 ? 'enabled' : 'disabled')"
    "netsh int ipv6 set global icmpjumbograms=disabled"
    "netsh int ipv6 set global recursivereassembly=disabled"
    "netsh int ipv6 set global slaacprivacylevel=0"
    "netsh int tcp set global autotuninglevel=$($ATL[$AutoTuning])"
    "netsh int tcp set global dca=$($AutoTuning -gt 0 ? 'enabled' : 'disabled')"
    "netsh int tcp set global ecncapability=$($AutoTuning -gt 0 ? 'enabled' : 'disabled')"
    "netsh int tcp set global fastopen=enabled"
    "netsh int tcp set global fastopenfallback=enabled"
    "netsh int tcp set global hystart=disabled"
    "netsh int tcp set global initialrto=$($InitialRTO)"
    "netsh int tcp set global maxsynretransmissions=$($TCPRetries)"
    "netsh int tcp set global nonsackrttresiliency=$($AutoTuning -gt 0 ? 'enabled' : 'disabled')"
    "netsh int tcp set global pacingprofile=$($AutoTuning -gt 0 ? 'always' : 'off')"
    "netsh int tcp set global prr=$($AutoTuning -gt 0 ? 'enabled' : 'disabled')"
    "netsh int tcp set global rsc=disabled"
    "netsh int tcp set global rss=$($RSSQueues -gt 0 ? 'enabled' : 'disabled')"
    "netsh int tcp set global timestamps=$($TCPOptions -in 2, 3 ? 'enabled' : 'disabled')"
    "netsh int tcp set heuristics forcews=disabled wsh=disabled"
    "netsh int tcp set security mpp=disabled"
    "netsh int tcp set security profiles=disabled"
    "netsh int tcp set supplemental {template} congestionprovider=$($AutoTuning -gt 0 ? 'bbr2' : 'newreno')"
    "netsh int tcp set supplemental {template} delayedackfrequency=1"
    "netsh int tcp set supplemental {template} delayedacktimeout=10"
    "netsh int tcp set supplemental {template} enablecwndrestart=disabled"
    "netsh int tcp set supplemental {template} icw=10"
    "netsh int tcp set supplemental {template} minrto=200"
    "netsh int tcp set supplemental {template} rack=enabled"
    "netsh int tcp set supplemental {template} taillossprobe=disabled"
    "netsh int teredo set state disabled"
    "netsh int udp set global uro=disabled"
    "netsh int udp set global uso=disabled"
    "netsh winsock set autotuning off"
) | ForEach-Object {
    $X = $_
    if ($X -match "^netsh int ip") {
        $Y = "$X store=persistent"
        Invoke-Custom ($Y -match 'slaacprivacylevel' ? $Y : ($Y -replace 'ipv6','ip'))
    }
    if ($x -match "^netsh int tcp set supplemental") {
        @("compat", "custom", "datacenter", "datacentercustom", "internet", "internetcustom") | ForEach-Object {
            $Y = $X -replace "{template}", $_
            Invoke-Custom $Y
            $NetshCommands += "$Y`n"
        }
    } else {
        Invoke-Custom $X
        if ($X -notmatch "^netsh int tcp set global timestamps=") { # Prevent overriding Tcp1323Opts in Registry
            $NetshCommands += "$X`n"
        }
    }
}

# Adapter settings optimization
Get-NetAdapter -Physical | ForEach-Object {
    $Adapter = $_
    @("ipv4", "ipv6") | ForEach-Object {
        $X = "netsh int $_ set subinterface $($Adapter.ifIndex) mtu=$MTU"; Invoke-Custom "$X store=persistent"; Invoke-Custom $X; $NetshCommands += "$X`n"
        $Y = "netsh int $_ set dns $($Adapter.ifIndex) static $($DNS["$_-1"]) primary"; Invoke-Custom $Y; $NetshCommands += "$Y`n"
        $Z = "netsh int $_ add dns $($Adapter.ifIndex) $($DNS["$_-2"]) index=2"; Invoke-Custom $Z; $NetshCommands += "$Z`n"
    }
    Invoke-Custom "Reset-NetAdapterAdvancedProperty -NoRestart -Name '$($Adapter.Name)' -DisplayName '*'"
    Invoke-Custom "Get-NetAdapterBinding -Name '$($Adapter.Name)' | Where-Object { `$_.ComponentID -notin @('ms_tcpip', 'ms_tcpip6') } | Disable-NetAdapterBinding"
    $AdapterProperties | ForEach-Object {
        Invoke-Custom "$_ -NoRestart -Name '$($Adapter.Name)'"
    }
    $NIC.GetEnumerator() | ForEach-Object {
        Invoke-Custom "Set-NetAdapterAdvancedProperty -NoRestart -Name '$($Adapter.Name)' -RegistryKeyword $($_.Key) -RegistryValue $($_.Value)"
    }
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
$PowerPlanID = [guid]::NewGuid()
$PowerPlanPath = "$env:TEMP\ZeroLatency.pow"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ceferrari/ZeroLatency/refs/heads/main/ZeroLatency.pow" -OutFile $PowerPlanPath
if (Test-Path $PowerPlanPath) {
    powercfg /setactive ((powercfg /list | Where-Object { $_ -notmatch "ZeroLatency" } | Select-Object -Last 1) -match $GuidRegex | ForEach-Object { $matches[0] })
    powercfg /list | Select-String "ZeroLatency" | ForEach-Object { if ($_ -match $GuidRegex) { powercfg /delete $matches[0] } }
    powercfg /import $PowerPlanPath $PowerPlanID | Out-Null
    powercfg /changename $PowerPlanID "ZeroLatency" "Prioritizes maximum responsiveness and lowest latency."
    powercfg /setactive $PowerPlanID
    powercfg /hibernate off
    Write-Custom "Successfully imported and activated ZeroLatency Power Plan"
} else {
    Write-Custom "Failed to download ZeroLatency Power Plan"
}

# Power-Saving and Wake on Magic Packet
$WompInstances = Get-CimInstance -ClassName MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
$WakeInstances = Get-CimInstance -ClassName MSPower_DeviceWakeEnable -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
$PwsvInstances = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/wmi | Group-Object -Property InstanceName -AsHashTable -AsString
Get-CimInstance Win32_PnPEntity | ForEach-Object {
    $Pattern = "(?i)$([regex]::Escape($_.PNPDeviceID))"
    $WompInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $WompInstances[$_][0] -Property @{ EnableWakeOnMagicPacketOnly = $False }
    }
    $WakeInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $WakeInstances[$_][0] -Property @{ Enable = ($_.PNPClass -in @("Keyboard", "Mouse")) }
    }
    $PwsvInstances.Keys | Where-Object { $_ -match $Pattern } | ForEach-Object {
        Set-CimInstance -InputObject $PwsvInstances[$_][0] -Property @{ Enable = $False }
    }
}
Write-Custom "Successfully disabled Power-Saving and Wake on Magic Packet for applicable devices"

# Selective Suspend
Get-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\*\*\Device Parameters" | ForEach-Object {
    $Path = $_.PSPath
    $Props = Get-ItemProperty -Path $Path
    @{
        "AllowIdleIrpInD3"               = @{ Type = "DWord";  Value = 0 }
        "DeviceSelectiveSuspended"       = @{ Type = "DWord";  Value = 0 }
        "EnhancedPowerManagementEnabled" = @{ Type = "DWord";  Value = 0 }
        "SelectiveSuspendEnabled"        = @{ Type = "Binary"; Value = ([byte[]](0x00)) }
        "SelectiveSuspendOn"             = @{ Type = "DWord";  Value = 0 }
    }.GetEnumerator() | ForEach-Object {
        if ($Props.PSObject.Properties.Name -notcontains $_.Key) { return }
        Set-ItemProperty -Path $Path -Name $_.Key -Type $_.Value.Type -Value $_.Value.Value
    }
}
Write-Custom "Successfully disabled Selective Suspend for applicable devices"

# Background Access for UWP applications
Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" | Where-Object { $_.PSChildName -notmatch "NVIDIA|Realtek|OneDrive" } | ForEach-Object {
    $Path = $_.PSPath
    @{
        "Disabled"                = @{ Type = "DWord"; Value = 1 }
        "DisabledBySystem"        = @{ Type = "DWord"; Value = 1 }
        "DisabledByUser"          = @{ Type = "DWord"; Value = 1 }
        "IgnoreBatterySaver"      = @{ Type = "DWord"; Value = 0 }
        "NCBEnabled"              = @{ Type = "DWord"; Value = 0 }
        "SleepDisabled"           = @{ Type = "DWord"; Value = 1 }
        "SleepIgnoreBatterySaver" = @{ Type = "DWord"; Value = 0 }
    }.GetEnumerator() | ForEach-Object {
        Set-ItemProperty -Path $Path -Name $_.Key -Type $_.Value.Type -Value $_.Value.Value
    }
}
Write-Custom "Successfully disabled Background Access for UWP applications"

# Registry helpers
# Disable Settings > Accounts > Sign-in options > Use my sign-in info to automatically finish setting up after an update or restart
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\UserARSO' | ForEach-Object { Set-ItemProperty -Path $_.PsPath -Name OptOut -Type "DWord" -Value 1 }
# Disable Settings > Apps > Advanced app settings > Archive apps
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\InstallService\Stubification' | ForEach-Object { Set-ItemProperty -Path $_.PsPath -Name EnableAppOffloading -Type "DWord" -Value 0 }
# Disable Settings > Personalization > Device usage > *
$SubscribedContents = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" | Get-Member -MemberType NoteProperty | Where-Object Name -like "SubscribedContent-*Enabled" | ForEach-Object { "`"$($_.Name)`"=dword:00000000" }) -join "`n"

# Registry tweaks (AI & Search)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; --- Disable AI
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"ShowCopilotButton"=dword:00000000
"ShowCortanaButton"=dword:00000000

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\WindowsCopilot]
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsCopilot]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\WindowsCopilot]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001
"@)

[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\WindowsAI]
"AllowRecallEnablement"=dword:00000000
"DisableAIDataAnalysis"=dword:00000001
"DisableClickToDo"=dword:00000001
"TurnOffSavingSnapshots"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana]
"value"=dword:00000000

$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Paint]
"DisableCocreator"=dword:00000001
"DisableGenerativeErase"=dword:00000001
"DisableGenerativeFill"=dword:00000001
"DisableImageCreator"=dword:00000001
"DisableRemoveBackground"=dword:00000001
"@)

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat]
"IsUserEligible"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsAI]
"AllowRecallEnablement"=dword:00000000
"DisableAIDataAnalysis"=dword:00000001
"DisableClickToDo"=dword:00000001
"TurnOffSavingSnapshots"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\WindowsNotepad]
"DisableAIFeatures"=dword:00000001
; ---

; --- Disable Search
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"AllowSearchToUseLocation"=dword:00000000
"BackgroundAppGlobalToggle"=dword:00000000
"BingSearchEnabled"=dword:00000000
"CanCortanaBeEnabled"=dword:00000000
"CortanaConsent"=dword:00000000
"CortanaEnabled"=dword:00000000
"DeviceHistoryEnabled"=dword:00000000
"DisableSearchBoxSuggestions"=dword:00000001
"HistoryViewEnabled"=dword:00000000
"IsWebView2"=dword:00000000
"SearchboxTaskbarMode"=dword:00000000
"SearchboxTaskbarModeCache"=dword:00000000
"UsingFallbackBundle"=dword:00000000
"VoiceShortcut"=dword:00000000
"WebView2RuntimeVersionType"=dword:00000000
"WebViewBundleType"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SearchSettings]
"IsAADCloudSearchEnabled"=dword:00000000
"IsDeviceSearchHistoryEnabled"=dword:00000000
"IsDynamicSearchBoxEnabled"=dword:00000000
"IsMSACloudSearchEnabled"=dword:00000000
"SafeSearchMode"=dword:00000000
"WebProviderLastNotificationBehavior"=dword:00000000

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer]
"DisableSearchBoxSuggestions"=dword:00000001
"DisableSearchHistory"=dword:00000001
"@)

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Search]
"CortanaEnabled"=dword:00000000
"CortanaInAmbientMode"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search]
"AllowCloudSearch"=dword:00000000
"AllowCortana"=dword:00000000
"AllowCortanaAboveLock"=dword:00000000
"AllowIndexingEncryptedStoresOrItems"=dword:00000000
"AllowSearchToUseLocation"=dword:00000000
"AlwaysUseAutoLangDetection"=dword:00000000
"ConnectedSearchPrivacy"=dword:00000003
"ConnectedSearchUseWeb"=dword:00000000
"ConnectedSearchUseWebOverMeteredConnections"=dword:00000000
"CortanaConsent"=dword:00000000
"DisableWebSearch"=dword:00000001
"EnableDynamicContentInWSB"=dword:00000000
"PreventRemoteQueries"=dword:00000001
"PreventUnwantedAddIns"=""
; ---

"@
Write-Custom "Successfully modified registry settings (AI & Search)"

# Registry tweaks (Features)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Prevent MSDT Exploit
[-HKEY_CLASSES_ROOT\ms-msdt]

; Disable Give access to context menu
[-HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Directory\shellex\CopyHookHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Directory\shellex\PropertySheetHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing]
[-HKEY_CLASSES_ROOT\Drive\shellex\PropertySheetHandlers\Sharing]
[-HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing]
[-HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing]

; Disable Include in library from context menu
[-HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location]
[-HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location]

; Remove Subscriptions
[-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions]

; Remove Gallery and Home shortcuts from File Explorer
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}]
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}]

; Hide duplicate removable drives from navigation pane in File Explorer
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}]

; Hide 3D Objects folder from File Explorer
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}]
[-HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}]

; Disable Let Windows manage my default printer
[HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Windows]
"LegacyDefaultPrinterMode"=dword:00000001

; --- Disable Background Apps
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications]
"GlobalUserDisabled"=dword:00000001

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"BackgroundAppGlobalToggle"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy]
"LetAppsRunInBackground"=dword:00000002
; ---

; --- Disable Connected Devices Platform and Cross-Device
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CDP]
"CdpSessionUserAuthzPolicy"=dword:00000000
"NearShareChannelUserAuthzPolicy"=dword:00000000
"RomeSdkChannelUserAuthzPolicy"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CrossDeviceResume\Configuration]
"IsOneDriveResumeAllowed"=dword:00000000
"IsResumeAllowed"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Mobility]
"CrossDeviceEnabled"=dword:00000000

$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"AllowClipboardHistory"=dword:00000000
"AllowCrossDeviceClipboard"=dword:00000000
"AllowCrossDeviceNotifications"=dword:00000000
"DisableAutomaticRestartSignOn"=dword:00000001
"DisableCrossDeviceResume"=dword:00000001
"EnableActivityFeed"=dword:00000000
"EnableCdp"=dword:00000000
"EnableCdpUserSvc"=dword:00000000
"EnableMmx"=dword:00000000
"PublishUserActivities"=dword:00000000
"UploadUserActivities"=dword:00000000
"@)
; ---

; Disable AutoPlay
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers]
"DisableAutoplay"=dword:00000001

; Disable suggested contents, Pre-installed apps, Lockscreen tips
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager]
"ContentDeliveryAllowed"=dword:00000000
"FeatureManagementEnabled"=dword:00000000
"OemPreInstalledAppsEnabled"=dword:00000000
"PreInstalledAppsEnabled"=dword:00000000
"PreInstalledAppsEverEnabled"=dword:00000000
"RotatingLockScreenEnabled"=dword:00000000
"RotatingLockScreenOverlayEnabled"=dword:00000000
"SilentInstalledAppsEnabled"=dword:00000000
"SlideshowEnabled"=dword:00000000
"SoftLandingEnabled"=dword:00000000
"SubscribedContentEnabled"=dword:00000000
"SystemPaneSuggestionsEnabled"=dword:00000000
$SubscribedContents

; Disable Shell Experience Host dashboard prelaunch
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Dsh]
"IsPrelaunchEnabled"=dword:00000000

; Show All Taskbar Icons and Hide Frequent Folders in Quick Access
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer]
"EnableAutoTray"=dword:00000000
"ShowFrequent"=dword:00000000

; Tune Start Menu and Taskbar
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"LaunchTo"=dword:00000001
"ShowSyncProviderNotifications"=dword:00000000
"ShowTaskViewButton"=dword:00000000
"Start_IrisRecommendations"=dword:00000000
"Start_Layout"=dword:00000001
"Start_TrackDocs"=dword:00000000
"TaskbarAl"=dword:00000000
"TaskbarMn"=dword:00000000

; Enable End Task in Taskbar right click menu
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings]
"TaskbarEndTask"=dword:00000001

; Disable Suggested Notifications
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested]
"Enabled"=dword:00000000

; Remove Meet Now
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
"HideSCAMeetNow"=dword:00000001

; Disable Suggested Actions
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard]
"Disabled"=dword:00000001

; Disable Account Notifications
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications]
"EnableAccountNotifications"=dword:00000000
"@)

; Disable Phone Companion
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start]
"RightCompanionToggledOpen"=dword:00000000

; Disable Finish Setting Up Your Device
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement]
"ScoobeSystemSettingEnabled"=dword:00000000

; --- Disable Widgets
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests]
"value"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh]
"AllowNewsAndInterests"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds]
"EnableFeeds"=dword:00000000
; ---

; Disable Maintenance
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance]
"MaintenanceDisabled"=dword:00000001

; Disable Driver Searching
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching]
"SearchOrderConfig"=dword:00000000

; Tune File Explorer
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer]
"ActiveSetupDisabled"=dword:00000000
"ActiveSetupTaskOverride"=dword:00000001
"AsyncRunOnce"=dword:00000001
"AsyncUpdatePCSettings"=dword:00000001
"DisableAppInstallsOnFirstLogon"=dword:00000001
"DisableResolveStoreCategories"=dword:00000001
"DisableUpgradeCleanup"=dword:00000001
"EarlyAppResolverStart"=dword:00000001
"HubMode"=dword:00000001
"MachineOobeUpdates"=dword:00000001
"MaxCachedIcons"="4096"
"NoWaitOnRoamingPayloads"=dword:00000001

; Disable Lock and Sleep
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings]
"ShowLockOption"=dword:00000000
"ShowSleepOption"=dword:00000000

$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DeliveryOptimization]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization]
"DODownloadMode"=dword:00000000
"@)

; Disable Settings Home
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer]
"SettingsPageVisibility"="hide:home"
"@)

; Disable Microsoft Edge features
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"BackgroundModeEnabled"=dword:00000000
"ComposeInlineEnabled"=dword:00000000
"CopilotCDPPageContext"=dword:00000000
"CopilotPageContext"=dword:00000000
"EdgeEntraCopilotPageContext"=dword:00000000
"EdgeHistoryAISearchEnabled"=dword:00000000
"GenAILocalFoundationalModelSettings"=dword:00000001
"HardwareAccelerationModeEnabled"=dword:00000000
"HubsSidebarEnabled"=dword:00000000
"NewTabPageBingChatEnabled"=dword:00000000
"NewTabPageContentEnabled"=dword:00000000
"NewTabPageHideDefaultTopSites"=dword:00000001
"StartupBoostEnabled"=dword:00000000

; Disable App Archiving
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Appx]
"AllowAutomaticAppArchiving"=dword:00000000

; Disable Windows Store automatic updates
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore]
"AutoDownload"=dword:00000002

; Detailed BSOD
[HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\CrashControl]
"DisplayParameters"=dword:00000001

; Enable Long Paths
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem]
"LongPathsEnabled"=dword:00000001

; Disable Remote Assistance
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Remote Assistance]
"fAllowFullControl"=dword:00000000
"fAllowToGetHelp"=dword:00000000
"fEnableChatControl"=dword:00000000

; Disable Maps Automatic Updates
[HKEY_LOCAL_MACHINE\SYSTEM\Maps]
"AutoUpdateEnabled"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (Features)"

# Registry tweaks (Gaming)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Tune Game Bar
[HKEY_CURRENT_USER\Software\Microsoft\GameBar]
"AllowAutoGameMode"=dword:0000000$($GameMode)
"AllowGameDVR"=dword:00000000
"AutoGameModeEnabled"=dword:0000000$($GameMode)
"GameModeEnabled"=dword:0000000$($GameMode)
"ShowGameBar"=dword:00000000
"ShowStartupPanel"=dword:00000000
"UseNexusForGameBarEnabled"=dword:00000000

; --- Disable Game DVR
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR]
"AppCaptureEnabled"=dword:00000000
"AudioCaptureEnabled"=dword:00000000
"CursorCaptureEnabled"=dword:00000000
"EchoCancellationEnabled"=dword:00000000
"HistoricalCaptureEnabled"=dword:00000000
"HistoricalCaptureOnBatteryAllowed"=dword:00000000
"HistoricalCaptureOnWirelessDisplayAllowed"=dword:00000000
"MicrophoneCaptureEnabled"=dword:00000000
"VKMSaveHistoricalVideo"=dword:00000000
"VKMTakeScreenshot"=dword:00000000
"VKMToggleBroadcast"=dword:00000000
"VKMToggleCameraCapture"=dword:00000000
"VKMToggleGameBar"=dword:00000000
"VKMToggleMicrophoneCapture"=dword:00000000
"VKMToggleRecording"=dword:00000000
"VKMToggleRecordingIndicator"=dword:00000000
"VKSaveHistoricalVideo"=dword:00000000
"VKTakeScreenshot"=dword:00000000
"VKToggleBroadcast"=dword:00000000
"VKToggleCameraCapture"=dword:00000000
"VKToggleGameBar"=dword:00000000
"VKToggleMicrophoneCapture"=dword:00000000
"VKToggleRecording"=dword:00000000
"VKToggleRecordingIndicator"=dword:00000000
"@)

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\GameDVR]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR]
"AllowGameDVR"=dword:00000000
"@)

[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000
; ---

"@
Write-Custom "Successfully modified registry settings (Gaming)"

# Registry tweaks (Input)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Disable Filter Keys
[HKEY_CURRENT_USER\Control Panel\Accessibility\Keyboard Response]
"AutoRepeatDelay"="0"
"AutoRepeatRate"="0"
"BounceTime"="0"
"DelayBeforeAcceptance"="0"
"Flags"="2"

; Disable Mouse Keys
[HKEY_CURRENT_USER\Control Panel\Accessibility\MouseKeys]
"Flags"="158"
"MaximumSpeed"="80"
"TimeToMaximumSpeed"="3000"

; Disable Sticky Keys
[HKEY_CURRENT_USER\Control Panel\Accessibility\StickyKeys]
"Flags"="2"

; Tune Cursor
[HKEY_CURRENT_USER\Control Panel\Cursors]
"AppStarting"=hex(2):00,00
"Arrow"=hex(2):00,00
"ContactVisualization"=dword:00000000
"Crosshair"=hex(2):00,00
"CursorBaseSize"=dword:00000000
"GestureVisualization"=dword:00000000
"Hand"=hex(2):00,00
"Help"=hex(2):00,00
"IBeam"=hex(2):00,00
"No"=hex(2):00,00
"NWPen"=hex(2):00,00
"Person"=hex(2):00,00
"Pin"=hex(2):00,00
"Scheme Source"=dword:00000000
"SizeAll"=hex(2):00,00
"SizeNESW"=hex(2):00,00
"SizeNS"=hex(2):00,00
"SizeNWSE"=hex(2):00,00
"SizeWE"=hex(2):00,00
"UpArrow"=hex(2):00,00
"Wait"=hex(2):00,00

; Tune Keyboard
[HKEY_CURRENT_USER\Control Panel\Keyboard]
"InitialKeyboardIndicators"="0"
"KeyboardDelay"="0"
"KeyboardSpeed"="31"
"PrintScreenKeyForSnippingEnabled"=dword:00000000

; Tune Mouse
[HKEY_CURRENT_USER\Control Panel\Mouse]
"ActiveWindowTracking"=dword:00000000
"Beep"="No"
"DoubleClickHeight"="4"
"DoubleClickSpeed"="500"
"DoubleClickWidth"="4"
"ExtendedSounds"="No"
"MouseHoverHeight"="4"
"MouseHoverTime"="10"
"MouseHoverWidth"="4"
"MouseSensitivity"="10"
"MouseSpeed"="0"
"MouseThreshold1"="0"
"MouseThreshold2"="0"
"MouseTrails"="0"
"SmoothMouseXCurve"=hex:00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
"SmoothMouseYCurve"=hex:00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
"SnapToDefaultButton"="0"
"SwapMouseButtons"="0"

; Disable Language Bar
[HKEY_CURRENT_USER\Software\Microsoft\CTF\LangBar]
"ExtraIconsOnMinimized"=dword:00000000
"Label"=dword:00000000
"ShowStatus"=dword:00000003
"Transparency"=dword:000000ff

; --- Disable Typing
[HKEY_CURRENT_USER\Software\Microsoft\input]
"IsInputAppPreloadEnabled"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\input\Settings]
"InsightsEnabled"=dword:00000000
"IsVoiceTypingKeyEnabled"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\input\TIPC]
"Enabled"=dword:00000000

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\InputPersonalization]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InputPersonalization]
"AllowInputPersonalization"=dword:00000000
"RestrictImplicitInkCollection"=dword:00000001
"RestrictImplicitTextCollection"=dword:00000001
"@)

[HKEY_CURRENT_USER\Software\Microsoft\InputPersonalization\TrainedDataStore]
"HarvestContacts"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Personalization\Settings]
"AcceptedPrivacyPolicy"=dword:00000000
; ---

; --- Disable Narrator
[HKEY_CURRENT_USER\Software\Microsoft\Narrator]
"CoupleNarratorCursorKeyboard"=dword:00000000
"EchoChars"=dword:00000000
"EchoWords"=dword:00000000
"ErrorNotificationType"=dword:00000000
"IntonationPause"=dword:00000000
"NarratorCursorHighlight"=dword:00000000
"ReadHints"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Narrator\NarratorHome]
"AutoStart"=dword:00000000
"MinimizeType"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Narrator\NoRoam]
"ContextVerbosityLevelV2"=dword:00000001
"DuckAudio"=dword:00000000
"EchoToggleKeys"=dword:00000000
"NarratorModifiers"=dword:00000002
"OnlineServicesEnabled"=dword:00000000
"RunningState"=dword:00000000
"ScriptingEnabled"=dword:00000000
"UserVerbosityLevel"=dword:00000001
"WinEnterLaunchEnabled"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Accessibility]
"NarratorAfterSigninResetCompleted"=dword:00000000
; ---

; Disable Screen Magnifier
[HKEY_CURRENT_USER\Software\Microsoft\ScreenMagnifier]
"FollowCaret"=dword:00000000
"FollowFocus"=dword:00000000
"FollowMouse"=dword:00000000
"FollowNarrator"=dword:00000000

; Disable Touch Keyboard
[HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7]
"EnableAutocorrection"=dword:00000000
"EnableAutoShiftEngage"=dword:00000000
"EnableDoubleTapSpace"=dword:00000000
"EnableKeyAudioFeedback"=dword:00000000
"EnableSpellchecking"=dword:00000000
"TipbandDesiredVisibility"=dword:00000000
"TouchKeyboardTapInvoke"=dword:00000000

; Disable Handwriting Error Reports
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\HandwritingErrorReports]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports]
"PreventHandwritingErrorReports"=dword:00000001

; Tune Keyboard Buffer Size
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters]
"KeyboardDataQueueSize"=dword:0000001e

; Tune Mouse Buffer Size
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\mouclass\Parameters]
"MouseDataQueueSize"=dword:0000001e

"@
Write-Custom "Successfully modified registry settings (Input)"

# Registry tweaks (Media)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; --- Tune DPI and Scaling
[-HKEY_CURRENT_USER\Control Panel\Desktop\PerMonitorSettings]

[HKEY_CURRENT_USER\Control Panel\Desktop]
"EnablePerProcessSystemDPI"=dword:00000000
"LogPixels"=dword:00000096
"MenuShowDelay"="0"
"Win8DpiScaling"=dword:00000000

[HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics]
"AppliedDPI"=dword:00000096
; ---

; Sound Communications Do Nothing
[HKEY_CURRENT_USER\Software\Microsoft\Multimedia\Audio]
"UserDuckingPreference"=dword:00000003

; Tune Video Playback
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\VideoSettings]
"AllowLowResolution"=dword:00000000
"EnableAutoEnhanceDuringPlayback"=dword:00000000
"VideoQualityOnBattery"=dword:00000001

; Tune Multimedia for Best Performance and Responsiveness
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"AlwaysOn"=dword:00000001
"LazyModeTimeout"=dword:00000000
"NetworkThrottlingIndex"=dword:ffffffff
"NoLazyMode"=dword:00000001
"SystemResponsiveness"=dword:00000000

; Audio Affinities and Priorities
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Audio]
"Affinity"=dword:00000003
"Background Only"="True"
"BackgroundPriority"=dword:00000006
"Clock Rate"=dword:00002710
"GPU Priority"=dword:00000008
"Latency Sensitive"="True"
"Priority"=dword:00000006
"Scheduling Category"="Medium"
"SFIO Priority"="Normal"

; Display Affinities and Priorities
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing]
"Affinity"=dword:00000000
"Background Only"="True"
"BackgroundPriority"=dword:00000018
"Clock Rate"=dword:00002710
"GPU Priority"=dword:00000012
"Latency Sensitive"="True"
"Priority"=dword:00000008
"Scheduling Category"="High"
"SFIO Priority"="High"

; Games Affinities and Priorities
$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency]
"Affinity"=dword:00000000
"Background Only"="False"
"BackgroundPriority"=dword:00000000
"Clock Rate"=dword:00002710
"GPU Priority"=dword:00000008
"Latency Sensitive"="True"
"Priority"=dword:00000006
"Scheduling Category"="High"
"SFIO Priority"="High"
"@)

; Disable Audio Enhancements
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio]
"DisableAudioEnhancements"=dword:00000001

; Disable Startup Sound
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation]
"DisableStartupSound"=dword:00000001

; Disable MPO (Multi-Plane Overlay)
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Dwm]
"OverlayTestMode"=dword:00000005

; Disable Windows Media Digital Rights Management
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WMDRM]
"DisableOnline"=dword:00000001

; Toggle Hardware-Accelerated GPU Scheduling and Increase Timeout Detection and Recovery
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers]
"HwSchMode"=dword:$('{0:x8}' -f ($HAGS + 1))
"TdrDelay"=dword:0000000a

; Disable Interrupt Steering
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PnP\Pci]
"DisableInterruptSteering"=dword:00000001

; Boosts Priority of Critical System Interrupts and CPU scheduling
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl]
"IRQ0Priority"=dword:00000001
"IRQ8Priority"=dword:00000001
"Win32PrioritySeparation"=dword:$('{0:x8}' -f $Win32PrioSep)

"@
Write-Custom "Successfully modified registry settings (Media)"

# Registry tweaks (Memory)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; --- Disable Storage Sense
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy]
"01"=dword:00000000

$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\StorageSense]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\StorageSense]
"AllowStorageSenseGlobal"=dword:00000000
"@)
; ---

; Disable Fault Tolerant Heap
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\FTH]
"Enabled"=dword:00000000

; Disable Service Host Splitting Threshold
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control]
"SvcHostSplitThresholdInKB"=dword:00000000

; Tune DPC and Timer Resolution
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\kernel]
"DpcTimeout"=dword:00000000
"GlobalTimerResolutionRequests"=dword:00000001
"SerializeTimerExpiration"=dword:00000000

; Disable Memory Compression, Paging Executive, Large System Cache
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"DisableCompression"=dword:00000001
"DisablePagingExecutive"=dword:00000001
"LargeSystemCache"=dword:00000000

; Disable Prefetch and Superfetch
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]
"EnablePrefetcher"=dword:00000000
"EnableSuperfetch"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (Memory)"

# Registry tweaks (Network)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Disable Internet Explorer Max Connections
$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER]
"explorer.exe"=dword:00000010
"iexplore.exe"=dword:00000010
"@)

; Disable Nagle's algorithm for MSMQ (Microsoft Message Queuing)
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters]
"TCPNoDelay"=dword:00000001

; Disable Network Discovery
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer]
"NoNetworkDiscovery"=dword:00000001

; Disable QoS Packet Scheduler bandwidth reservation limit
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Psched]
"NonBestEffortLimit"=dword:00000000

; Disable ICS (Internet Connection Sharing)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Network\SharedAccessConnection]
"EnableControl"=dword:00000000

; Tune TCP/UDP Buffer Sizes and Datagram Handling
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters]
"DefaultReceiveWindow"=dword:00000000
"DefaultSendWindow"=dword:00000000
"DynamicSendBufferDisable"=dword:00000001
"FastCopyReceiveThreshold"=dword:$('{0:x8}' -f $MTU)
"FastSendDatagramThreshold"=dword:$('{0:x8}' -f $MTU)

; Disable File and Printer Sharing
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer]
"NoFileAndPrinterSharing"=dword:00000001

; Disable File and Printer Sharing and Adjust Server Sizes
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters]
"AllowInsecureGuestAuth"=dword:00000000
"AutoShareServer"=dword:00000000
"AutoShareWks"=dword:00000000
"IRPStackSize"=dword:00000020
"RestrictNullSessAccess"=dword:00000001
"Size"=dword:00000003

; Disable Legacy NetBIOS Name Resolution via LMHOSTS File
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters]
"EnableLMHOSTS"=dword:00000000

; Tune TCP/IP settings
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters]
"DefaultTTL"=dword:00000040
"DisableDHCPMediaSense"=dword:00000000
"DisableIPSourceRouting"=dword:00000002
"DisableMediaSenseEventLog"=dword:00000001
"DisableTaskOffload"=dword:0000000$([int]($Offloads -le 0))
"DisableUserTOSSetting"=dword:00000001
"EnableAddrMaskReply"=dword:00000000
"EnableDeadGWDetect"=dword:00000000
"EnableICMPRedirect"=dword:00000000
"EnableMulticastForwarding"=dword:00000000
"EnablePMTUBHDetect"=dword:00000000
"EnablePMTUDiscovery"=dword:00000001
"GlobalMaxTcpWindowSize"=dword:$('{0:x8}' -f [uint32]$TWS)
"InitialRttData"=dword:$('{0:x8}' -f [uint32]$InitialRTO)
"KeepAliveTime"=dword:000493e0
"MaxConnectionsPerServer"=dword:00000000
"MaximumReassemblyHeaders"=dword:0000ffff
"MaxUserPort"=dword:0000fffe
"PortTrackerEnabledMode"=dword:00000000
"SackOpts"=dword:00000001
"StrictTimeWaitSeqCheck"=dword:00000001
"Tcp1323Opts"=dword:0000000$($TCPOptions)
"TcpMaxConnectRetransmissions"=dword:0000000$($TCPRetries)
"TcpMaxDataRetransmissions"=dword:0000000$($TCPRetries)
"TcpMaxDupAcks"=dword:0000000$($TCPRetries)
"TcpNumConnections"=dword:00fffffe
"TcpTimedWaitDelay"=dword:0000001e
"TcpWindowSize"=dword:$('{0:x8}' -f [uint32]$TWS)

; Prevents QoS From Using Network Location Awareness
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\QoS]
"Do not use NLA"="1"

; Sets Priority Order for Hostname Resolution Methods
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider]
"DnsPriority"=dword:00000006
"HostsPriority"=dword:00000005
"LocalPriority"=dword:00000004
"NetbtPriority"=dword:00000007

; Prefer IPv4 over IPv6
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters]
"DisabledComponents"=dword:00000020

; Tune Winsock
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock]
"MaxSockAddrLength"=dword:00000010
"MinSockAddrLength"=dword:00000010
"OfflineCapable"=dword:00000000
"UseDelayedAcceptance"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (Network)"

# Registry tweaks (Power)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Disable Modern Standby Networking
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Power\PowerSettings\f15576e8-98b7-4186-b944-eafa664402d9]
"ACSettingIndex"=dword:00000000
"DCSettingIndex"=dword:00000000

; Disable Power Saving features
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power]
"CsEnabled"=dword:00000000
"EcoQosDisabled"=dword:00000001
"EnableEcoQoS"=dword:00000000
"EnergyEstimationEnabled"=dword:00000000
"HibernateEnabled"=dword:00000000
"HibernateEnabledDefault"=dword:00000000
"SleepReliabilityDetailedDiagnostics"=dword:00000000

; Disable Power Throttling
$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power]
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling]
"PowerThrottlingOff"=dword:00000001
"@)

; Set Power Mode to Best Performance
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes]
"ActiveOverlayAcPowerScheme"="ded574b5-45a0-4f42-8737-46345c09c238"

; Disable Hiberboot
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power]
"HiberbootEnabled"=dword:00000000

; Disable USB Selective Suspend
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USB]
"DisableSelectiveSuspend"=dword:00000001

"@
Write-Custom "Successfully modified registry settings (Power)"

# Registry tweaks (Security)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Disable App & browser control > Reputation-based protection > SmartScreen for Microsoft Edge
[HKEY_CURRENT_USER\Software\Microsoft\Edge\SmartScreenEnabled]
@=dword:00000000

; Disable App & browser control > Reputation-based protection > Potentially unwanted app blocking
[HKEY_CURRENT_USER\Software\Microsoft\Edge\SmartScreenPuaEnabled]
@=dword:00000000

; Disable App & browser control > Reputation-based protection > SmartScreen for Microsoft Store Apps
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AppHost]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost]
"EnableWebContentEvaluation"=dword:00000000
"PreventOverride"=dword:00000000
"@)

; Disable Security Health warnings - the "dismisses" that shows on Defender (keep values at 0)
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows Security Health\State]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Security Health\State]
"AppAndBrowser_AppRepSmartScreenOff"=dword:00000000
"AppAndBrowser_EdgeSmartScreenOff"=dword:00000000
"AppAndBrowser_PhishingSensorsOff"=dword:00000000
"AppAndBrowser_PuaSmartScreenOff"=dword:00000000
"AppAndBrowser_StoreAppsSmartScreenOff"=dword:00000000
"Defender_AutoSampleSubmissionDisabled"=dword:00000000
"DefenderPua_PuaDisabled"=dword:00000000
"Hardware_HVCI_Off"=dword:00000000
"@)

; Disable App & browser control > Reputation-based protection > Check apps and files
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer]
"SmartScreenEnabled"="Off"

; Limit Windows Defender CPU Usage
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Scan]
"AvgCPULoadFactor"=dword:00000019
"ScanAvgCPULoadFactor"=dword:00000019

; Disable App & browser control > Smart App Control
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CI\Policy]
"EmodePolicyRequired"=dword:00000000
"SkuPolicyRequired"=dword:00000000
"VerifiedAndReputablePolicyState"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (Security)"

# Registry tweaks (Telemetry)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; --- Disable Let websites show me locally relevant content by accessing my language list
[HKEY_CURRENT_USER\Control Panel\International\User Profile]
"HttpAcceptLanguageOptOut"=dword:00000001

]HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\SyncSettings]
"UseLanguageList"=dword:00000000
; ---

; --- Disable Media Player tracking and retrievals
[HKEY_CURRENT_USER\Software\Microsoft\MediaPlayer\Preferences]
"UsageTracking"=dword:00000000

[HKEY_CURRENT_USER\Software\Policies\Microsoft\WindowsMediaPlayer]
"PreventCDDVDMetadataRetrieval"=dword:00000001
"PreventMusicFileMetadataRetrieval"=dword:00000001
"PreventRadioPresetsRetrieval"=dword:00000001
; ---

; Set Feedback Frequency to Never
[HKEY_CURRENT_USER\Software\Microsoft\Siuf\Rules]
"NumberOfSIUFInPeriod"=dword:00000000
"PeriodInNanoSeconds"=-

; --- Disable Online Speech Recognition
[HKEY_CURRENT_USER\Software\Microsoft\Speech_OneCore\Preferences]
"ModelDownloadAllowed"=dword:00000000
"VoiceActivationEnableAboveLockscreen"=dword:00000000
"VoiceActivationOn"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy]
"HasAccepted"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Preferences]
"VoiceActivationDefaultOn"=dword:00000000
; ---

; --- Disable Let Apps use Advertising ID for Relevant Ads
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo]
"Enabled"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo]
"DisabledByGroupPolicy"=dword:00000001
; ---

; --- Disable Spotlight and Consumer Features
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings]
"EnabledState"=dword:00000000

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CloudContent]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent]
"DisableCloudOptimizedContent"=dword:00000001
"DisableConsumerAccountStateContent"=dword:00000001
"DisableSoftLanding"=dword:00000001
"DisableSpotlightCollectionOnDesktop"=dword:00000001
"DisableTailoredExperiencesWithDiagnosticData"=dword:00000001
"DisableWindowsConsumerFeatures"=dword:00000001
"DisableWindowsSpotlightFeatures"=dword:00000001
"@)
; ---

; --- Disable recommended, most frequently used and recently added apps
$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer]
"ShowRecommendations"=dword:00000000
"@)

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"Start_AccountNotifications"=dword:00000000
"Start_JumpListItems"=dword:00000000
"Start_ShowRecentDocs"=dword:00000000
"Start_ShowRecentlyAdded"=dword:00000000
"Start_TrackDocs"=dword:00000000
"Start_TrackProgs"=dword:00000000
"@)

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Start]
"ShowRecentList"=dword:00000000
"@)

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer]
"DisableStartupGrouping"=dword:00000001
"HideRecentlyAddedApps"=dword:00000001
"HideRecommendedSection"=dword:00000001
"NoInstrumentation"=dword:00000001
"NoStartMenuMFUprogramsList"=dword:00000001
"ShowOrHideMostUsedApps"=dword:00000002
"@)

$(Split-Registry -Content @"
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\EdgeUI]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\EdgeUI]
"DisableMFUTracking"=dword:00000001
"@)

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\current\device\Start]
"HideRecommendedSection"=dword:00000001
; ---

; Send only Required Diagnostic and Usage Data
$(Split-Registry -Content @"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection]
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"AllowCommercialDataPipeline"=dword:00000000
"AllowDesktopAnalyticsProcessing"=dword:00000000
"AllowDeviceNameInTelemetry"=dword:00000000
"AllowTelemetry"=dword:00000000
"AllowUpdateComplianceProcessing"=dword:00000000
"AllowWUfBCloudProcessing"=dword:00000000
"DisableOneSettingsDownloads"=dword:00000001
"DoNotShowFeedbackNotifications"=dword:00000001
"LimitDiagnosticLogCollection"=dword:00000001
"MaxTelemetryAllowed"=dword:00000000
"MicrosoftEdgeDataOptIn"=dword:00000000
"@)

; Disable Out-of-Box Experience
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE]
"DisablePrivacyExperience"=dword:00000001
"DisableVoice"=dword:00000001
"SkipMachineOOBE"=dword:00000001
"SkipUserOOBE"=dword:00000001

; Disable Tailored experiences with diagnostic data for Current User
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Privacy]
"TailoredExperiencesWithDiagnosticDataEnabled"=dword:00000000

; Disable Personalization of Ads
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"PersonalizationReportingEnabled"=dword:00000000

; Disable Customer Experience Improvement Program
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\SQMClient\Windows]
"CEIPEnable"=dword:00000000

; Disable License Checking
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform]
"NoGenTicket"=dword:00000001

; Disable Activity History
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System]
"PublishUserActivities"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (Telemetry)"

# Registry tweaks (VBS)
Set-Registry -Content @"
Windows Registry Editor Version 5.00

; Disable VBS (Virtualization Based Security)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard]
"CachedDrtmAuthIndex"=dword:00000000
"EnableVirtualizationBasedSecurity"=dword:00000000
"HyperVVirtualizationBasedSecurityOptout"=dword:00000000
"RequireMicrosoftSignedBootChain"=dword:00000000
"RequirePlatformSecurityFeatures"=dword:00000000
"WasEnabledBy"=dword:00000000

; Disable Credential Guard (Windows 10)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard]
"Enabled"=dword:00000000

; Disable HVCI (Hypervisor Enforced Code Integrity)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity]
"Enabled"=dword:00000000
"EnabledBootId"=dword:00000000

; Disable Kernel Shadow Stacks
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks]
"AuditModeEnabled"=dword:00000000
"Enabled"=dword:00000000

; Disable Key Guard (Windows 11)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KeyGuard\Status]
"CredGuardEnabled"=dword:00000000
"EncryptionKeyAvailable"=dword:00000000
"EncryptionKeyPersistent"=dword:00000000
"ExecSystemProcessesError"=dword:00000000
"IsSecureKernelRunning"=dword:00000000
"IsTestConfig"=dword:00000000
"KeyGuardEnabled"=dword:00000000
"LsaIsoLaunchAttempted"=dword:00000000
"LsaIsoLaunchError"=dword:00000000
"NumAttemptedRestarts"=dword:00000000
"NumSuccessfulRestarts"=dword:00000000
"SecretsMode"=dword:00000000

"@
Write-Custom "Successfully modified registry settings (VBS)"

# Network settings task
New-Task -Name "ZeroLatency (netsh)" -Command $NetshCommands
Write-Custom "Successfully created a task with netsh commands"

# Network adapters restart
Get-NetAdapter -Physical | ForEach-Object { Restart-NetAdapter -Name "$($_.Name)" }
Write-Custom "Successfully restarted all physical network adapters"

# Final message
Write-Host "`n`e[1;35mScript complete! Restart recommended to apply all changes`n`nPress any key to exit...`e[0m"
$Null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# End logging
Stop-Transcript
