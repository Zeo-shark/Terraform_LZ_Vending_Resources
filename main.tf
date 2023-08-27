module "rbac" {
  source = "./rbac"
}

module "networking" {
  source = "./networking"
}

module "security" {
  source = "./security"
}

module "tags" {
  source = "./tags"
}

module "policies" {
  source = "./policies"
}
