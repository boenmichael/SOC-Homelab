# SOC HomeLab v2 Terraform Draft

## Goal

Build a small-enterprise SOC lab in Azure with:

- Splunk SIEM server (SOC monitoring)
- Active Directory domain
- Compromisable endpoint
- Centralized logging
- Attack simulation

This draft is mapped to your current files (`providers.tf`, `network.tf`, `compute.tf`, `variables.tf`, `terraform.tfvars`) and broken into safe, incremental phases.

---

## Current Baseline (What You Already Have)

From current config:

- Resource Group: `azurerm_resource_group.this`
- VNet: `azurerm_virtual_network.this` (`10.10.0.0/16`)
- Subnets:
  - `azurerm_subnet.soc_subnet` (`10.10.1.0/24`)
  - `azurerm_subnet.ad_subnet` (`10.10.2.0/24`)
  - `azurerm_subnet.client_subnet` (`10.10.3.0/24`)
- NICs with static private IPs:
  - Splunk NIC `10.10.1.4`
  - AD NIC `10.10.2.4`
  - Client NIC `10.10.3.4`
- VMs:
  - Linux VM `azurerm_linux_virtual_machine.splunk_vm` (Ubuntu 22.04 LTS image)
  - Windows VM `azurerm_windows_virtual_machine.ad_vm`
  - Windows VM `azurerm_windows_virtual_machine.client_vm`

## Confirmed Decisions (Pinned)

- SOC VM image: Ubuntu LTS (`Canonical / 0001-com-ubuntu-server-jammy / 22_04-lts-gen2 / latest`)
- Secret handling: keep plaintext `admin_password` and `subscription_id` in `terraform.tfvars` for this lab
- SSH public key path: current `~/.ssh/...` approach is accepted because lab management is performed from a separate Kali Linux machine
- Access model: use Azure Bastion Basic for management access

---

## v2 Target Layout (Files and Responsibilities)

Use this structure while keeping your current files valid during migration:

- `providers.tf`
  - `terraform` block
  - `provider "azurerm"` block
- `network.tf`
  - Resource Group
  - VNet
  - Subnets
- `security.tf`
  - NSGs and subnet associations
  - Optional JIT/Bastion-related resources
- `compute.tf`
  - NICs
  - VM resources (SOC, AD, client)
- `identity.tf`
  - AD promotion and domain join VM extensions
- `logging.tf`
  - Splunk installation bootstrap and forwarder setup via extensions
- `variables.tf`
  - Input variables only
- `outputs.tf`
  - Important outputs (IPs, hostnames, URLs)
- `terraform.tfvars`
  - Contains lab variables (including plaintext secrets by current decision)

Note: Initial split is now complete into `providers.tf`, `network.tf`, and `compute.tf`. Remaining files (`security.tf`, `identity.tf`, `logging.tf`, `outputs.tf`) can be added incrementally.

Update: `logging.tf` has now been added for Splunk and forwarder automation.

---

## Resource-by-Resource Checklist (Mapped to Existing Config)

## Phase 0: Baseline and Prereqs (No Architecture Change)

1. Secrets handling

- [x] Keep plaintext `admin_password` and `subscription_id` in `terraform.tfvars` (lab decision).
- [ ] Optional hardening later: move sensitive values to env vars or Key Vault.

2. SSH key path reliability

- [x] Keep `~/.ssh/...` path as-is for Kali-based management host.

3. Provider readiness

- [ ] Keep `azurerm` provider on v4 and validate auth context.

Validation gate:

- [ ] `terraform init -upgrade`
- [ ] `terraform validate`

---

## Phase 1: Network Security Controls (High Priority)

Access model selected:

- [x] Azure Bastion Basic selected
- [x] Add Bastion subnet (`AzureBastionSubnet`) and Bastion resources during security phase

### Add NSGs (new resources)

Create three NSGs:

- [x] `azurerm_network_security_group.soc_nsg`
- [x] `azurerm_network_security_group.ad_nsg`
- [x] `azurerm_network_security_group.client_nsg`

Add baseline rules:

- SOC NSG:
  - [x] Allow Splunk web UI `8000` from admin source only
  - [x] Allow Splunk forwarder ingest `9997` from AD/client subnet
  - [x] Allow SSH `22` from Bastion subnet (admin access path)
- AD NSG:
  - [x] Allow required AD ports from domain members
  - [x] Restrict RDP `3389` to Bastion subnet (admin access path)
- Client NSG:
  - [x] Restrict RDP `3389` to Bastion subnet (admin access path)
  - [x] Allow domain communication to AD subnet

Associate NSGs to subnets:

- [x] `azurerm_subnet_network_security_group_association.soc_assoc`
- [x] `azurerm_subnet_network_security_group_association.ad_assoc`
- [x] `azurerm_subnet_network_security_group_association.client_assoc`

Validation gate:

- [ ] `terraform plan` shows only NSG/association additions
- [ ] `terraform apply`

---

## Phase 2: SOC VM Image Strategy (Resolved)

Current resource: `azurerm_linux_virtual_machine.splunk_vm`

Decision path:

- [x] Option A chosen: Ubuntu LTS image for Splunk host.
- [ ] Confirm image availability in target region before first full apply.

If using Ubuntu (example direction):

