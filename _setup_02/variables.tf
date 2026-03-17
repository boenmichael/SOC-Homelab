variable "resource_group_name" {
    default = "SOC-LAB-FR"
}

variable "location" {
    default = "France Central"
}

variable "vnet_cidr" {
    default = "10.10.0.0/16"
}

variable "soc_subnet_cidr" {
    default = "10.10.1.0/24"
}

variable "ad_subnet_cidr" {
    default = "10.10.2.0/24"
}

variable "client_subnet_cidr" {
    default = "10.10.3.0/24"
}

variable "vm_size" {
    default = "Standard_B2als_v2"
}

variable "admin_username" {
    default = "azureuser"
}

variable "admin_password" {
    description = "Password for the AD and client VMs. Must meet Azure's complexity requirements."
    type       = string
    sensitive  = true
}

variable "public_key" {
  description = "Public key for SSH access to Splunk VMs."
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID to deploy resources into."
  type        = string
}

variable "admin_source_ip_cidr" {
    description = "Admin source CIDR allowed to access Splunk web UI (for example x.x.x.x/32)."
    type        = string
    default     = "0.0.0.0/0"
}

variable "bastion_subnet_cidr" {
    description = "CIDR range for Azure Bastion subnet (must be /26 or larger)."
    type        = string
    default     = "10.10.10.0/26"
}

variable "ad_domain_name" {
    description = "Active Directory forest root domain name."
    type        = string
    default     = "corp.local"
}

variable "ad_safe_mode_password" {
    description = "Directory Services Restore Mode (DSRM) password for AD promotion."
    type        = string
    sensitive   = true
}

variable "domain_join_username" {
    description = "Domain account used by JsonADDomainExtension to join the client VM (UPN format recommended)."
    type        = string
}

variable "domain_join_password" {
    description = "Password for the domain join account."
    type        = string
    sensitive   = true
}

variable "splunk_download_url" {
    description = "Download URL for Splunk Enterprise .tgz package for Linux."
    type        = string
}

variable "splunk_admin_password" {
    description = "Admin password configured for Splunk Enterprise on the SOC VM."
    type        = string
    sensitive   = true
}

variable "splunk_forwarder_download_url" {
    description = "Download URL for Splunk Universal Forwarder MSI package."
    type        = string
}

