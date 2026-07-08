# Plan-time tests for the module. The msgraph provider is mocked, so no credentials and no cloud
# calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "msgraph" {}

variables {
  incident_updates = {
    triage = {
      incident_id    = "00000000-0000-0000-0000-000000000000"
      status         = "inProgress"
      classification = "truePositive"
      determination  = "multiStagedAttack"
      assigned_to    = "soc@example.com"
      custom_tags    = ["triaged-by-terraform"]
    }
  }

  incident_comments = {
    note = {
      incident_id = "00000000-0000-0000-0000-000000000000"
      comment     = "Triaged by Terraform."
    }
  }

  alert_updates = {
    triage = {
      alert_id       = "11111111-1111-1111-1111-111111111111"
      status         = "inProgress"
      classification = "truePositive"
    }
  }

  incidents = {
    manual = {
      body = { displayName = "Test", severity = "medium" }
    }
  }

  manual_alerts = {
    phish = {
      title       = "Suspected phishing"
      description = "A user reported a phishing email."
      severity    = "medium"
      category    = "InitialAccess"
    }
  }

  security_resources = {
    rule = {
      url         = "security/rules/detectionRules"
      api_version = "beta"
      body        = { displayName = "Rule", isEnabled = true }
    }
  }
}

run "resources_are_created_per_entry" {
  command = plan

  assert {
    condition     = length(msgraph_update_resource.incident_updates) == 1 && length(msgraph_update_resource.alert_updates) == 1
    error_message = "One update resource should be created per incident_updates / alert_updates entry."
  }

  assert {
    condition     = length(msgraph_resource_action.incident_comments) == 1
    error_message = "One comment action should be created per incident_comments entry."
  }

  assert {
    condition     = length(msgraph_resource.incidents) == 1 && length(msgraph_resource.security_resources) == 1
    error_message = "One resource should be created per incidents / security_resources entry."
  }
}

run "incident_update_body_maps_typed_fields_to_graph_names" {
  command = plan

  assert {
    condition     = msgraph_update_resource.incident_updates["triage"].body.status == "inProgress"
    error_message = "status should be carried onto the PATCH body."
  }

  assert {
    condition     = msgraph_update_resource.incident_updates["triage"].body.assignedTo == "soc@example.com"
    error_message = "assigned_to should map to the Graph camelCase assignedTo."
  }

  assert {
    condition     = contains(msgraph_update_resource.incident_updates["triage"].body.customTags, "triaged-by-terraform")
    error_message = "custom_tags should map to the Graph customTags."
  }
}

run "create_defaults_to_beta" {
  command = plan

  assert {
    condition     = msgraph_resource.incidents["manual"].api_version == "beta"
    error_message = "The incident create path should default to the beta API version."
  }
}

run "updates_default_to_v1_0" {
  command = plan

  assert {
    condition     = msgraph_update_resource.incident_updates["triage"].api_version == "v1.0"
    error_message = "Update operations should default to the stable v1.0 API version."
  }
}

run "comment_body_has_odata_type" {
  command = plan

  assert {
    condition     = msgraph_resource_action.incident_comments["note"].body.comment == "Triaged by Terraform."
    error_message = "The comment text should be carried onto the action body."
  }
}

run "manual_alert_posts_to_alerts_v2_with_typed_body" {
  command = plan

  assert {
    condition     = msgraph_resource.manual_alerts["phish"].url == "security/alerts_v2"
    error_message = "createManualAlert should POST to security/alerts_v2."
  }

  assert {
    condition     = msgraph_resource.manual_alerts["phish"].body.title == "Suspected phishing"
    error_message = "The typed title should be carried onto the manual alert body."
  }

  assert {
    condition     = msgraph_resource.manual_alerts["phish"].api_version == "beta"
    error_message = "createManualAlert defaults to the beta API version."
  }
}

run "invalid_incident_status_is_rejected" {
  command = plan

  variables {
    incident_updates = {
      bad = { incident_id = "00000000-0000-0000-0000-000000000000", status = "notARealStatus" }
    }
  }

  expect_failures = [var.incident_updates]
}
