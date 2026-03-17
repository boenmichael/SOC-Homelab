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
    description = "SSH public key for the Splunk VM."
    type        = string  
}