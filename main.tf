terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#management group
resource "azurerm_management_group" "example" {
  name = "example-management-group"
}

#resource group
resource "azurerm_resource_group" "example_rg" {
  name     = "example-resources"
  location = "East US"
}



#policy def
resource "azurerm_policy_definition" "example" {
   name        = "enforce-tagging"
  display_name = "Enforce Tagging Policy"
  description = "Enforces required tags on resources"
  policy_type = "Custom"
  mode        = "All"

  metadata = jsonencode({
    category = "Tags"
  })

  policy_rule = jsonencode({
    "if" : {
      "field" : "tags",
      "not" : {
        "exists" : "true"
      }
    },
    "then" : {
      "effect" : "deny"
    }
  })
}


resource "azurerm_policy_assignment" "example" {
  name                 = "example-policy-assignment"
  scope                = azurerm_resource_group.example.id
  policy_definition_id = azurerm_policy_definition.example.id
}

# budgets plans
resource "azurerm_budget" "example" {
  name                  = "example-budget"
  resource_group_name   = azurerm_resource_group.example.name
  amount                = 100.0
  time_period {
    start_date = "2023-01-01"
    end_date   = "2023-12-31"
  }
}

#budget alert
resource "azurerm_budget_alert" "rg_alert" {
  name               = "rg-budget-alert"
  resource_group_name = azurerm_resource_group.example_rg.name
  budget_id          = azurerm_budget.rg_budget.id

  threshold = 70
  direction = "Up"
  operator  = "GreaterThan"
  time_aggregation = "Average"
}

#rabac roles subscription and resource groups level
resource "azurerm_role_assignment" "rbac_owner" {
  for_each = toset(var.rbac_roles["owner"]["assignments"])

  principal_id   = azurerm_user_assigned_identity.your_identity.principal_id
  role_definition_name = "Owner"
}

resource "azurerm_role_assignment" "rbac_contributor" {
  for_each = toset(var.rbac_roles["contributor"]["assignments"])

  principal_id   = azurerm_user_assigned_identity.your_identity.principal_id
  role_definition_name = "Contributor"
}

resource "azurerm_role_assignment" "rbac_vm_contributor" {
  for_each = toset(var.rbac_roles["vm_contributor"]["assignments"])

  principal_id   = azurerm_user_assigned_identity.your_identity.principal_id
  role_definition_name = "Virtual Machine Contributor"
}
# Define other resources here (VNet, Subnet, Route Table, NSG, DDoS policy, SIEM integration, Tags, Budgets, Defender for Cloud)

# Example: Virtual Network
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
}

# Example: Subnet
resource "azurerm_subnet" "example_subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#UDR
resource "azurerm_route_table" "example" {
  name                = "example-routetable"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  route {
    name          = "route1"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.1"
  }
}

#   NSG
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Define more security rules as needed
}

resource "azurerm_ddos_protection_plan" "example" {
  name                = "example-ddos-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "example-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "example-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_D2_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "adminuser"
    admin_password = "P@ssw0rd!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "testing"
  }
}

resource "azurerm_ddos_protection_plan_association" "example" {
  resource_uri       = azurerm_virtual_machine.example.id
  protection_plan_id = azurerm_ddos_protection_plan.example.id
}

#  siem integration, defender for cloud 
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-log-analytics"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days  = 30
}

resource "azurerm_security_center_subscription_pricing" "example" {
  resource_group_name = azurerm_resource_group.example.name
  tier                = "Standard"
}

#security SIEM integration
resource "azurerm_security_center_contact" "example" {
  name          = "example-contact"
  email         = "security@example.com"
  phone         = "123-456-7890"
  alert_notifications = ["High", "Critical"]
}

resource "azurerm_security_center_auto_provisioning" "example" {
  auto_provision = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_security_center_security_contact" "example" {
  contact_id = azurerm_security_center_contact.example.id
}

resource "azurerm_security_center_assessment_policy" "example" {
  name                = "example-assessment-policy"
  policy_setting      = "Default"
  assessment_type     = "VulnerabilityAssessment"
  resource_type       = "AzureVM"
  severity            = ["High", "Medium"]
  status              = "Enabled"
}


resource "azurerm_security_center_auto_provisioning" "defender" {
  auto_provision = true
  workspace_id   = azurerm_log_analytics_workspace.example.id
  tier           = "Standard"

  security_center_contact {
    alert_notifications = ["High", "Critical"]
  }

  high_priority_security_recommendations = true
}

resource "azurerm_defender_for_cloud_subscription" "example" {
  is_enabled = true
  resource_group_name = azurerm_resource_group.example.name
}




