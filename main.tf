locals {
  # Build incident PATCH bodies from the typed convenience fields (dropping nulls, mapping to the
  # Graph camelCase names) then merge the raw body over the top so it wins.
  incident_update_bodies = {
    for k, v in var.incident_updates : k => merge(
      { for kk, vv in {
        status         = v.status
        classification = v.classification
        determination  = v.determination
        assignedTo     = v.assigned_to
        customTags     = v.custom_tags
      } : kk => vv if vv != null },
      v.body != null ? v.body : {},
    )
  }

  alert_update_bodies = {
    for k, v in var.alert_updates : k => merge(
      { for kk, vv in {
        status         = v.status
        classification = v.classification
        determination  = v.determination
        assignedTo     = v.assigned_to
      } : kk => vv if vv != null },
      v.body != null ? v.body : {},
    )
  }
}

# ---- CREATE incidents (experimental, beta) ----
resource "msgraph_resource" "incidents" {
  for_each = var.incidents

  url                    = "security/incidents"
  api_version            = coalesce(each.value.api_version, "beta")
  body                   = each.value.body
  update_method          = coalesce(each.value.update_method, "PATCH")
  response_export_values = each.value.response_export_values
}

# ---- UPDATE existing incidents (triage) ----
resource "msgraph_update_resource" "incident_updates" {
  for_each = var.incident_updates

  url                    = "security/incidents/${each.value.incident_id}"
  api_version            = coalesce(each.value.api_version, var.default_api_version)
  body                   = local.incident_update_bodies[each.key]
  response_export_values = each.value.response_export_values
}

# ---- Incident comments (one-time POST) ----
resource "msgraph_resource_action" "incident_comments" {
  for_each = var.incident_comments

  resource_url = "security/incidents/${each.value.incident_id}"
  action       = "comments"
  method       = "POST"
  api_version  = coalesce(each.value.api_version, var.default_api_version)

  body = {
    "@odata.type" = "microsoft.graph.security.alertComment"
    comment       = each.value.comment
  }
}

# ---- CREATE alerts (experimental, beta) ----
resource "msgraph_resource" "alerts" {
  for_each = var.alerts

  url                    = "security/alerts_v2"
  api_version            = coalesce(each.value.api_version, "beta")
  body                   = each.value.body
  update_method          = coalesce(each.value.update_method, "PATCH")
  response_export_values = each.value.response_export_values
}

# ---- UPDATE existing alerts_v2 (triage) ----
resource "msgraph_update_resource" "alert_updates" {
  for_each = var.alert_updates

  url                    = "security/alerts_v2/${each.value.alert_id}"
  api_version            = coalesce(each.value.api_version, var.default_api_version)
  body                   = local.alert_update_bodies[each.key]
  response_export_values = each.value.response_export_values
}

# ---- Generic security resources (for example custom detection rules) ----
resource "msgraph_resource" "security_resources" {
  for_each = var.security_resources

  url                    = each.value.url
  api_version            = coalesce(each.value.api_version, var.default_api_version)
  body                   = each.value.body
  update_method          = coalesce(each.value.update_method, "PATCH")
  response_export_values = each.value.response_export_values
}
