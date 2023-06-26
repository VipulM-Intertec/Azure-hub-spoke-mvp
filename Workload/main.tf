

# Resource Group Module is Used to Create Resource Groups
module "spoke1-resourcegroup" {
source = "../modules/resourcegroups"
# Resource Group Variables
az_rg_name     = "az-netb-pr-eastus2-rg"
az_rg_location = "eastus2"
az_tags = {
ApplicationName = "Network"
Role 		    = "Network"
Owner 		    = "IT"
Environment	    = "Prod"
CompanyName     = "NETB"
Criticality     = "Medium"
DR 		        = "No"
  }
}



# vnet Module is used to create Virtual Networks and Subnets
module "spoke1-vnet" {
source = "../modules/vnet"

virtual_network_name              = "az-netb-pr-eastus2-vnet"
resource_group_name               = module.spoke1-resourcegroup.rg_name
location                          = module.spoke1-resourcegroup.rg_location
virtual_network_address_space     = ["10.51.0.0/16"]
subnet_names = {
    "az-netb-pr-web-snet" = {
        subnet_name = "az-netb-pr-web-snet"
        address_prefixes = ["10.51.1.0/24"]
        route_table_name = ""
        snet_delegation  = ""
    },
    "az-netb-pr-db-snet" = {
        subnet_name = "az-netb-pr-db-snet"
        address_prefixes = ["10.51.2.0/24"]
        route_table_name = ""
        snet_delegation  = ""
    }
    }
}

# vnet-peering Module is used to create peering between Virtual Networks
module "hub-to-spoke1" {
source = "../modules/vnet-peering"
depends_on = [module.spoke1-vnet]
#depends_on = [module.hub-vnet , module.spoke1-vnet , module.azure_firewall_01]
#depends_on = [module.hub-vnet , module.spoke1-vnet , module.application_gateway, module.vpn_gateway , module.azure_firewall_01]

virtual_network_peering_name = "az-conn-pr-eastus2-vnet-to-az-netb-pr-eastus2-vnet"
#resource_group_name          = module.hub-resourcegroup.rg_name
resource_group_name = var.resource_group_name
#virtual_network_name         = module.hub-vnet.vnet_name
virtual_network_name = var.virtual_network_name
remote_virtual_network_id    = module.spoke1-vnet.vnet_id
allow_virtual_network_access = "true"
allow_forwarded_traffic      = "true"
allow_gateway_transit        = "true"
use_remote_gateways          = "false"

}

# vnet-peering Module is used to create peering between Virtual Networks
module "spoke1-to-hub" {
source = "../modules/vnet-peering"

virtual_network_peering_name = "az-netb-pr-eastus2-vnet-to-az-conn-pr-eastus2-vnet"
#resource_group_name          = module.spoke1-resourcegroup.rg_name
resource_group_name = var.resource_group_name
#virtual_network_name         = module.spoke1-vnet.vnet_name
virtual_network_name = var.virtual_network_name
#remote_virtual_network_id    = module.hub-vnet.vnet_id
remote_virtual_network_id = var.remote_virtual_network_id
allow_virtual_network_access = "true"
allow_forwarded_traffic      = "true"
allow_gateway_transit        = "false"
# As there is no gateway while testing - Setting to False
#use_remote_gateways   = "true"
use_remote_gateways          = "false"
#depends_on = [module.hub-vnet , module.spoke1-vnet]
depends_on = [ module.spoke1-vnet ]
}

# routetables Module is used to create route tables and associate them with Subnets created by Virtual Networks
module "route_tables" {
source = "../modules/routetables"
#depends_on = [module.hub-vnet , module.spoke1-vnet]
depends_on = [ module.spoke1-vnet ]
route_table_name              = "az-netb-pr-eastus2-route"
#location                      = module.hub-resourcegroup.rg_location
location = var.location
#resource_group_name           = module.hub-resourcegroup.rg_name
resource_group_name = var.resource_group_name
disable_bgp_route_propagation = false

route_name                    = "ToAzureFirewall"
address_prefix                = "0.0.0.0/0"
next_hop_type                 = "VirtualAppliance"
#next_hop_in_ip_address        = module.azure_firewall_01.azure_firewall_private_ip
next_hop_in_ip_address = var.next_hop_in_ip_address

subnet_id_01                  = module.spoke1-vnet.vnet_subnet_id[0]
subnet_id_02                  = module.spoke1-vnet.vnet_subnet_id[1]


}


# vm-windows Module is used to create Windows Virtual Machines
module "vm-windows-01" {
source = "../modules/vm-windows"
virtual_machine_name             = "aznetbrap01"
nic_name                         = "aznetbrap01-nic"
location                         = module.spoke1-resourcegroup.rg_location
resource_group_name              = module.spoke1-resourcegroup.rg_name
ipconfig_name                    = "ipconfig1"
subnet_id                        = module.spoke1-vnet.vnet_subnet_id[1]
private_ip_address_allocation    = "Static"
private_ip_address               = "10.51.1.4"
vm_size                          = "Standard_D2s_v3"
# Uncomment this line to delete the OS disk automatically when deleting the VM
delete_os_disk_on_termination    = true
# Uncomment this line to delete the data disks automatically when deleting the VM
delete_data_disks_on_termination = true

publisher                        = "MicrosoftWindowsServer"
offer                            = "WindowsServer"
sku                              = "2019-Datacenter"
storage_version                  = "latest"

os_disk_name                     = "aznetbrap01osdisk"
caching                          = "ReadWrite"
create_option                    = "FromImage"
managed_disk_type                = "Premium_LRS"

admin_username                   = "netb.admin"
admin_password                   = "Password1234!"

provision_vm_agent               = true
depends_on = [module.spoke1-vnet]
}

