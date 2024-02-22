provider "azurerm" {
  features {}
  environment = var.azure_environment
}

resource "random_string" "random" {
  length      = 6
  special     = false
  lower       = true
  min_upper   = 2
  min_numeric = 2
}

locals {
  cluster_name = var.cluster_name == "" ? random_string.random.result : var.cluster_name
}

module "vnet" {
  source               = "./modules/vnet"
  location             = var.azure_region
  cluster_name         = local.cluster_name
  host_cidr            = var.vnet_cidr
  subnet_cidr          = var.address_space
  virtual_network_name = var.vnet_name
  tags                 = var.tags
}

module "common" {
  source       = "./modules/common"
  location     = var.azure_region
  cluster_name = local.cluster_name
  rg           = module.vnet.rg
  vnet_id      = module.vnet.id
  subnet_id    = module.vnet.subnet_id
  tags         = var.tags
}

module "masters" {
  source              = "./modules/master"
  master_count        = var.master_count
  vnet_id             = module.vnet.id
  rg                  = module.vnet.rg
  cluster_name        = local.cluster_name
  location            = var.azure_region
  subnet_id           = module.vnet.subnet_id
  ssh_key             = module.common.ssh_key
  image               = var.image_ubuntu1804
  master_type         = var.master_type
  tags                = var.tags
  fault_domain_count  = var.fault_domain_count
  update_domain_count = var.update_domain_count

}

module "workers" {
  count               = var.worker_count > 0 ? 1 : 0
  source              = "./modules/worker"
  worker_count        = var.worker_count
  vnet_id             = module.vnet.id
  rg                  = module.vnet.rg
  cluster_name        = local.cluster_name
  location            = var.azure_region
  subnet_id           = module.vnet.subnet_id
  ssh_key             = module.common.ssh_key
  image               = var.image_ubuntu1804
  worker_type         = var.worker_type
  tags                = var.tags
  fault_domain_count  = var.fault_domain_count
  update_domain_count = var.update_domain_count
}

module "windows_workers" {
  count               = var.windows_worker_count > 0 ? 1 : 0
  source              = "./modules/windows_worker"
  worker_count        = var.windows_worker_count
  vnet_id             = module.vnet.id
  rg                  = module.vnet.rg
  cluster_name        = local.cluster_name
  location            = var.azure_region
  subnet_id           = module.vnet.subnet_id
  ssh_key             = module.common.ssh_key
  image               = var.image_windows2019
  worker_type         = var.worker_type
  username            = var.windows_admin_username
  tags                = var.tags
  fault_domain_count  = var.fault_domain_count
  update_domain_count = var.update_domain_count
}

locals {
  managers = [
    for ip in module.masters.public_ips : {
      ssh = {
        address = ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${local.cluster_name}.pem"
      }
      privateInterface = "eth0"
      role             = "manager"
    }
  ]
  workers = var.worker_count > 0 ? [
    for ip in module.workers[0].public_ips : {
      ssh = {
        address = ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${local.cluster_name}.pem"
      }
      privateInterface = "eth0"
      role             = "worker"
    }
  ] : []
  windows_workers = var.windows_worker_count > 0 ? [
    for ip in module.windows_workers[0].public_ips : {
      winRM = {
        address  = ip
        user     = var.windows_admin_username
        password = module.windows_workers[0].windows_password
        useHTTPS = true
        insecure = true
      }
      privateInterface = "Ethernet"
      role             = "worker"
    }
  ] : []
}

locals {
  launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.4"
    kind       = "mke"
    metadata = {
      name = local.cluster_name
    }
    spec = {
      mcr = {
        channel           = "stable"
        installURLLinux   = "https://get.mirantis.com/"
        installURLWindows = "https://get.mirantis.com/install.ps1"
        repoURL           = "https://repos.mirantis.com"
        version           = var.mcr_version
      }
      mke = {
        adminUsername = "admin"
        adminPassword = var.admin_password
        version       = var.mke_version
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.masters.lb_dns_name}",
        ]
      }
      hosts = concat(local.managers, local.workers, local.windows_workers)
    }
  }
}

output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}

output "loadbalancers" {
  value = {
    MasterLB  = module.masters.lb_dns_name
    WorkersLB = var.worker_count > 0 ? module.workers[0].lb_dns_name : ""
  }
}
