variable "rbac_roles" {
  description = "List of RBAC roles"
  type        = map(map(list(string)))
  # Define RBAC roles here
  default = {
    "owner" = {
      "assignments" = [
        "user1@example.com",
        "user2@example.com"
      ]
    }
    "contributor" = {
      "assignments" = [
        "user3@example.com",
        "user4@example.com"
      ]
    }
    "vm_contributor" = {
      "assignments" = [
        "user5@example.com"
      ]
    }
  }
}

# Define RBAC assignments using the variable

# rbac - owner/contributor/vm contributor
# vnet/subnet/route table/nsg
# assign ddos policy
# siem integration
# tags subscriptions
# tags to resource groups
# default budgets

# [Friday 4:38 PM] Allan Lewis
# defender for cloud