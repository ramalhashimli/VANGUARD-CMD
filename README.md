<p align="center">
<pre>
 ╦  ╦╔═╗╔╗╔╔═╗╦ ╦╔═╗╦═╗╔╦╗   ╔═╗╔╦╗╔╦╗
 ╚╗╔╝╠═╣║║║║ ╦║ ║╠═╣╠╦╝ ║║───║  ║║║ ║║
  ╚╝ ╩ ╩╝╚╝╚═╝╚═╝╩ ╩╩╚══╩╝   ╚═╝╩ ╩═╩╝
         Enterprise System Hardening Framework
</pre>
</p>

<p align="center">
  <strong>Zero-dependency Windows hardening and optimization in a single .cmd file</strong>
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/install-10_seconds-brightgreen?style=flat-square" alt="Install"></a>
  <a href="#"><img src="https://img.shields.io/badge/powershell-ZERO-red?style=flat-square" alt="No PowerShell"></a>
  <a href="#"><img src="https://img.shields.io/badge/dependencies-ZERO-blue?style=flat-square" alt="Zero Deps"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-Windows%2010%2F11%20%7C%20Server-orange?style=flat-square" alt="Platform"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License"></a>
</p>

---

## What It Does

VANGUARD-CMD audits and hardens a Windows system in a single pass. It checks for known vulnerable configurations, applies security best practices, optimizes network and disk performance, and neutralizes telemetry — all using **native `cmd.exe` commands only**.

No PowerShell. No Python. No installers. No agents. Copy one file, right-click, run as administrator.

---

## Modules

### Module 1: Security Hardening & Audit

| Check | Action | Method |
|---|---|---|
| SMBv1 Server protocol | Detect & disable | `reg` query/add on LanmanServer\Parameters |
| SMBv1 Client driver | Detect & disable | `sc` config mrxsmb10 |
| NetBIOS over TCP/IP | Disable on all interfaces | `reg` iterate NetBT\Parameters\Interfaces |
| NTLM authentication | Enforce NTLMv2 only (Level 5) | `reg` Lsa\LmCompatibilityLevel |
| Windows Defender Cloud Protection | Enable Advanced mode | `reg` Windows Defender\Spynet |
| Windows Defender PUA Blocking | Enable | `reg` PUAProtection |
| Windows Defender Behavior Monitoring | Verify enabled | `reg` Real-Time Protection |
| Defender Real-Time Protection | Verify running | `sc` query WinDefend |
| Firewall (Domain/Private/Public) | Verify all ON | `netsh advfirewall` |
| Telemetry outbound firewall rule | Block known IPs | `netsh advfirewall firewall` |
| UAC | Verify enabled | `reg` Policies\System\EnableLUA |
| AutoRun/AutoPlay | Disable all drives | `reg` NoDriveTypeAutoRun = 0xFF |
| RDP Network Level Authentication | Enforce | `reg` WinStations\RDP-Tcp |
| Remote Assistance | Disable | `reg` fAllowToGetHelp = 0 |

### Module 2: System Optimization

| Action | Method |
|---|---|
| Clear user TEMP directory | `del` + `rd` |
| Clear system TEMP directory | `del` + `rd` |
| Clear Windows Update download cache | `net stop wuauserv` + `del` + `net start` |
| Clear Prefetch cache | `del` on `%SystemRoot%\Prefetch` |
| DISM component store cleanup | `dism /online /cleanup-image /startcomponentcleanup` |
| Flush DNS resolver cache | `ipconfig /flushdns` |
| Flush ARP cache | `netsh interface ip delete arpcache` |
| TCP auto-tuning level → normal | `netsh int tcp set global` |
| Enable Receive Side Scaling (RSS) | `netsh int tcp set global` |
| Disable TCP timestamps | `netsh int tcp set global` |
| Enable ECN capability | `netsh int tcp set global` |
| Set telemetry level → Security (0) | `reg` DataCollection\AllowTelemetry |
| Disable feedback notifications | `reg` DoNotShowFeedbackNotifications |
| Disable DiagTrack service | `sc stop` + `sc config start= disabled` |
| Disable WAP Push service | `sc stop` + `sc config start= disabled` |
| Disable CEIP scheduled tasks | `schtasks /change /disable` |

---

## Quick Start

**Option A — Download and run:**

```cmd
curl -sL https://raw.githubusercontent.com/ramalhashimli/VANGUARD-CMD/master/vanguard.cmd -o vanguard.cmd
```

Then right-click `vanguard.cmd` → **Run as administrator**.

**Option B — Clone:**

```cmd
git clone https://github.com/ramalhashimli/VANGUARD-CMD.git
cd VANGUARD-CMD
```

Right-click `vanguard.cmd` → **Run as administrator**.

---

## Requirements

- Windows 10 / 11 Enterprise (build 1607+ for ANSI color support)
- Windows Server 2016 / 2019 / 2022
- **Must run as Administrator**
- No PowerShell, no .NET, no third-party tools

---

## Terminal Output Preview

