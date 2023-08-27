variable "rbac_roles" {
  description = "List of RBAC roles"
  type        = map(map(list(string)))
  # Define RBAC roles here
}

# Define RBAC assignments using the variable
