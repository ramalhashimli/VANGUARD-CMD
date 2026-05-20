@echo off
:: =============================================================================
:: VANGUARD-CMD v1.0.0
:: Enterprise System Hardening & Optimization Framework
:: 100% Native Windows Batch | Zero Dependencies | Zero PowerShell
:: =============================================================================

setlocal EnableExtensions EnableDelayedExpansion

set "VER=1.0.0"

:: ---------------------------------------------------------------------------
:: ANSI COLOR SETUP (requires Windows 10 build 1607+ for VT100 support)
:: Generate the ESC character (0x1B) using the prompt technique
:: ---------------------------------------------------------------------------
for /F %%e in ('echo prompt $E ^| cmd') do set "E=%%e"

:: Color definitions
set "CR=!E![31m"
set "CG=!E![32m"
set "CY=!E![33m"
set "CB=!E![34m"
set "CM=!E![35m"
set "CC=!E![36m"
set "CW=!E![97m"
set "CD=!E![90m"
set "BW=!E![1;97m"
set "BC=!E![1;36m"
set "C0=!E![0m"

:: ---------------------------------------------------------------------------
:: TIMESTAMP (locale-safe via WMIC)
:: ---------------------------------------------------------------------------
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%a"
set "DDATE=!DT:~0,4!-!DT:~4,2!-!DT:~6,2!"
set "DTIME=!DT:~8,2!:!DT:~10,2!:!DT:~12,2!"
set "FSTAMP=!DT:~0,8!_!DT:~8,2!!DT:~10,2!!DT:~12,2!"

:: ---------------------------------------------------------------------------
:: LOG FILE
:: ---------------------------------------------------------------------------
set "LOG_DIR=%SYSTEMDRIVE%\VanguardCMD\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!" 2>nul
set "LOG=!LOG_DIR!\vanguard_!FSTAMP!.log"

:: ---------------------------------------------------------------------------
:: HOSTNAME
:: ---------------------------------------------------------------------------
set "HOST=%COMPUTERNAME%"

:: ---------------------------------------------------------------------------
:: COUNTERS
:: ---------------------------------------------------------------------------
set /a TOTAL=0
set /a PASSED=0
set /a WARNINGS=0
set /a ACTIONS=0
set /a FAILURES=0

:: ---------------------------------------------------------------------------
:: ADMINISTRATIVE PRIVILEGE CHECK
:: Attempt to access a privileged resource. If it fails, we are not admin.
:: ---------------------------------------------------------------------------
net session >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo   !CR![x]  Administrative privileges required.!C0!
    echo   !CD!     Right-click this script and select "Run as administrator".!C0!
    echo.
    pause
    exit /b 3
)

:: ---------------------------------------------------------------------------
:: BANNER
:: ---------------------------------------------------------------------------
cls
echo.
echo   !CC!+==============================================================================+!C0!
echo   !CC!^|!C0!                                                                              !CC!^|!C0!
echo   !CC!^|!C0!       !BW!V A N G U A R D  -  C M D!C0!     !CD!v!VER!!C0!                                  !CC!^|!C0!
echo   !CC!^|!C0!       !CD!Enterprise System Hardening ^& Optimization Framework!C0!               !CC!^|!C0!
echo   !CC!^|!C0!                                                                              !CC!^|!C0!
echo   !CC!+==============================================================================+!C0!
echo.
echo   !CD!Host: !HOST!  ^|  !DDATE! !DTIME!  ^|  Log: !LOG!!C0!
echo.

:: Write header to log file
echo ============================================================================== >> "!LOG!"
echo   VANGUARD-CMD v!VER! -- System Hardening Report >> "!LOG!"
echo   Host: !HOST!   Date: !DDATE! !DTIME! >> "!LOG!"
echo ============================================================================== >> "!LOG!"
echo. >> "!LOG!"

:: ---------------------------------------------------------------------------
:: RUN MODULES
:: ---------------------------------------------------------------------------
call :mod_security
call :mod_optimize
call :summary

:: Set exit code based on results
if !FAILURES! gtr 0 ( exit /b 2 )
if !WARNINGS! gtr 0 ( exit /b 1 )
exit /b 0


