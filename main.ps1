# Auto-Elevate to Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch the script with UAC prompt and FORCE the new window to stay open (-NoExit)
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ruleName = "Steam-Connection-Block"

# Set up the config file path (saves in the same folder as this script)
$configPath = Join-Path (Split-Path$PSCommandPath) "steam_path.txt"

# Check if we already have the path saved
if (Test-Path $configPath) {
    $steamPath = Get-Content$configPath
} else {
    Write-Host "First time setup: Please select your steam.exe file in the popup window..." -ForegroundColor Yellow
    
    # Load Windows Forms to show a file picker UI
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select steam.exe"
    $openFileDialog.Filter = "Steam Executable (steam.exe)|steam.exe"
    $openFileDialog.InitialDirectory = "C:\Program Files (x86)\Steam"
    
    # Show the file picker
    $dialogResult =$openFileDialog.ShowDialog()
    
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $steamPath =$openFileDialog.FileName
        # Save the chosen path to a text file so we don't ask again
        Set-Content -Path $configPath -Value$steamPath
        Write-Host "Saved Steam location to: $configPath" -ForegroundColor Green
    } else {
        Write-Warning "No file selected. Cannot continue."
        Read-Host "Press Enter to close..."
        exit
    }
}

# Verify the path actually exists
if (!(Test-Path $steamPath)) {
    Write-Warning "Could not find steam.exe at '$steamPath'."
    Write-Warning "Deleting saved config so you can try again next time..."
    Remove-Item $configPath -ErrorAction SilentlyContinue
    Read-Host "Press Enter to close..."
    exit
}

# Check if the rules already exist
$inboundRule = Get-NetFirewallRule -DisplayName "$ruleName-Inbound" -ErrorAction SilentlyContinue
$outboundRule = Get-NetFirewallRule -DisplayName "$ruleName-Outbound" -ErrorAction SilentlyContinue

if (!$inboundRule -or !$outboundRule) {
    # Create the rules and enable them (Blocks connection)
    Write-Host "Creating firewall rules..." -ForegroundColor Cyan
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
