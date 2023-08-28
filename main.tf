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

data "azurerm_client_config" "current" {}

#management group
resource "azurerm_management_group" "example" {
  name = "example-management-group"
}

#resource group
resource "azurerm_resource_group" "example" {
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


resource "azurerm_policy_set_definition" "example" {
  name         = "testPolicySet"
  policy_type  = "Custom"
  display_name = "Test Policy Set"

  parameters = <<PARAMETERS
    {
        "allowedLocations": {
            "type": "Array",
            "metadata": {
                "description": "The list of allowed locations for resources.",
                "displayName": "Allowed locations",
                "strongType": "location"
            }
        }
    }
PARAMETERS

  policy_definition_reference {
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"
    parameter_values     = <<VALUE
    {
      "listOfAllowedLocations": {"value": "[parameters('allowedLocations')]"}
    }
    VALUE
  }
}

# budgets plans
resource "azurerm_monitor_action_group" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "example"
}

resource "azurerm_consumption_budget_subscription" "example" {
  name            = "example"
  subscription_id = data.azurerm_client_config.current.subscription_id

  amount     = 1000
  time_grain = "Monthly"

  time_period {
    start_date = "2022-06-01T00:00:00Z"
    end_date   = "2022-07-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [
        azurerm_resource_group.example.name,
      ]
    }

    tag {
      name = "foo"
      values = [
        "bar",
        "baz",
      ]
    }
  }

  notification {
    enabled   = true
    threshold = 90.0
    operator  = "EqualTo"

    contact_emails = [
      "foo@example.com",
      "bar@example.com",
    ]

    contact_groups = [
      azurerm_monitor_action_group.example.id,
    ]

    contact_roles = [
      "Owner",
    ]
  }

  notification {
    enabled        = false
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [
      "foo@example.com",
      "bar@example.com",
    ]
  }
}

# #budget alert


#rabac roles subscription and resource groups level
resource "azurerm_role_assignment" "rbac_owner" {
  for_each = toset(var.rbac_roles["owner"]["assignments"])

  principal_id   = "9a9e2da0-3f04-4a60-9d24-cca10ee77f7f"
  role_definition_name = "Owner"
}

resource "azurerm_role_assignment" "rbac_contributor" {
  for_each = toset(var.rbac_roles["contributor"]["assignments"])

  principal_id   = "9a9e2da0-3f04-4a60-9d24-cca10ee77f7f"
  role_definition_name = "Contributor"
}

resource "azurerm_role_assignment" "rbac_vm_contributor" {
  for_each = toset(var.rbac_roles["vm_contributor"]["assignments"])

  principal_id   = "9a9e2da0-3f04-4a60-9d24-cca10ee77f7f"
  role_definition_name = "Virtual Machine Contributor"
}
# Define other resources here (VNet, Subnet, Route Table, NSG, DDoS policy, SIEM integration, Tags, Budgets, Defender for Cloud)

# Example: Virtual Network
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Example: Subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
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

resource "azurerm_network_ddos_protection_plan" "example" {
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

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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

# resource "azurerm_ddos_protection_plan_association" "example" {
#   resource_uri       = azurerm_virtual_machine.example.id
#   protection_plan_id = azurerm_ddos_protection_plan.example.id
# }

#  siem integration, defender for cloud 
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-log-analytics"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days  = 30
}

resource "azurerm_security_center_subscription_pricing" "example" {
#   resource_group_name = azurerm_resource_group.example.name
  tier                = "Standard"
}

#security SIEM integration
resource "azurerm_security_center_contact" "example" {
  name          = "example-contact"
  email         = "security@example.com"
  phone         = "123-456-7890"
  alert_notifications = true
  alerts_to_admins    = true
}

resource "azurerm_security_center_auto_provisioning" "example" {
  auto_provision = "On"
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
}

# resource "azurerm_security_center_security_contact" "example" {
#   contact_id = azurerm_security_center_contact.example.id
# }

resource "azurerm_security_center_assessment_policy" "example" {
  display_name        = "example-assessment-policy"
#   policy_setting      = "Default"
#   assessment_type     = "VulnerabilityAssessment"
#   resource_type       = "AzureVM"
#   categories          = Compute
  severity            = "Medium"
#   status              = "Enabled"
  description         = "Test Description"
}


resource "azurerm_security_center_auto_provisioning" "defender" {
  auto_provision = "On"
}

resource "azurerm_eventhub_namespace" "example" {
  name                = "example-namespace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  capacity            = 2
}

resource "azurerm_eventhub" "example" {
  name                = "acceptanceTestEventHub"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.example.name
  partition_count     = 2
  message_retention   = 2
}

resource "azurerm_eventhub_authorization_rule" "example" {
  name                = "example-rule"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.example.name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_security_center_automation" "example" {
  name                = "example-automation"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  action {
    type              = "EventHub"
    resource_id       = azurerm_eventhub.example.id
    connection_string = azurerm_eventhub_authorization_rule.example.primary_connection_string
  }

  source {
    event_source = "Alerts"
    rule_set {
      rule {
        property_path  = "properties.metadata.severity"
        operator       = "Equals"
        expected_value = "High"
        property_type  = "String"
      }
    }
  }

  scopes = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
}


# resource "azurerm_defender_for_cloud_subscription" "example" {
#   is_enabled = true
#   resource_group_name = azurerm_resource_group.example.name
# }




