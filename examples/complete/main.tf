# Complete call, showing the full toolkit against the Microsoft Defender unified security surface:
#   - triage an existing incident and add a comment
#   - triage an existing alert (alerts_v2)
#   - create a custom detection rule (beta), the documented way to have custom alerts and incidents
#     generated into the Defender portal
#   - optionally attempt the experimental beta incident create (behind enable_experimental_create)
#
# Nothing here can be applied without a licensed tenant (Defender / E5) and the security Graph
# permissions; the ids are placeholders to replace.
locals {
  # The experimental incident create, gated so the default configuration does not attempt it. A
  # for/if keeps the type consistent whether or not it is present.
  experimental_incidents = {
    manual = {
      api_version = "beta"
      body = {
        displayName    = "Terraform-authored incident"
        severity       = "medium"
        status         = "active"
        classification = "truePositive"
        determination  = "multiStagedAttack"
        customTags     = ["created-by-terraform"]
      }
    }
  }
}

module "security" {
  source = "../../"

  # Triage an existing incident (v1.0, stable).
  incident_updates = {
    triage = {
      incident_id    = var.incident_id
      status         = "inProgress"
      classification = "truePositive"
      determination  = "multiStagedAttack"
      assigned_to    = "soc@example.com"
      custom_tags    = ["triaged-by-terraform"]
    }
  }

  # Add a comment to that incident.
  incident_comments = {
    note = {
      incident_id = var.incident_id
      comment     = "Triaged and assigned by Terraform."
    }
  }

  # Triage an existing alert.
  alert_updates = {
    triage = {
      alert_id       = var.alert_id
      status         = "inProgress"
      classification = "truePositive"
      determination  = "malware"
      assigned_to    = "soc@example.com"
    }
  }

  # Raise a manual alert (createManualAlert, POST /security/alerts_v2, documented on beta). This is
  # a real create and is how a custom alert rolls up into a Defender incident.
  manual_alerts = {
    reported-phish = {
      title            = "User-reported phishing email"
      description      = "A user reported a suspicious email that passed mail filtering."
      severity         = "medium"
      category         = "InitialAccess"
      mitre_techniques = ["T1566"]
    }
  }

  # A custom detection rule (beta): the documented mechanism for generating custom alerts and
  # incidents into the Defender portal.
  security_resources = {
    suspicious-process = {
      url         = "security/rules/detectionRules"
      api_version = "beta"
      body = {
        displayName = "Terraform: suspicious encoded PowerShell"
        isEnabled   = true
        queryCondition = {
          queryText = "DeviceProcessEvents | where FileName =~ 'powershell.exe' and ProcessCommandLine has '-enc' | project Timestamp, DeviceId, DeviceName, InitiatingProcessAccountName"
        }
        schedule = {
          period = "24H"
        }
        detectionAction = {
          alertTemplate = {
            title              = "Suspicious encoded PowerShell"
            description        = "An encoded PowerShell command line was observed."
            severity           = "medium"
            category           = "Execution"
            recommendedActions = "Investigate the initiating account and host."
            mitreTechniques    = ["T1059.001"]
            impactedAssets = [
              {
                "@odata.type" = "#microsoft.graph.security.impactedDeviceAsset"
                identifier    = "deviceId"
              }
            ]
          }
          organizationalScope = null
          responseActions     = []
        }
      }
    }
  }

  # Experimental incident create (off by default).
  incidents = { for k, v in local.experimental_incidents : k => v if var.enable_experimental_create }
}
