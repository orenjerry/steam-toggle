# Auto-Elevate to Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch the script with UAC prompt and FORCE the new window to stay open (-NoExit)
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ruleName = "Steam-Connection-Block"
# Update this path if you installed Steam on a different drive
$steamPath = "C:\Program Files (x86)\Steam\steam.exe" 

if (!(Test-Path $steamPath)) {
    Write-Warning "Could not find steam.exe at $steamPath. Please update the path in the script."
    Read-Host "Press Enter to close..."
    exit
}

# Check if the rules already exist
$inboundRule = Get-NetFirewallRule -DisplayName "$ruleName-Inbound" -ErrorAction SilentlyContinue
$outboundRule = Get-NetFirewallRule -DisplayName "$ruleName-Outbound" -ErrorAction SilentlyContinue

if (!$inboundRule -or !$outboundRule) {
    # Create the rules and enable them (Blocks connection)
    Write-Host "First run: Creating firewall rules..." -ForegroundColor Cyan
    New-NetFirewallRule -DisplayName "$ruleName-Inbound" -Direction Inbound -Program $steamPath -Action Block -Profile Any -Enabled True | Out-Null
    New-NetFirewallRule -DisplayName "$ruleName-Outbound" -Direction Outbound -Program $steamPath -Action Block -Profile Any -Enabled True | Out-Null
    Write-Host "Steam connection is now BLOCKED." -ForegroundColor Red
} else {
    # Toggle existing rules
    if ($inboundRule.Enabled -eq$true) {
        Set-NetFirewallRule -DisplayName "$ruleName-Inbound" -Enabled False
        Set-NetFirewallRule -DisplayName "$ruleName-Outbound" -Enabled False
        Write-Host "Steam connection is now ALLOWED." -ForegroundColor Green
    } else {
        Set-NetFirewallRule -DisplayName "$ruleName-Inbound" -Enabled True
        Set-NetFirewallRule -DisplayName "$ruleName-Outbound" -Enabled True
        Write-Host "Steam connection is now BLOCKED." -ForegroundColor Red
    }
}

Read-Host "Press Enter to close..."
