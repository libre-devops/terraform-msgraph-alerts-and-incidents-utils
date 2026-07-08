output "alert_update_ids" {
  description = "Target alert ids for the triage updates."
  value       = module.security.alert_update_ids
}

output "incident_ids" {
  description = "Created incident ids (only populated when enable_experimental_create is set)."
  value       = module.security.incident_ids
}

output "incident_update_ids" {
  description = "Target incident ids for the triage updates."
  value       = module.security.incident_update_ids
}

output "security_resources" {
  description = "Created security resources (the custom detection rule)."
  value       = module.security.security_resources
}
