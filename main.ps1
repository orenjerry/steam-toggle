# Requires Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Access Denied. Please right-click PowerShell and run as Administrator."
    Pause
    exit
}

$ruleName = "Steam-Connection-Block"
# Update this path if you installed Steam on a different drive
$steamPath = "D:\Aplikasi\Steam\Steam.exe" 

if (!(Test-Path $steamPath)) {
    Write-Warning "Could not find steam.exe at $steamPath. Please update the path in the script."
    Pause
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
    if ($inboundRule.Enabled -eq $true) {
        Set-NetFirewallRule -DisplayName "$ruleName-Inbound" -Enabled False
        Set-NetFirewallRule -DisplayName "$ruleName-Outbound" -Enabled False
        Write-Host "Steam connection is now ALLOWED." -ForegroundColor Green
    } else {
        Set-NetFirewallRule -DisplayName "$ruleName-Inbound" -Enabled True
        Set-NetFirewallRule -DisplayName "$ruleName-Outbound" -Enabled True
        Write-Host "Steam connection is now BLOCKED." -ForegroundColor Red
    }
}

Start-Sleep -Seconds 3