:: ============================================================================
::
::  SUBROUTINES: LOGGING HELPERS
::
:: ============================================================================

:pass
    set /a TOTAL+=1
    set /a PASSED+=1
    echo   !CG![+]!C0!  %~1
    echo   [+]  %~1 >> "!LOG!"
    goto :eof

:action
    set /a TOTAL+=1
    set /a ACTIONS+=1
    echo   !CM![-]!C0!  %~1
    echo   [-]  %~1 >> "!LOG!"
    goto :eof

:warn
    set /a TOTAL+=1
    set /a WARNINGS+=1
    echo   !CY![~]!C0!  %~1
    echo   [~]  %~1 >> "!LOG!"
    goto :eof

:fail
    set /a TOTAL+=1
    set /a FAILURES+=1
    echo   !CR![x]!C0!  %~1
    echo   [x]  %~1 >> "!LOG!"
    goto :eof

:info
    echo   !CC![*]!C0!  %~1
    echo   [*]  %~1 >> "!LOG!"
    goto :eof

:section
    echo.
    echo   !CC!+------------------------------------------------------------------------------+!C0!
    echo   !CC!^|!C0!  !BW!%~1!C0!
    echo   !CC!+------------------------------------------------------------------------------+!C0!
    echo.
    echo. >> "!LOG!"
    echo   +------------------------------------------------------------------------------+ >> "!LOG!"
    echo   ^|  %~1 >> "!LOG!"
    echo   +------------------------------------------------------------------------------+ >> "!LOG!"
    echo. >> "!LOG!"
    goto :eof

:subsec
    echo.
    echo   !CD!--- %~1 ---!C0!
    echo. >> "!LOG!"
    echo   --- %~1 --- >> "!LOG!"
    echo. >> "!LOG!"
    goto :eof


:: ============================================================================
::
::  MODULE 1: SECURITY HARDENING & AUDIT
::
:: ============================================================================

