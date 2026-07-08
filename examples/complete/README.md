<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

The full toolkit against the Defender unified security surface: triage an existing incident and add
a comment, triage an existing alert (alerts_v2), create a custom detection rule (beta, the
documented way to generate custom alerts and incidents into the Defender portal), and, behind
`enable_experimental_create`, attempt the experimental beta incident create. All ids are
placeholders to replace, and applying needs a Defender / E5 tenant with the security Graph
permissions.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_msgraph"></a> [msgraph](#requirement\_msgraph) | >= 0.1.0, < 1.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_security"></a> [security](#module\_security) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_id"></a> [alert\_id](#input\_alert\_id) | Object id of an existing Defender alert (alerts\_v2) to triage. Replace with a real id. | `string` | `"11111111-1111-1111-1111-111111111111"` | no |
| <a name="input_enable_experimental_create"></a> [enable\_experimental\_create](#input\_enable\_experimental\_create) | Whether to attempt creating an incident through the experimental beta POST path. Off by default:<br/>creating incidents through Graph is undocumented and unverified. Turn it on only to test the<br/>behaviour against a licensed tenant. | `bool` | `false` | no |
| <a name="input_incident_id"></a> [incident\_id](#input\_incident\_id) | Object id of an existing Defender incident to triage and comment on. Replace with a real id. | `string` | `"00000000-0000-0000-0000-000000000000"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_update_ids"></a> [alert\_update\_ids](#output\_alert\_update\_ids) | Target alert ids for the triage updates. |
| <a name="output_incident_ids"></a> [incident\_ids](#output\_incident\_ids) | Created incident ids (only populated when enable\_experimental\_create is set). |
| <a name="output_incident_update_ids"></a> [incident\_update\_ids](#output\_incident\_update\_ids) | Target incident ids for the triage updates. |
| <a name="output_security_resources"></a> [security\_resources](#output\_security\_resources) | Created security resources (the custom detection rule). |
<!-- END_TF_DOCS -->