- [ ] `publisher = "Canonical"`
- [ ] `offer = "0001-com-ubuntu-server-jammy"`
- [ ] `sku = "22_04-lts-gen2"`
- [ ] `version = "latest"`

Validation gate:

- [x] Linux image updated in Terraform code
- [ ] `terraform plan` for VM replacement is understood/approved
- [ ] `terraform apply`

---

## Phase 3: AD Domain Build Automation

Current resource: `azurerm_windows_virtual_machine.ad_vm`

Add extension for AD DS promotion:

- [x] `azurerm_virtual_machine_extension.ad_ds_install`
  - Install AD-Domain-Services
  - Create forest (example: `corp.local`)
  - Reboot handling in script

Add variables:

- [x] `ad_domain_name`
- [x] `ad_safe_mode_password` (sensitive)

Post-deploy checks:

- [ ] AD VM can resolve and host domain DNS
- [ ] Domain controller service healthy

Validation gate:

- [x] Terraform code updated for AD DS extension + new vars
- [ ] Apply only extension + new vars
- [ ] Verify AD domain exists

---

## Phase 4: Domain Join the Client Endpoint

Current resource: `azurerm_windows_virtual_machine.client_vm`

Add extension for domain join:

- [x] `azurerm_virtual_machine_extension.client_domain_join`
  - Join `corp.local`
  - Use domain join account creds (prefer least privilege)

Add variables:

- [x] `domain_join_username`
- [x] `domain_join_password` (sensitive)

Validation gate:

- [ ] Client appears in AD Computers
- [ ] Login with domain user works

---

## Phase 5: Centralized Logging to Splunk

SOC server bootstrap:

- [x] Add cloud-init/custom_data or extension script on SOC VM to install Splunk Enterprise.
- [x] Configure Splunk listener ports (`9997`, `8089`) and web (`8000`) securely.

Windows log forwarding:

- [x] Add VM extension/script to install Splunk Universal Forwarder on AD VM.
- [x] Add VM extension/script to install Splunk Universal Forwarder on client VM.
- [x] Configure monitored inputs:
  - [x] Security logs
  - [x] Sysmon logs
  - [x] PowerShell logs

Optional Azure-native logging:

- [ ] Add Log Analytics workspace and Azure Monitor diagnostics for Azure control-plane visibility.

Validation gate:

- [ ] Events from AD and client are searchable in Splunk
- [ ] Index/sourcetype naming is documented

---

## Phase 6: Attack Simulation Capability

Infrastructure additions:

- [x] No attacker VM: run attack simulation directly from `vm-client`.

Simulation tooling:

- [x] Atomic Red Team tests (repo scaffolded on `vm-client`)
- [x] Scripted ATT&CK-style techniques on `vm-client`
- [x] Curated scripts for:
  - [x] Credential access attempts
  - [x] Lateral movement simulations
  - [x] Suspicious PowerShell activity

Detection validation:

- [ ] Build Splunk saved searches and alerts
- [ ] Map detections to ATT&CK techniques
- [ ] Record true positives/false positives

Validation gate:

- [ ] At least 5 reproducible attack scenarios produce detectable telemetry

---

## Phase 7: Documentation Outputs (for your guide)

Capture these outputs from Terraform:

- [x] SOC VM private IP and management access method
- [x] AD VM private IP
- [x] Client VM private IP
- [x] Domain name and join instructions
- [x] Splunk access URL and initial login flow

Create `outputs.tf` with at least:

- [x] `soc_private_ip`
- [x] `ad_private_ip`
- [x] `client_private_ip`
- [x] `domain_name`

---

## Suggested New Variables (v2)

Add these to `variables.tf` over time:

- [ ] `admin_source_ip_cidr` (for mgmt access allowlist)
- [ ] `ad_domain_name`
- [ ] `ad_safe_mode_password` (sensitive)
- [ ] `domain_join_username`
- [ ] `domain_join_password` (sensitive)
- [ ] `soc_vm_size`
- [ ] `ad_vm_size`
- [ ] `client_vm_size`

---

## Minimal First Increment (Recommended Next PR/Change Set)

Keep it small and low-risk:

- [ ] Add NSGs + subnet associations
- [ ] Add Azure Bastion Basic resources
- [x] Keep SSH key path handling as-is
- [x] Keep sensitive values in tfvars for now
- [x] SOC image strategy locked to Ubuntu

This gives you a secure and stable base before AD/join/logging automation.

---

## Command Checklist Per Increment

For each phase:

```bash
terraform fmt
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

After major phase completion:

```bash
terraform output
```

---

## Notes for Your Specific Current Config

- You have already switched Splunk host image to Ubuntu LTS, which aligns with the recommended stable base for SIEM workloads.
- You have chosen Azure Bastion Basic for management access; keep NSGs restrictive and avoid direct internet exposure for VM admin ports.
- Static private IPs are fine for a lab as long as subnet CIDRs are not changed.
- Keep AD and Client on separate subnets as you already do; this supports cleaner NSG policy and later attack-path demonstrations.

---

## Completion Criteria (Definition of Done)

Lab is considered complete when:

- [ ] AD domain is operational and client is domain-joined
- [ ] Splunk receives logs from AD + client
- [ ] At least one attack simulation generates alerts/detections
- [ ] NSGs enforce least privilege between tiers
- [ ] Deployment and validation steps are documented end-to-end