:mod_security
    call :section "MODULE 1: SECURITY HARDENING ^& AUDIT                                    "

    :: ================================================================
    :: 1.1 PROTOCOL SECURITY
    :: ================================================================
    call :subsec "1.1 Protocol Security"

    :: --- SMBv1 Server ---
    :: Registry: HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters
    :: Value: SMB1 (DWORD) = 0 means disabled
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 2^>nul ^| findstr /i "SMB1"') do set "_v=%%v"

    if "!_v!"=="0x0" (
        call :pass "SMBv1 Server Protocol           : Disabled"
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "SMBv1 Server Protocol           : Disabled [was enabled]"
        ) else (
            call :fail "SMBv1 Server Protocol           : Failed to disable"
        )
    )

    :: --- SMBv1 Client (mrxsmb10 driver) ---
    :: If the driver start type is DISABLED (4), it is already off
    sc qc mrxsmb10 2>nul | findstr /i "DISABLED" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "SMBv1 Client Driver              : Disabled"
    ) else (
        sc stop mrxsmb10 >nul 2>&1
        sc config mrxsmb10 start= disabled >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "SMBv1 Client Driver              : Disabled [was enabled]"
        ) else (
            call :fail "SMBv1 Client Driver              : Failed to disable"
        )
    )

    :: --- NetBIOS over TCP/IP ---
    :: Iterate all network interfaces and set NetbiosOptions = 2 (disabled)
    set /a "_nb_fixed=0"
    set /a "_nb_ok=0"
    for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" 2^>nul ^| findstr /i "HKEY"') do (
        set "_nb_val="
        for /f "tokens=3" %%v in ('reg query "%%k" /v NetbiosOptions 2^>nul ^| findstr /i "NetbiosOptions"') do set "_nb_val=%%v"
        if "!_nb_val!"=="0x2" (
            set /a _nb_ok+=1
        ) else (
            reg add "%%k" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
            set /a _nb_fixed+=1
        )
    )

    if !_nb_fixed! gtr 0 (
        call :action "NetBIOS over TCP/IP             : Disabled on !_nb_fixed! interface(s)"
    ) else (
        call :pass "NetBIOS over TCP/IP             : Disabled on all interfaces"
    )

    :: --- NTLMv2 Enforcement ---
    :: LmCompatibilityLevel = 5 means "Send NTLMv2 only, refuse LM and NTLM"
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel 2^>nul ^| findstr /i "LmCompatibilityLevel"') do set "_v=%%v"

    if "!_v!"=="0x5" (
        call :pass "NTLM Authentication             : NTLMv2 only (Level 5)"
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "NTLM Authentication             : Enforced NTLMv2 only (Level 5)"
        ) else (
            call :fail "NTLM Authentication             : Failed to enforce"
        )
    )

    :: ================================================================
    :: 1.2 WINDOWS DEFENDER HARDENING
    :: ================================================================
    call :subsec "1.2 Windows Defender Hardening"

    :: Check if Defender service is installed (may be absent on Server Core or with third-party AV)
    sc query WinDefend >nul 2>&1
    if !errorlevel! neq 0 (
        call :info "Windows Defender                : Not installed (Server SKU or third-party AV)"
        goto :defender_done
    )

    :: --- Cloud-Delivered Protection ---
    :: SpyNetReporting = 2 means Advanced cloud protection
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting 2^>nul ^| findstr /i "SpyNetReporting"') do set "_v=%%v"

    if "!_v!"=="0x2" (
        call :pass "Defender Cloud Protection        : Enabled (Advanced)"
    ) else (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 2 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 1 /f >nul 2>&1
        call :action "Defender Cloud Protection        : Enabled (Advanced)"
    )

    :: --- PUA (Potentially Unwanted Application) Blocking ---
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v PUAProtection 2^>nul ^| findstr /i "PUAProtection"') do set "_v=%%v"

    if "!_v!"=="0x1" (
        call :pass "Defender PUA Blocking            : Enabled"
    ) else (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v PUAProtection /t REG_DWORD /d 1 /f >nul 2>&1
        call :action "Defender PUA Blocking            : Enabled"
    )

    :: --- Behavior Monitoring ---
    :: DisableBehaviorMonitoring = 0 means enabled (double negative)
    :: If the key does not exist, Defender defaults to enabled
    set "_v=DEFAULT"
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring 2^>nul ^| findstr /i "DisableBehaviorMonitoring"') do set "_v=%%v"

    if "!_v!"=="0x0" (
        call :pass "Defender Behavior Monitoring     : Enabled"
    ) else if "!_v!"=="DEFAULT" (
        call :pass "Defender Behavior Monitoring     : Enabled (default)"
    ) else (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 0 /f >nul 2>&1
        call :action "Defender Behavior Monitoring     : Re-enabled [was disabled]"
    )

    :: --- Real-Time Protection service state ---
    sc query WinDefend 2>nul | findstr /i "RUNNING" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "Defender Real-Time Protection    : Running"
    ) else (
        call :warn "Defender Real-Time Protection    : Not running"
    )

    :defender_done

    :: ================================================================
    :: 1.3 FIREWALL VERIFICATION
    :: ================================================================
    call :subsec "1.3 Firewall Verification"

    :: --- Domain Profile ---
    set "_fw="
    for /f "tokens=2" %%s in ('netsh advfirewall show domainprofile state 2^>nul ^| findstr /i "State"') do set "_fw=%%s"
    if /i "!_fw!"=="ON" (
        call :pass "Firewall Domain Profile         : ON"
    ) else if /i "!_fw!"=="OFF" (
        call :fail "Firewall Domain Profile         : OFF"
    ) else (
        call :warn "Firewall Domain Profile         : Unknown"
    )

    :: --- Private Profile ---
    set "_fw="
    for /f "tokens=2" %%s in ('netsh advfirewall show privateprofile state 2^>nul ^| findstr /i "State"') do set "_fw=%%s"
    if /i "!_fw!"=="ON" (
        call :pass "Firewall Private Profile        : ON"
    ) else if /i "!_fw!"=="OFF" (
        call :fail "Firewall Private Profile        : OFF"
    ) else (
        call :warn "Firewall Private Profile        : Unknown"
    )

    :: --- Public Profile ---
    set "_fw="
    for /f "tokens=2" %%s in ('netsh advfirewall show publicprofile state 2^>nul ^| findstr /i "State"') do set "_fw=%%s"
    if /i "!_fw!"=="ON" (
        call :pass "Firewall Public Profile         : ON"
    ) else if /i "!_fw!"=="OFF" (
        call :fail "Firewall Public Profile         : OFF"
    ) else (
        call :warn "Firewall Public Profile         : Unknown"
    )

    :: --- Block Telemetry Outbound ---
    :: Add a single outbound block rule for known Microsoft telemetry endpoints
    set "_rule_name=VanguardCMD-Block-Telemetry"
    netsh advfirewall firewall show rule name="!_rule_name!" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "Telemetry Outbound Rule         : Already configured"
    ) else (
        netsh advfirewall firewall add rule name="!_rule_name!" dir=out action=block remoteip="13.107.4.50,13.69.68.64/26,40.77.226.0/25,52.114.74.0/24,65.55.252.43,204.79.197.200" enable=yes >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "Telemetry Outbound Rule         : Created (known endpoints blocked)"
        ) else (
            call :warn "Telemetry Outbound Rule         : Failed to create"
        )
    )

    :: ================================================================
    :: 1.4 SYSTEM SECURITY POSTURE
    :: ================================================================
    call :subsec "1.4 System Security Posture"

    :: --- UAC (User Account Control) ---
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2^>nul ^| findstr /i "EnableLUA"') do set "_v=%%v"

    if "!_v!"=="0x1" (
        call :pass "UAC (User Account Control)      : Enabled"
    ) else (
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "UAC (User Account Control)      : Enabled [reboot required]"
        ) else (
            call :fail "UAC (User Account Control)      : Failed to enable"
        )
    )

    :: --- AutoRun / AutoPlay ---
    :: NoDriveTypeAutoRun = 0xFF disables autorun on all drive types
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun 2^>nul ^| findstr /i "NoDriveTypeAutoRun"') do set "_v=%%v"

    if "!_v!"=="0xff" (
        call :pass "AutoRun/AutoPlay                : Disabled (all drives)"
    ) else (
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f >nul 2>&1
        call :action "AutoRun/AutoPlay                : Disabled (all drives)"
    )

    :: --- RDP Network Level Authentication ---
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication 2^>nul ^| findstr /i "UserAuthentication"') do set "_v=%%v"

    if "!_v!"=="0x1" (
        call :pass "RDP Network Level Authentication: Enabled"
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul 2>&1
        call :action "RDP Network Level Authentication: Enabled"
    )

    :: --- Remote Assistance ---
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp 2^>nul ^| findstr /i "fAllowToGetHelp"') do set "_v=%%v"

    if "!_v!"=="0x0" (
        call :pass "Remote Assistance               : Disabled"
    ) else (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f >nul 2>&1
        call :action "Remote Assistance               : Disabled"
    )

    :: --- Windows Remote Management (WinRM) ---
    sc query WinRM 2>nul | findstr /i "STOPPED" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "WinRM Service                   : Stopped"
    ) else (
        sc query WinRM >nul 2>&1
        if !errorlevel! equ 0 (
            call :info "WinRM Service                   : Running (verify if intentional)"
        ) else (
            call :pass "WinRM Service                   : Not installed"
        )
    )

    goto :eof


