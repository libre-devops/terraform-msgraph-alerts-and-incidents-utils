# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated.

# The create endpoints only exist on beta; a v1.0 create will fail.
check "create_requires_beta" {
  assert {
    condition = alltrue(concat(
      [for k, v in var.incidents : coalesce(v.api_version, "beta") == "beta"],
      [for k, v in var.alerts : coalesce(v.api_version, "beta") == "beta"],
    ))
    error_message = "Creating an incident or alert requires api_version = beta; the v1.0 surface has no create operation."
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
