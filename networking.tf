variable "vnet_config" {
  description = "VNet configuration"
  type        = map(map(string))
  # Define VNet configurations here
}

variable "subnet_config" {
  description = "Subnet configuration"
  type        = map(map(string))
  # Define subnet configurations here
}

# Define VNet, subnet, route table, NSG resources using the variables