:: ============================================================================
::
::  MODULE 2: SYSTEM OPTIMIZATION
::
:: ============================================================================

:mod_optimize
    call :section "MODULE 2: SYSTEM OPTIMIZATION                                            "

    :: ================================================================
    :: 2.1 DISK & CACHE CLEANUP
    :: ================================================================
    call :subsec "2.1 Disk ^& Cache Cleanup"

    :: --- User TEMP ---
    del /q /f "%TEMP%\*" >nul 2>&1
    for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" >nul 2>&1
    call :action "User TEMP Directory             : Cleaned"

    :: --- System TEMP ---
    del /q /f "%SYSTEMROOT%\Temp\*" >nul 2>&1
    for /d %%d in ("%SYSTEMROOT%\Temp\*") do rd /s /q "%%d" >nul 2>&1
    call :action "System TEMP Directory           : Cleaned"

    :: --- Windows Update Download Cache ---
    :: Must stop the Windows Update service before clearing
    net stop wuauserv >nul 2>&1
    net stop bits >nul 2>&1
    del /q /f "%SYSTEMROOT%\SoftwareDistribution\Download\*" >nul 2>&1
    for /d %%d in ("%SYSTEMROOT%\SoftwareDistribution\Download\*") do rd /s /q "%%d" >nul 2>&1
    net start bits >nul 2>&1
    net start wuauserv >nul 2>&1
    call :action "Windows Update Cache            : Cleaned"

    :: --- Prefetch ---
    del /q /f "%SYSTEMROOT%\Prefetch\*" >nul 2>&1
    call :action "Prefetch Cache                  : Cleaned"

    :: --- DISM Component Store Cleanup ---
    :: This can take several minutes on systems with many updates
    call :info "DISM Component Cleanup          : Running (may take several minutes)..."
    dism /online /cleanup-image /startcomponentcleanup /quiet >nul 2>&1
    set "_dism_rc=!errorlevel!"
    if !_dism_rc! equ 0 (
        call :action "DISM Component Cleanup          : Completed"
    ) else if !_dism_rc! equ 3010 (
        call :action "DISM Component Cleanup          : Completed (reboot recommended)"
    ) else (
        call :warn "DISM Component Cleanup          : Finished with code !_dism_rc!"
    )

    :: --- DNS Resolver Cache ---
    ipconfig /flushdns >nul 2>&1
    call :action "DNS Resolver Cache              : Flushed"

    :: --- ARP Cache ---
    netsh interface ip delete arpcache >nul 2>&1
    call :action "ARP Cache                       : Flushed"

    :: ================================================================
    :: 2.2 TCP/IP STACK OPTIMIZATION
    :: ================================================================
    call :subsec "2.2 TCP/IP Stack Optimization"

    :: --- TCP Auto-Tuning ---
    :: 'normal' allows Windows to dynamically adjust the receive window
    netsh int tcp set global autotuninglevel=normal >nul 2>&1
    if !errorlevel! equ 0 (
        call :action "TCP Auto-Tuning Level           : Set to normal"
    ) else (
        call :warn "TCP Auto-Tuning Level           : Could not set"
    )

    :: --- Receive Side Scaling (RSS) ---
    :: Distributes network receive processing across multiple CPUs
    netsh int tcp set global rss=enabled >nul 2>&1
    if !errorlevel! equ 0 (
        call :action "Receive Side Scaling (RSS)      : Enabled"
    ) else (
        call :warn "Receive Side Scaling (RSS)      : Could not enable"
    )

    :: --- TCP Timestamps ---
    :: Disabling reduces TCP header overhead by 12 bytes per packet
    netsh int tcp set global timestamps=disabled >nul 2>&1
    if !errorlevel! equ 0 (
        call :action "TCP Timestamps                  : Disabled (reduced overhead)"
    ) else (
        call :warn "TCP Timestamps                  : Could not disable"
    )

    :: --- ECN (Explicit Congestion Notification) ---
    :: Enables routers to signal congestion before packet loss occurs
    netsh int tcp set global ecncapability=enabled >nul 2>&1
    if !errorlevel! equ 0 (
        call :action "ECN Capability                  : Enabled"
    ) else (
        call :warn "ECN Capability                  : Could not enable"
    )

    :: --- Display current TCP global parameters ---
    echo.
    call :info "Verified TCP/IP global state:"
    for /f "tokens=*" %%l in ('netsh int tcp show global 2^>nul ^| findstr /i "Receive Window" ^| findstr /i "Auto-Tuning"') do (
        call :info "  %%l"
    )
    for /f "tokens=*" %%l in ('netsh int tcp show global 2^>nul ^| findstr /i "Receive-Side Scaling"') do (
        call :info "  %%l"
    )
    for /f "tokens=*" %%l in ('netsh int tcp show global 2^>nul ^| findstr /i "ECN Capability"') do (
        call :info "  %%l"
    )

    :: ================================================================
    :: 2.3 TELEMETRY & PRIVACY
    :: ================================================================
    call :subsec "2.3 Telemetry ^& Privacy Management"

    :: --- Telemetry Level ---
    :: AllowTelemetry = 0 is "Security" (minimum possible level)
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry 2^>nul ^| findstr /i "AllowTelemetry"') do set "_v=%%v"

    if "!_v!"=="0x0" (
        call :pass "Telemetry Level                 : Security (minimum)"
    ) else (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
        call :action "Telemetry Level                 : Set to Security (minimum)"
    )

    :: --- Feedback Notifications ---
    set "_v="
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications 2^>nul ^| findstr /i "DoNotShowFeedbackNotifications"') do set "_v=%%v"

    if "!_v!"=="0x1" (
        call :pass "Feedback Notifications          : Already disabled"
    ) else (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul 2>&1
        call :action "Feedback Notifications          : Disabled"
    )

    :: --- DiagTrack Service (Connected User Experiences and Telemetry) ---
    sc qc DiagTrack 2>nul | findstr /i "DISABLED" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "DiagTrack Service               : Already disabled"
    ) else (
        sc stop DiagTrack >nul 2>&1
        sc config DiagTrack start= disabled >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "DiagTrack Service               : Stopped and disabled"
        ) else (
            call :warn "DiagTrack Service               : Could not disable"
        )
    )

    :: --- dmwappushservice (WAP Push Message Routing) ---
    sc qc dmwappushservice 2>nul | findstr /i "DISABLED" >nul 2>&1
    if !errorlevel! equ 0 (
        call :pass "WAP Push Service                : Already disabled"
    ) else (
        sc stop dmwappushservice >nul 2>&1
        sc config dmwappushservice start= disabled >nul 2>&1
        if !errorlevel! equ 0 (
            call :action "WAP Push Service                : Stopped and disabled"
        ) else (
            call :warn "WAP Push Service                : Could not disable"
        )
    )

    :: --- CEIP Scheduled Tasks ---
    :: Disable Customer Experience Improvement Program tasks
    set /a "_ceip_disabled=0"
    schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable >nul 2>&1
    if !errorlevel! equ 0 ( set /a _ceip_disabled+=1 )
    schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /disable >nul 2>&1
    if !errorlevel! equ 0 ( set /a _ceip_disabled+=1 )

    if !_ceip_disabled! gtr 0 (
        call :action "CEIP Scheduled Tasks            : !_ceip_disabled! task(s) disabled"
    ) else (
        call :pass "CEIP Scheduled Tasks            : Already disabled or not present"
    )

    :: --- Application Compatibility Telemetry ---
    schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable >nul 2>&1
    if !errorlevel! equ 0 (
        call :action "Compatibility Appraiser Task    : Disabled"
    ) else (
        call :pass "Compatibility Appraiser Task    : Already disabled or not present"
    )

    goto :eof


