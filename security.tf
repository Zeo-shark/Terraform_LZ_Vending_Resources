variable "ddos_policy_config" {
  description = "DDoS policy configuration"
  type        = map(map(string))
  # Define DDoS policy configurations here
}

variable "siem_integration_config" {
  description = "SIEM integration configuration"
  type        = map(map(string))
  # Define SIEM integration configurations here
}

variable "defender_for_cloud_config" {
  description = "Defender for Cloud configuration"
  type        = map(map(string))
  # Define Defender for Cloud configurations here
}

# Define DDos policy, SIEM integration, Defender for Cloud resources using the variables
