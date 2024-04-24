# Terraform for Launchpad on Azure

A terraform module for preparing a basic Azure compute cluster for Launchpad installation.

[Launchpad]{https://docs.mirantis.com/mke/3.7/launchpad.html} is a Mirantis tool for installation 
of Mirantis Containers products. The tool can work with any properly prepared accessible cluster,
This module can create a basic simple cluster, and provide the appropriate Launchpad configuration
for use with Launchpad.

## Prerequisites

* An account and credentials for Azure.
* Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install)
* The Terraform `azurerm` provider requires a number of environment variables to be set. Refer to the [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) documentation for more details. The minimum required environment variables for this example are:

  * ARM_CLIENT_ID
  * ARM_CLIENT_SECRET
  * ARM_SUBSCRIPTION_ID
  * ARM_TENANT_ID

### Authentication

The Terraform `azure` provider uses an external system for authentication, which can be set up 
before running terraform, using the azure cli.
See [here](https://registry.terraform.io/providers/hashicorp/azure/latest/docs) for more details

## Usage

Use the module to create a basic compute cluster with HCL as follows:

```
module "provision" {
  source = "terraform-mirantis-modules/launchpad-azure/mirantis"

  azure_region = "eastus"

  cluster_name = "my-cluster" 

  master_count = 1
  worker_count = 3
  msr_count    = 1
}
```

Then use the `mke_cluster` output for the launchpad yaml:

```
terraform output -raw mke_cluster > launchpad.yaml
launchpad apply
```

### Azure Configuration

1. `azure_environment` can specify the azure environment

### Cluster Components

Cluster composition can be managed using simple input controls for swarm managers, workers, 
MSR replicas. Windows workers also have their own controls matching controls.

```
manager_count = 3                  // 3 machines will be created
manager_type  = "Standard_DS3_v2"  // machine node type
manager_volume_size = 100GB        // machine volume size
```

### Product configuration

While the Terraform module does not run launchpad, it does prepare the Launchpad configuration
file for you. Because of this you can provide inputs that will then get included into the 
Launchpad yaml.

Each product's installation targets can be configured: 

```
mcr_channel  = "stable"
mcr_repo_url = "https://repos.mirantis.com"
mcr_version  = "23.0.3"

mke_image_repo    = "docker.io/mirantis"
mke_install_flags = [ "--nodeport-range=32768-35535" ]
mke_version       = "3.6.3"

msr_image_repo = "docker.io/mirantis"
msr_install_flags = [ "--ucp-insecure-tls" ]
msr_version        = "2.9.11"
msr_replica_config = "sequential"
```

Specifically, the MKE authentication can be set

```
admin_password = "mirantisadmin"
admin_username = "admin"
```

### Windows workers 

This module supports windows workers. You need only specify the node configuration 
and also incluse a windows admin password.

## Notes

1. If any Windows workers are created then a random password will be generated for the admin account `DockerAdmin` that is created.
2. Only Linux workers are added to the LoadBalancer created for workers.
3. Both RDP and WinRM ports are opened for Windows workers.
4. A default storage account is created for kubernetes.
5. The number of Fault & Update Domains varies depending on which Azure Region you're using. A list can be found 
[here](https://github.com/MicrosoftDocs/azure-docs/blob/master/includes/managed-disks-common-fault-domain-region-list.md). The Fault 
& Update Domain values are used in the Availability Set definitions
6. Windows worker nodes may be rebooted after engine install
