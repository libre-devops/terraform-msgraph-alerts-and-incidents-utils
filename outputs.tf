output "alert_update_ids" {
  description = "Map of alert-update key to the target alert resource id."
  value       = { for k, v in msgraph_update_resource.alert_updates : k => v.id }
}

output "alert_update_outputs" {
  description = "Map of alert-update key to its exported response values."
  value       = { for k, v in msgraph_update_resource.alert_updates : k => v.output }
}

output "incident_comment_outputs" {
  description = "Map of incident-comment key to the action response."
  value       = { for k, v in msgraph_resource_action.incident_comments : k => v.output }
}

output "incident_ids" {
  description = "Map of incident key to the created incident resource id (only for incidents created via the experimental create path)."
  value       = { for k, v in msgraph_resource.incidents : k => v.id }
}

output "incident_update_ids" {
  description = "Map of incident-update key to the target incident resource id."
  value       = { for k, v in msgraph_update_resource.incident_updates : k => v.id }
}

output "incident_update_outputs" {
  description = "Map of incident-update key to its exported response values."
  value       = { for k, v in msgraph_update_resource.incident_updates : k => v.output }
}

output "incidents" {
  description = "Map of incident key to its resource url and exported response values (create path)."
  value       = { for k, v in msgraph_resource.incidents : k => { id = v.id, resource_url = v.resource_url, output = v.output } }
}

output "manual_alert_ids" {
  description = "Map of manual-alert key to the created alert resource id."
  value       = { for k, v in msgraph_resource.manual_alerts : k => v.id }
}

output "manual_alerts" {
  description = "Map of manual-alert key to its resource url and exported response values."
  value       = { for k, v in msgraph_resource.manual_alerts : k => { id = v.id, resource_url = v.resource_url, output = v.output } }
}

output "security_resources" {
  description = "Map of security-resource key to its resource url and exported response values."
  value       = { for k, v in msgraph_resource.security_resources : k => { id = v.id, resource_url = v.resource_url, output = v.output } }
}
