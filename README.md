# ZeroLatency

[![Windows Compatibility: 11](https://img.shields.io/badge/Windows-11-blue.svg)](https://www.microsoft.com/en-us/software-download/windows11)
[![PowerShell Compatibility: 7](https://img.shields.io/badge/PowerShell-7-blue.svg)](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/ceferrari/ZeroLatency.svg?style=social)](https://github.com/ceferrari/ZeroLatency)

**ZeroLatency** is a highly opinionated PowerShell script for Windows that prioritizes maximum system responsiveness and lowest possible latency above all else. Tailored for gamers, audio professionals, and users with real-time workloads, it aggressively debloats Windows by removing pre-installed packages, AI, accessibility, and gaming overlays. It disables unnecessary services, telemetry, indexing, and power-saving features. It primarily optimizes network and power settings, including a custom power plan. While prioritizing performance over security and power efficiency, it preserves essential functionality including Windows Defender, Windows Update, Microsoft Store, and WSL (Windows Subsystem for Linux), the latter being a key feature for developers.

In addition to the provided information, the script is not intended for every user or scenario. It is specifically designed for Windows 11 and has not been tested on any other versions. The network optimizations assume a stable, high-quality link, such as fiber, and may not be as effective on unstable or low-quality connections. Users who require high throughput for tasks like simultaneous streaming while gaming may need to tweak the script to suit their specific needs. The script also does not focus on security hardening; for that purpose, users should look into specialized tools like the [Harden Windows Security](https://github.com/HotCakeX/Harden-Windows-Security). Furthermore, while the script will undoubtedly improve gaming performance, its primary goal is to achieve minimum latency, not to maximize raw FPS.

## ⚠️ Disclaimer

This script makes significant modifications to your Windows system configuration. Use it at your own risk. We are not responsible for any instability, data loss, security vulnerabilities, hardware damage, or any other issues that may result from using this script. It is highly recommended to create a system restore point before proceeding.

## 📋 Prerequisites

- [Windows 11](https://www.microsoft.com/en-us/software-download/windows11)
  - A clean installation of Windows 11 is strongly recommended for the best results. Using it on an earlier version or an already existing installation increases the risk of issues
  - After the installation, ensure your system is fully updated through both Windows Update and the Microsoft Store before running the script
  - We suggest using [Rufus](https://rufus.ie) to create a bootable USB from the official ISO and customize it to use an offline local account instead of requiring an online Microsoft account
- [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
  - The script relies on features exclusive to PowerShell version 7 or newer and is not compatible with the version 5 that comes pre-installed with Windows
  - The recommended method by Microsoft to install it is via WinGet, simply running the following command on Terminal (PowerShell or Command Prompt)
    ```powershell
    winget install --id Microsoft.PowerShell --source winget
    ```

## 🚀 Usage

### Default

1. Install or update to the latest version of NIC drivers
    - [Realtek](https://www.realtek.com/Download/List?cate_id=584) (select NDIS - Not Support Power Saving)
    - [Intel](https://www.intel.com/content/www/us/en/download/15084/intel-ethernet-adapter-complete-driver-pack.html)
2. Download the [ZeroLatency.ps1](https://raw.githubusercontent.com/ceferrari/ZeroLatency/refs/heads/main/ZeroLatency.ps1) file (Right click > Save link as...)
3. Run the following command to unblock the script (won't work on Command Prompt, only PowerShell)
    ```powershell
    Unblock-File -Path "C:\Path\To\ZeroLatency.ps1"
    ```
4. Open the file using a text editor (e.g., Notepad or VSCode)
5. Go through each step, change the variables and save the file
6. Execute the script by double-clicking the file and accepting the UAC prompt
    - You may need to associate `.ps1` files with PowerShell 7 when running it for the first time
    - PowerShell 7 executable is usually located at `C:\Program Files\PowerShell\7\pwsh.exe`
7. Check the [Extra](#-extra) section for further optimizations (optional but highly recommended)

### (WIP) Reset

1. Download the [ZeroLatencyReset.ps1](https://raw.githubusercontent.com/ceferrari/ZeroLatency/refs/heads/main/ZeroLatencyReset.ps1) file (Right click > Save link as...)
2. Run the following command to unblock the script (won't work on Command Prompt, only PowerShell)
    ```powershell
    Unblock-File -Path "C:\Path\To\ZeroLatencyReset.ps1"
    ```
3. Execute the script by double-clicking the file and accepting the UAC prompt

## 🛠️ Fixes

### TCP Autotuning

To achieve high ratings on the Bufferbloat test, this script disables `TCP Autotuning`. This is a strategic choice to prioritize low latency and stable ping times under heavy network load, which is the core metric of the Bufferbloat grade. By limiting the maximum TCP buffer size, we prevent the buildup of excessive queues in your router, eliminating the bloat and the lag it causes, even when your connection is saturated. This latency-focused configuration comes with a potential trade-off: a reduction in maximum raw throughput (speed) on high-bandwidth, high-latency connections. If you find the reduction in raw speed undesirable, or if an A+ rating is not a priority for your use case, we recommend reverting this tweak to restore your connection's full throughput potential, by running the following command in an elevated Terminal (PowerShell or Command Prompt)
```powershell
netsh int tcp set global autotuninglevel=normal
```
### Interrupt Steering Mode
If, for whatever reason, you choose not to follow the recommendation of configuring your interrupt affinities using the [Go Interrupt Policy](#go-interrupt-policy) application, even though it is likely the most effective optimization available, you will need to adjust the hidden `Interrupt Steering Mode` setting on the ZeroLatency custom power plan. By default, this setting can be configured to `Lock Interrupt Routing` in order to minimize the overhead of switching cores. However, since you will not be manually distributing interrupts across specific cores in this scenario, it is advisable to change this setting to its default value, allowing Windows to handle interrupt routing automatically, by running the following command in an elevated Terminal (won't work on Command Prompt, only PowerShell)
```powershell
powercfg /setacvalueindex ([regex]::Match((powercfg /list | Select-String "ZeroLatency" | Select -First 1), "[0-9a-fA-F-]{36}").Value) "48672f38-7a9a-4bb2-8bf8-3d85be19de4e" "2bfc24f9-5ea2-4801-8213-3dbae01aa39d" 0
```

## 🧩 Extra

ZeroLatency focuses on maximizing system responsiveness and minimizing latency through automated tweaks, but there are additional tools that can complement its effects. These tools further enhance optimizations that are highly system-specific, hardware-dependent, or otherwise impractical to replicate fully within a single script. For example, utilities like MSI-specific tuning software provide granular control over interrupt handling and core assignment across diverse hardware configurations. Using them alongside this script can help achieve even lower latency and a more finely tuned system without duplicating effort.

### [Process Lasso](https://bitsum.com)

Aadvanced software for Windows that optimizes system responsiveness and stability by intelligently managing process priorities and CPU affinities. Its primary function is to prevent system stalls and maintain smooth performance under high load by dynamically adjusting how processes utilize CPU resources, offering both automated optimization and granular manual control.

<details>
  <summary>Expand to check the recommended configuration</summary>

  - Settings
    - Main > [ (✓) ProBalance Enabled, ( ) SmartTrim Enabled, ( ) IdleSaver Enabled ]
    - Options > Power > Start Process Lasso with Power Profile > ZeroLatency
    - Options > General > Refresh Interval (GUI) > 5 seconds
    - Options > General > Refresh Interval (Governor) > 5 seconds
    - Options > CPU > Efficiency Modes... > [ Process match: *, Efficiency mode: Off, Add Rule ]
    - Options > CPU > Dynamic Thread Priority Boosts... > [ Process match: *, Dynamic thread priority boosts: Off, Add Rule ]
    - Options > CPU > CPU Affinities... > [ Process match: audiodg.exe, CPU affinity: \<Select A\>, Add Rule ]
    - Options > CPU > CPU Affinities... > [ Process match: dwm.exe, CPU affinity: \<Select A\>, Add Rule ]
    - Options > CPU > CPU Affinities... > [ Process match: \<Your Process\>, CPU affinity: \<Select B\>, Add Rule ]
  - Glossary
    - \<Select A\>: Select the first physical core (e.g., if you have HT/SMT on, select 0 and 1, otherwise just 0)
    - \<Select B\>: Select all remaining cores (e.g., if you have HT/SMT on and 6 cores, select 2 through 11)
    - \<Your Process\>: Replace with the name of the process you want to exclude from first core (e.g., your game executable)

</details>

### [Go Interrupt Policy](https://github.com/spddl/GoInterruptPolicy)

Modern and comprehensive utility, serving as a robust replacement for legacy tools such as [Interrupt Affinity Tool](https://www.techpowerup.com/download/microsoft-interrupt-affinity-tool) and [MSI Tool](https://forums.guru3d.com/threads/windows-line-based-vs-message-signaled-based-interrupts-msi-tool.378044), providing a unified solution for optimizing device interrupts on Windows. Its primary function is to manage Message Signaled Interrupts (MSI), a more efficient, lower-latency alternative to traditional line-based interrupts, by allowing users to control interrupt priorities and assign specific CPU cores affinities for handling device interrupts.

<details>
  <summary>(WIP) Expand to check the recommended configuration</summary>
</details>

### [Custom Resolution Utility](https://www.monitortests.com/forum/Thread-Custom-Resolution-Utility-CRU)

Sspecialized tool designed to extend the capabilities of your display hardware by allowing users to create custom resolutions, refresh rates, and timing parameters. It provides precise control over monitor settings beyond standard driver options, enabling optimized visual performance and compatibility with non-standard displays or configurations.

<details>
  <summary>(WIP) Expand to check the recommended configuration</summary>
</details>

## 📈 Results

### [Bufferbloat](https://www.waveform.com/tools/bufferbloat)

<details>
  <summary>Result obtained from a fiber connection in Brazil and without an SQM router</summary>
  <img width="1228" height="1024" alt="Result_Bufferbloat" src=".github/images/Result_Bufferbloat.png" />
</details>

### [LatencyMon](https://www.resplendence.com/latencymon)

<details>
  <summary>Result obtained after three consecutive Arms Race matches in Counter Strike 2</summary>
  <img width="1228" height="1024" alt="Result_LatencyMon" src=".github/images/Result_LatencyMon.png" />
</details>

### [MouseTester](https://www.overclock.net/threads/mousetester-software-reloaded.1590569)

<details>
  <summary>Result obtained with a Razer DeathAdder V2 Pro on wireless mode and 1600dpi</summary>
  <img width="1228" height="1024" alt="Result_MouseTester" src=".github/images/Result_MouseTester.png" />
</details>

## 🤝 Contributing

Contributions are welcome! 🎉

- Open an issue to report bugs or suggest improvements
- Fork the repository and submit a Pull Request for new features or fixes

## ❤️ Supporting

If you find this project useful, please consider tipping any amount to support the development!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G51KLB1L)

## 💡 Inspirations

This project was made possible thanks to the work of others who have explored similar areas of Windows tuning and performance optimization. The following scripts and tools served as valuable references and inspiration. While the implementation here is highly opinionated, these resources influenced certain ideas, approaches, and techniques.

- [Win11Debloat](https://github.com/Raphire/Win11Debloat)
- [WinScript](https://github.com/flick9000/winscript)
- [WinUtil](https://github.com/ChrisTitusTech/winutil)
- [WinFix](https://github.com/fivance/WinFix)
- [Aurora](https://github.com/IBRHUB/Aurora)
- [ZOICWARE](https://github.com/zoicware/ZOICWARE)
- [Khorvie Tech](https://github.com/Khorvie-Tech)
- [TCP Optimizer](https://www.speedguide.net/downloads.php)
