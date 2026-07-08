# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated.

# The create paths only exist on beta; a v1.0 create will fail. Manual alert creation
# (createManualAlert) is documented on beta; direct incident creation is beta metadata only.
check "create_requires_beta" {
  assert {
    condition = alltrue(concat(
      [for k, v in var.incidents : coalesce(v.api_version, "beta") == "beta"],
      [for k, v in var.manual_alerts : coalesce(v.api_version, "beta") == "beta"],
    ))
    error_message = "Creating an incident or manual alert requires api_version = beta; the v1.0 surface has no create operation."
  }
}

# createManualAlert requires title, description, severity and category (via the typed fields or body).
check "manual_alert_required_fields" {
  assert {
    condition = alltrue([
      for k, v in var.manual_alerts :
      v.body != null ? true : (v.title != null && v.description != null && v.severity != null && v.category != null)
    ])
    error_message = "Each manual_alerts entry must set title, description, severity and category (or supply them through body)."
  }
}

# The Graph security API rejects a determination without a classification.
check "determination_needs_classification" {
  assert {
    condition = alltrue(concat(
      [for k, v in var.incident_updates : v.determination == null || v.classification != null],
      [for k, v in var.alert_updates : v.determination == null || v.classification != null],
    ))
    error_message = "Setting determination requires classification to be set as well (the Graph security API pairs them)."
  }
}
