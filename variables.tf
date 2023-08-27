variable "rbac_roles" {
  description = "RBAC roles configuration"
  type = map(map(list(string)))
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