# vm-linux-01 Module is used to create Linux Virtual Machines
module "vm-linux-01" {
source = "../modules/vm-linux"
nic_name                         = "aznetbrdb01-nic"
location                         = module.spoke1-resourcegroup.rg_location
resource_group_name              = module.spoke1-resourcegroup.rg_name
ipconfig_name                    = "ipconfig1"
subnet_id                        = module.spoke1-vnet.vnet_subnet_id[0]
private_ip_address_allocation    = "Dynamic"
private_ip_address               = ""
# if you wish to have static - Change Dynamic to Static - Fill in Private IP
virtual_machine_name             = "aznetbrdb01"
vm_size                          = "Standard_D2s_v3"
# size                           = "Standard_D8s_v3"

publisher                        = "RedHat"
offer                            = "RHEL"
sku                              = "86-gen2"
storage_version                  = "latest"

os_disk_name                     = "aznetbrdb01osdisk"
caching                          = "ReadWrite"
managed_disk_type                = "Premium_LRS"
disk_size_gb                     = "255"
# if you need larger disk
# disk_size_gb                     = "511"

admin_username                   = "netb.admin"
admin_password                   = "Password1234!"
disable_password_authentication  = false
depends_on = [module.spoke1-vnet]
}



/**
# keyvault Module is used to create Azure Key Vault
# To use Key vault - First Uncomment this block and Choose a unique name
module "key_vault" {
source = "./modules/keyvault"

resource_group_name          = module.hub-resourcegroup.rg_name
location                     = module.hub-resourcegroup.rg_location

# To use Key vault - Choose a unique name below like az-conn-pr-eastus2-kv-05
key_vault_name = "az-conn-pr-eastus2-kv"
sku_name = "standard"
admin_certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update"
    ]

admin_key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey"
    ]

admin_secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Restore",
      "Restore",
      "Set"
    ]

managed_identity_name               = "mi-appgw-keyvault"
managed_identity_secret_permissions = [
      "Get"
    ]
}
**/

/**
# applicationgateway Module is used to create Application Gateway
# To use Applicaition Gateway you need to provision key vault first
# Provision Key Vault - Import Certificate named Prod.pfx with name prod
# So that it uses a managed identity to access the certificate stored in Azure Key Vault

module "application_gateway" {
source = "./modules/applicationgateway"

application_gateway_name       = "az-conn-pr-eastus2-agw"
resource_group_name            = module.hub-resourcegroup.rg_name
location                       = module.hub-resourcegroup.rg_location
# To use Key vault - Choose the existing key vault name
key_vault_name                 = "az-conn-pr-eastus2-kv"
managed_identity_name          = "mi-appgw-keyvault"
public_ip_address_id           = module.public_ip_02.public_ip_address_id
subnet_id                      = module.hub-vnet.vnet_subnet_id[0]
cert_name                      = "prod"

sku_name                       = "Standard_v2"
tier                           = "Standard_v2"
capacity                       = 2

gateway_ip_configuration_name  = "gateway-ip-configuration-01"

frontend_port_name             = "myFrontendPort"
frontend_port_1                = "443"

backend_address_pool_name      = "myBackendPool"

frontend_ip_configuration_name = "myAGIPConfig"
http_setting_name              = "myHTTPsetting"
https_setting_name             = "myHTTPSsetting"
listener_name                  = "myListener"
request_routing_rule_name      = "myRoutingRule"
redirect_configuration_name    = "myRedirectConfig"
backend_ip_addresss            = ["10.51.1.4"]

# Update your Host name - Specified in your SSL Certificate
probe_host_name                = "prod.virtualpetal.com"

}
**/


/**
# vpn-gateway Module is used to create Express Route Gateway - So that it can connect to the express route Circuit
module "vpn_gateway" {
source = "./modules/vpn-gateway"
depends_on = [module.hub-vnet , module.spoke1-vnet , module.azure_firewall_01 , module.application_gateway]

vpn_gateway_name              = "az-conn-pr-eastus2-01-vgw"
location                      = module.hub-resourcegroup.rg_location
resource_group_name           = module.hub-resourcegroup.rg_name

type                          = "ExpressRoute"
vpn_type                      = "PolicyBased"

sku                           = "Standard"
active_active                 = false
enable_bgp                    = false

ip_configuration              = "default"
private_ip_address_allocation = "Dynamic"
subnet_id                     = module.hub-vnet.vnet_subnet_id[2]
public_ip_address_id          = module.public_ip_01.public_ip_address_id

}
**/