:: ============================================================================
::
::  SUMMARY
::
:: ============================================================================

:summary
    echo.
    echo   !CC!+==============================================================================+!C0!
    echo   !CC!^|!C0!  !BW!SCAN COMPLETE!C0!                                                              !CC!^|!C0!
    echo   !CC!^|!C0!                                                                              !CC!^|!C0!
    echo   !CC!^|!C0!  Total: !TOTAL!  ^|  !CG!Passed: !PASSED!!C0!  ^|  !CM!Fixed: !ACTIONS!!C0!  ^|  !CY!Warnings: !WARNINGS!!C0!  ^|  !CR!Failed: !FAILURES!!C0!
    echo   !CC!^|!C0!                                                                              !CC!^|!C0!
    echo   !CC!^|!C0!  !CD!Log saved: !LOG!!C0!
    echo   !CC!^|!C0!  !CY!Note: Some changes require a system restart to take effect.!C0!
    echo   !CC!^|!C0!                                                                              !CC!^|!C0!
    echo   !CC!+==============================================================================+!C0!
    echo.

    :: Write summary to log
    echo. >> "!LOG!"
    echo ============================================================================== >> "!LOG!"
    echo   SCAN COMPLETE >> "!LOG!"
    echo   Total: !TOTAL!  Passed: !PASSED!  Fixed: !ACTIONS!  Warnings: !WARNINGS!  Failed: !FAILURES! >> "!LOG!"
    echo   Note: Some changes require a system restart to take effect. >> "!LOG!"
    echo ============================================================================== >> "!LOG!"
    goto :eof
