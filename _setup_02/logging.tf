# Install and bootstrap Splunk Enterprise on the SOC VM.
resource "azurerm_virtual_machine_extension" "splunk_install" {
  name                       = "splunk-install"
  virtual_machine_id         = azurerm_linux_virtual_machine.splunk_vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({})

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
bash -c 'set -euo pipefail; wget -O /tmp/splunk.tgz "${var.splunk_download_url}"; tar -xzf /tmp/splunk.tgz -C /opt; /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt; /opt/splunk/bin/splunk enable boot-start -user ${var.admin_username}; /opt/splunk/bin/splunk edit user admin -password "${var.splunk_admin_password}" -role admin -auth admin:changeme; /opt/splunk/bin/splunk enable listen 9997 -auth admin:${var.splunk_admin_password}; /opt/splunk/bin/splunk restart'
EOT
  })

  depends_on = [
    azurerm_linux_virtual_machine.splunk_vm,
  ]
}

# Install Splunk Universal Forwarder on AD VM and configure event log inputs.
resource "azurerm_virtual_machine_extension" "ad_forwarder_install" {
  name                       = "ad-forwarder-install"
  virtual_machine_id         = azurerm_windows_virtual_machine.ad_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({})

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
powershell -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $msi='C:\\Windows\\Temp\\splunkforwarder.msi'; Invoke-WebRequest -Uri '${var.splunk_forwarder_download_url}' -OutFile $msi; Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', 'AGREETOLICENSE=Yes', 'LAUNCHSPLUNK=0' -Wait; $sf='C:\\Program Files\\SplunkUniversalForwarder\\etc\\system\\local'; New-Item -Path $sf -ItemType Directory -Force | Out-Null; @'[tcpout]\ndefaultGroup = default-autolb-group\n[tcpout:default-autolb-group]\nserver = ${azurerm_network_interface.splunk_nic.private_ip_address}:9997\n'@ | Set-Content -Path ($sf + '\\outputs.conf') -Encoding ASCII; @'[WinEventLog://Security]\ndisabled = 0\nindex = main\n[WinEventLog://System]\ndisabled = 0\nindex = main\n[WinEventLog://Application]\ndisabled = 0\nindex = main\n[WinEventLog://Microsoft-Windows-PowerShell/Operational]\ndisabled = 0\nindex = main\n[WinEventLog://Microsoft-Windows-Sysmon/Operational]\ndisabled = 0\nindex = main\n'@ | Set-Content -Path ($sf + '\\inputs.conf') -Encoding ASCII; Start-Process 'C:\\Program Files\\SplunkUniversalForwarder\\bin\\splunk.exe' -ArgumentList 'start', '--accept-license', '--answer-yes', '--no-prompt' -Wait"
EOT
  })

  depends_on = [
    azurerm_virtual_machine_extension.splunk_install,
    azurerm_virtual_machine_extension.ad_ds_install,
  ]
}

# Install Splunk Universal Forwarder on client VM and configure event log inputs.
resource "azurerm_virtual_machine_extension" "client_forwarder_install" {
  name                       = "client-forwarder-install"
  virtual_machine_id         = azurerm_windows_virtual_machine.client_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({})

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
powershell -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $msi='C:\\Windows\\Temp\\splunkforwarder.msi'; Invoke-WebRequest -Uri '${var.splunk_forwarder_download_url}' -OutFile $msi; Start-Process msiexec.exe -ArgumentList '/i', $msi, '/qn', 'AGREETOLICENSE=Yes', 'LAUNCHSPLUNK=0' -Wait; $sf='C:\\Program Files\\SplunkUniversalForwarder\\etc\\system\\local'; New-Item -Path $sf -ItemType Directory -Force | Out-Null; @'[tcpout]\ndefaultGroup = default-autolb-group\n[tcpout:default-autolb-group]\nserver = ${azurerm_network_interface.splunk_nic.private_ip_address}:9997\n'@ | Set-Content -Path ($sf + '\\outputs.conf') -Encoding ASCII; @'[WinEventLog://Security]\ndisabled = 0\nindex = main\n[WinEventLog://System]\ndisabled = 0\nindex = main\n[WinEventLog://Application]\ndisabled = 0\nindex = main\n[WinEventLog://Microsoft-Windows-PowerShell/Operational]\ndisabled = 0\nindex = main\n[WinEventLog://Microsoft-Windows-Sysmon/Operational]\ndisabled = 0\nindex = main\n'@ | Set-Content -Path ($sf + '\\inputs.conf') -Encoding ASCII; Start-Process 'C:\\Program Files\\SplunkUniversalForwarder\\bin\\splunk.exe' -ArgumentList 'start', '--accept-license', '--answer-yes', '--no-prompt' -Wait"
EOT
  })

  depends_on = [
    azurerm_virtual_machine_extension.splunk_install,
    azurerm_virtual_machine_extension.client_domain_join,
  ]
}

# Prepare client VM to run attack simulations locally (no separate attacker VM).
resource "azurerm_virtual_machine_extension" "client_attack_sim_setup" {
  name                       = "client-attack-sim-setup"
  virtual_machine_id         = azurerm_windows_virtual_machine.client_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({})

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
powershell -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $root='C:\\AttackSim'; New-Item -Path $root -ItemType Directory -Force | Out-Null; Invoke-WebRequest -Uri 'https://github.com/redcanaryco/atomic-red-team/archive/refs/heads/master.zip' -OutFile ($root + '\\atomic-red-team.zip'); Expand-Archive -Path ($root + '\\atomic-red-team.zip') -DestinationPath $root -Force; @'Write-Host \"Simulating failed SMB auth attempts against ${azurerm_network_interface.ad_nic.private_ip_address}\"; 1..5 | ForEach-Object { cmd /c \"net use \\\\${azurerm_network_interface.ad_nic.private_ip_address}\\IPC$ /user:corp\\fakeuser WrongPassword123!\" | Out-Null }'@ | Set-Content -Path ($root + '\\credential_access_attempts.ps1') -Encoding ASCII; @'Write-Host \"Running recon scans against AD and client for lateral movement simulation\"; Test-NetConnection -ComputerName ${azurerm_network_interface.ad_nic.private_ip_address} -Port 445; Test-NetConnection -ComputerName ${azurerm_network_interface.ad_nic.private_ip_address} -Port 3389; Test-NetConnection -ComputerName ${azurerm_network_interface.client_nic.private_ip_address} -Port 445'@ | Set-Content -Path ($root + '\\lateral_movement_sim.ps1') -Encoding ASCII; @'Write-Host \"Executing suspicious PowerShell activity simulation\"; powershell.exe -NoProfile -EncodedCommand SQBlAHgAIAAnAFMAdQBzAHAAaQBjAGkAbwB1AHMAUABvAHcAZQByAFMAaABlAGwAbABBAGMAdABpAHYAaQB0AHkAJwA='@ | Set-Content -Path ($root + '\\suspicious_powershell_activity.ps1') -Encoding ASCII"
EOT
  })

  depends_on = [
    azurerm_virtual_machine_extension.client_domain_join,
    azurerm_virtual_machine_extension.client_forwarder_install,
  ]
}
