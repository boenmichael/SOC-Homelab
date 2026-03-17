# Promote AD VM to a domain controller and create a new forest.
resource "azurerm_virtual_machine_extension" "ad_ds_install" {
  name                       = "ad-ds-install"
  virtual_machine_id         = azurerm_windows_virtual_machine.ad_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({})

  protected_settings = jsonencode({
    commandToExecute = <<-EOT
powershell -ExecutionPolicy Bypass -Command "Install-WindowsFeature AD-Domain-Services -IncludeManagementTools; Import-Module ADDSDeployment; $safeMode = ConvertTo-SecureString '${var.ad_safe_mode_password}' -AsPlainText -Force; Install-ADDSForest -DomainName '${var.ad_domain_name}' -InstallDNS:$true -SafeModeAdministratorPassword $safeMode -Force:$true -NoRebootOnCompletion:$true; Restart-Computer -Force"
EOT
  })

  depends_on = [
    azurerm_windows_virtual_machine.ad_vm,
  ]
}

# Join client VM to the AD domain after domain controller promotion.
resource "azurerm_virtual_machine_extension" "client_domain_join" {
  name                       = "client-domain-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.client_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.ad_domain_name
    User    = var.domain_join_username
    Restart = "true"
    Options = 3
  })

  protected_settings = jsonencode({
    Password = var.domain_join_password
  })

  depends_on = [
    azurerm_virtual_machine_extension.ad_ds_install,
  ]
}