```
  +==============================================================================+
  |                                                                              |
  |       V A N G U A R D  -  C M D     v1.0.0                                 |
  |       Enterprise System Hardening & Optimization Framework                   |
  |                                                                              |
  +==============================================================================+

  Host: WIN-SRV01  |  2026-05-20 14:32:01  |  Log: C:\VanguardCMD\logs\...

  +------------------------------------------------------------------------------+
  |  MODULE 1: SECURITY HARDENING & AUDIT                                        |
  +------------------------------------------------------------------------------+

  --- 1.1 Protocol Security ---

  [+]  SMBv1 Server Protocol           : Disabled
  [-]  SMBv1 Client Driver              : Disabled (was enabled)
  [-]  NetBIOS over TCP/IP             : Disabled on 2 interface(s)
  [+]  NTLM Authentication             : NTLMv2 only (Level 5)

  --- 1.2 Windows Defender Hardening ---

  [-]  Defender Cloud Protection        : Enabled (Advanced)
  [+]  Defender PUA Blocking            : Enabled
  [+]  Defender Behavior Monitoring     : Enabled (default)
  [+]  Defender Real-Time Protection    : Running

  --- 1.3 Firewall Verification ---

  [+]  Firewall Domain Profile         : ON
  [+]  Firewall Private Profile        : ON
  [~]  Firewall Public Profile         : OFF
  [-]  Telemetry Outbound Rule         : Created (known telemetry IPs blocked)

  --- 1.4 System Security Posture ---

  [+]  UAC (User Account Control)      : Enabled
  [-]  AutoRun/AutoPlay                : Disabled (all drives)
  [+]  RDP Network Level Authentication: Enabled
  [+]  Remote Assistance               : Disabled

  +------------------------------------------------------------------------------+
  |  MODULE 2: SYSTEM OPTIMIZATION                                               |
  +------------------------------------------------------------------------------+

  --- 2.1 Disk & Cache Cleanup ---

  [-]  User TEMP Directory             : Cleaned
  [-]  System TEMP Directory           : Cleaned
  [-]  Windows Update Cache            : Cleaned
  [-]  Prefetch Cache                  : Cleaned
  [*]  DISM Component Cleanup          : Running (may take several minutes)...
  [-]  DISM Component Cleanup          : Completed
  [-]  DNS Resolver Cache              : Flushed
  [-]  ARP Cache                       : Flushed

  --- 2.2 TCP/IP Stack Optimization ---

  [-]  TCP Auto-Tuning Level           : Set to normal
  [-]  Receive Side Scaling (RSS)      : Enabled
  [-]  TCP Timestamps                  : Disabled (reduced overhead)
  [-]  ECN Capability                  : Enabled

  --- 2.3 Telemetry & Privacy ---

  [-]  Telemetry Level                 : Set to Security (minimum)
  [-]  Feedback Notifications          : Disabled
  [-]  DiagTrack Service               : Stopped and disabled
  [+]  WAP Push Service                : Already disabled
  [-]  CEIP Scheduled Tasks            : Disabled

  +==============================================================================+
  |  SCAN COMPLETE                                                               |
  |  Total: 30  |  Passed: 14  |  Fixed: 14  |  Warnings: 1  |  Failed: 1      |
  |  Note: Some changes require a system restart to take effect.                 |
  +==============================================================================+
```

**Legend:**

| Tag | Meaning | Color |
|-----|---------|-------|
| `[+]` | Passed — already secure | Green |
| `[-]` | Fixed — action was taken | Magenta |
| `[~]` | Warning — review required | Yellow |
| `[x]` | Failed — could not remediate | Red |
| `[*]` | Info — no action needed | Cyan |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed or fixed |
| `1` | Completed with warnings |
| `2` | Critical failures found |
| `3` | Not running as Administrator |

---

## What This Script Modifies

> **Read this before running in production.**

This script makes **real changes** to the system. Specifically:

- **Registry modifications:** SMBv1, NetBIOS, NTLM, Defender, UAC, AutoRun, RDP NLA, Remote Assistance, Telemetry settings
- **Service state changes:** DiagTrack, dmwappushservice stopped and set to disabled
- **Firewall rules:** One outbound block rule added for known telemetry IPs
- **Scheduled tasks:** CEIP tasks disabled
- **File deletions:** TEMP, Prefetch, Windows Update download cache
- **Network stack:** TCP/IP global parameters adjusted via netsh

All changes are logged to `C:\VanguardCMD\logs\`. Review the log to see exactly what was changed.

**Recommendation:** Test on a non-production system first. Some changes (SMBv1 disable, NetBIOS disable, NTLM Level 5) can affect legacy application compatibility.

---

## Repository Structure

```
VANGUARD-CMD/
├── README.md
├── LICENSE
├── .gitignore
└── vanguard.cmd         # The entire framework — single file, zero dependencies
```

---

## FAQ

**Q: Does this phone home or send telemetry?**
A: No. The script only reads and writes to the local system. The only network operations are DNS flush and ARP cache clear.

**Q: Can I undo the changes?**
A: Registry changes can be reverted by setting the values back. Service changes can be reverted with `sc config <service> start= auto`. The log file documents every change made.

**Q: Why no PowerShell?**
A: PowerShell execution policies, version fragmentation, and AMSI interference make it unreliable for air-gapped or locked-down environments. Native `cmd.exe` runs everywhere, every time.

**Q: Does it work on Windows Server Core?**
A: Yes. All commands used are available in Server Core installations.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built for the admins who harden at scale.</sub>
</p>
