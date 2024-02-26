variable "cluster_name" {
  default     = ""
  description = "The name of the cluster"
}

variable "mke_version" {
  default     = "3.6.3"
  description = "The version of Mirantis Kubernetes Engine"
}

variable "mcr_version" {
  default     = "23.0.3"
  description = "The version of Mirantis Container Runtime"
}

variable "azure_region" {
  default     = "eastus"
  description = "The Azure region"
}

variable "azure_environment" {
  default     = "public"
  description = "The Azure environment"
}

variable "vnet_name" {
  default     = "virtualNet"
  description = "The name of the virtual network"
}

variable "vnet_cidr" {
  default     = "172.31.0.0/16"
  description = "The address space that is used by the virtual network"
}

variable "address_space" {
  default     = "172.31.0.0/16"
  description = "The address space that is used by the virtual network"
}

variable "admin_password" {
  default     = ""
  description = "The password for the admin user"
}

variable "master_count" {
  default     = 1
  description = "The number of master nodes"
}

variable "worker_count" {
  default     = 3
  description = "The number of worker nodes"
}

variable "windows_worker_count" {
  default     = 0
  description = "The number of Windows worker nodes"
}

variable "master_type" {
  default     = "Standard_DS3_v2"
  description = "The type of the master node"
}

variable "worker_type" {
  default     = "Standard_DS3_v2"
  description = "The type of the worker node"
}

variable "master_volume_size" {
  default     = 100
  description = "The size of the master node volume"
}

variable "worker_volume_size" {
  default     = 100
  description = "The size of the worker node volume"
}

variable "image_ubuntu1804" {
  description = "Default Ubuntu 18.04 LTS Image"
  type        = map(any)
  default = {
    "offer"     = "UbuntuServer"
    "publisher" = "Canonical"
    "sku"       = "18.04-LTS"
    "version"   = "latest"
  }
}

variable "image_windows2019" {
  description = "Default Windows 2019 Server Image"
  type        = map(any)
  default = {
    "offer"     = "WindowsServer"
    "publisher" = "MicrosoftWindowsServer"
    "sku"       = "2019-Datacenter"
    "version"   = "latest"
  }
}

variable "windows_admin_username" {
  default     = "MirantisAdmin"
  description = "The username for the Windows admin user"
}

variable "tags" {
  type = map(any)
  default = {
    "Owner" = "Launchpad"
  }
}

variable "fault_domain_count" {
  description = "Specifies the number of fault domains that are used"
  default     = 2
}

variable "update_domain_count" {
  description = "Specifies the number of update domains that are used"
  default     = 2
}
