<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform MSGraph Alerts and Incidents Utils

Manage Microsoft Defender (unified security, security.microsoft.com) alerts and incidents through
the Microsoft Graph security API, using the [Microsoft/msgraph](https://registry.terraform.io/providers/Microsoft/msgraph/latest)
provider. Triage existing incidents and alerts, add incident comments, manage custom detection
rules, and (experimentally) attempt incident and alert creation, with a `v1.0` or `beta` toggle per
operation.

> **Status: core, untested.** This module has not been run against a live tenant yet (it needs a
> Defender / E5 licence and the security Graph permissions). It is published as the core surface to
> be validated and released once a licensed tenant is available. CI self-test and release are held
> until then.

[![CI](https://github.com/libre-devops/terraform-msgraph-alerts-and-incidents-utils/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-msgraph-alerts-and-incidents-utils/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-msgraph-alerts-and-incidents-utils?sort=semver&label=release)](https://github.com/libre-devops/terraform-msgraph-alerts-and-incidents-utils/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-msgraph-alerts-and-incidents-utils)](./LICENSE)

---

## Why Graph and not the Azure Sentinel API

Microsoft Sentinel now surfaces its incidents and alerts in the Microsoft Defender portal
(security.microsoft.com); the workspace is still deployed in Azure, but the incident experience
moved. The Graph `/security/incidents` and `/security/alerts_v2` endpoints are that unified
Defender surface, whereas the older `Microsoft.SecurityInsights` (Azure) API is the Azure-portal
one. This module targets Graph so the changes land where analysts now work.

## What Graph actually supports (important)

- **Update / triage** incidents and alerts: **documented and stable** on `v1.0` (`PATCH`).
- **Comments** on incidents: **documented** (`POST /security/incidents/{id}/comments`).
- **Custom detection rules** (`security/rules/detectionRules`, beta): the **documented** way to have
  custom alerts and incidents generated into the Defender portal. Managed here via `security_resources`.
- **Creating a manual alert** (`createManualAlert`, `POST /security/alerts_v2`, beta): **documented.**
  This is a real, supported create and the way to raise a custom alert that rolls up into a Defender
  incident. Managed here via `manual_alerts` (title, description, severity and category are required).
- **Creating incidents directly**: **experimental and unverified.** Microsoft documents incidents as
  system-generated and publishes no create operation, but the beta metadata exposes a `POST` on the
  collection. The `incidents` input attempts that `POST` so it can be tested against a licensed
  tenant; do not rely on it until you have.

## Inputs at a glance

| Input | Operation | Graph resource used |
|---|---|---|
| `incident_updates` | PATCH an existing incident | `msgraph_update_resource` (destroy is a no-op) |
| `incident_comments` | POST a comment | `msgraph_resource_action` |
| `alert_updates` | PATCH an existing alert | `msgraph_update_resource` |
| `manual_alerts` | create a manual alert (createManualAlert, documented) | `msgraph_resource` |
| `security_resources` | full CRUD on any security resource (detection rules, ...) | `msgraph_resource` |
| `incidents` | experimental incident create (beta, unverified) | `msgraph_resource` |

## Minimum permissions

All as Microsoft Graph application permissions, admin-consented, on a Defender / E5 tenant:

| Feature | Minimum permission |
|---|---|
| Read/update incidents and comments | `SecurityIncident.ReadWrite.All` |
| Read/update alerts (alerts_v2) | `SecurityAlert.ReadWrite.All` |
| Custom detection rules | `CustomDetection.ReadWrite.All` |

## Examples

- [`examples/minimal`](./examples/minimal) - triage one existing incident.
- [`examples/complete`](./examples/complete) - triage an incident and alert, add a comment, create a custom detection rule, and (behind a flag) attempt the experimental incident create.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_msgraph"></a> [msgraph](#requirement\_msgraph) | >= 0.1.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_msgraph"></a> [msgraph](#provider\_msgraph) | >= 0.1.0, < 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [msgraph_resource.incidents](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/resource) | resource |
| [msgraph_resource.manual_alerts](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/resource) | resource |
| [msgraph_resource.security_resources](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/resource) | resource |
| [msgraph_resource_action.incident_comments](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/resource_action) | resource |
| [msgraph_update_resource.alert_updates](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/update_resource) | resource |
| [msgraph_update_resource.incident_updates](https://registry.terraform.io/providers/Microsoft/msgraph/latest/docs/resources/update_resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_updates"></a> [alert\_updates](#input\_alert\_updates) | Existing alerts (alerts\_v2) to update (triage), keyed by a stable logical name. Patches the<br/>alert identified by alert\_id. Typed fields cover the common updatable properties; use body for<br/>anything else (merged over the typed fields). | <pre>map(object({<br/>    alert_id               = string<br/>    api_version            = optional(string)<br/>    status                 = optional(string)<br/>    classification         = optional(string)<br/>    determination          = optional(string)<br/>    assigned_to            = optional(string)<br/>    body                   = optional(any)<br/>    response_export_values = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_default_api_version"></a> [default\_api\_version](#input\_default\_api\_version) | Default Microsoft Graph API version for operations that do not set their own. One of "v1.0" or<br/>"beta". Update and comment operations are documented on v1.0 (stable) and default to it. The<br/>create operations (incidents, alerts) are only exposed on beta, so they default to beta<br/>regardless of this value unless you pin api\_version on the entry. | `string` | `"v1.0"` | no |
| <a name="input_incident_comments"></a> [incident\_comments](#input\_incident\_comments) | Comments to add to existing incidents, keyed by a stable logical name. Each posts one comment to the incident identified by incident\_id. Adding a comment is a one-time action (not removed on destroy). | <pre>map(object({<br/>    incident_id = string<br/>    comment     = string<br/>    api_version = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_incident_updates"></a> [incident\_updates](#input\_incident\_updates) | Existing security incidents to update (triage), keyed by a stable logical name. Patches the<br/>incident identified by incident\_id. The typed fields cover the common updatable properties; use<br/>body to set anything else (it is merged over the typed fields). | <pre>map(object({<br/>    incident_id            = string<br/>    api_version            = optional(string)<br/>    status                 = optional(string)<br/>    classification         = optional(string)<br/>    determination          = optional(string)<br/>    assigned_to            = optional(string)<br/>    custom_tags            = optional(list(string))<br/>    body                   = optional(any)<br/>    response_export_values = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_incidents"></a> [incidents](#input\_incidents) | Security incidents to create and manage, keyed by a stable logical name. EXPERIMENTAL: creating<br/>incidents through Graph is a beta, undocumented capability; verify it against your tenant. body<br/>is the raw incident object (for example displayName, severity, status, classification,<br/>determination, customTags). api\_version defaults to beta because create is beta only. | <pre>map(object({<br/>    body                   = any<br/>    api_version            = optional(string)<br/>    update_method          = optional(string)<br/>    response_export_values = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_manual_alerts"></a> [manual\_alerts](#input\_manual\_alerts) | Manual alerts to create via the createManualAlert operation (POST /security/alerts\_v2), keyed by<br/>a stable logical name. The module always sends the required @odata.type<br/>(#microsoft.graph.security.manualAlert). title, description, severity, category and<br/>entity\_definitions (1 to 100) are required by the API; the rest are optional. Anything else can<br/>be set through body (merged over the typed fields). Creating a manual alert makes Defender open<br/>(or, with link\_to\_incident, link to) an incident. api\_version defaults to beta. | <pre>map(object({<br/>    title       = optional(string)<br/>    description = optional(string)<br/>    severity    = optional(string)<br/>    category    = optional(string)<br/><br/>    # 1 to 100 impacted/related entities. Required by the API (supply via body if you prefer).<br/>    entity_definitions = optional(list(object({<br/>      entity_type       = string # user, ip, device, file, ...<br/>      entity_identifier = string # userPrincipalName, address, deviceName, sha256, ...<br/>      identifier_value  = string<br/>      role              = optional(string, "impacted") # impacted | related<br/>    })), [])<br/><br/>    recommended_actions          = optional(string)<br/>    mitre_techniques             = optional(list(string))<br/>    sentinel_workspace           = optional(string) # route the alert to a Sentinel workspace<br/>    link_to_incident             = optional(number) # link to an existing incident id instead of a new one<br/>    is_excluded_from_correlation = optional(bool)<br/><br/>    body                   = optional(any)<br/>    api_version            = optional(string)<br/>    update_method          = optional(string)<br/>    response_export_values = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_security_resources"></a> [security\_resources](#input\_security\_resources) | Arbitrary Graph security resources to manage with full CRUD, keyed by a stable logical name.<br/>url is the collection URL (for example "security/rules/detectionRules"), body is the resource<br/>object. Use this for endpoints without a first-class input above, notably custom detection<br/>rules, which generate alerts and incidents that surface in the Defender portal. | <pre>map(object({<br/>    url                    = string<br/>    body                   = any<br/>    api_version            = optional(string)<br/>    update_method          = optional(string)<br/>    response_export_values = optional(map(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_update_ids"></a> [alert\_update\_ids](#output\_alert\_update\_ids) | Map of alert-update key to the target alert resource id. |
| <a name="output_alert_update_outputs"></a> [alert\_update\_outputs](#output\_alert\_update\_outputs) | Map of alert-update key to its exported response values. |
| <a name="output_incident_comment_outputs"></a> [incident\_comment\_outputs](#output\_incident\_comment\_outputs) | Map of incident-comment key to the action response. |
| <a name="output_incident_ids"></a> [incident\_ids](#output\_incident\_ids) | Map of incident key to the created incident resource id (only for incidents created via the experimental create path). |
| <a name="output_incident_update_ids"></a> [incident\_update\_ids](#output\_incident\_update\_ids) | Map of incident-update key to the target incident resource id. |
| <a name="output_incident_update_outputs"></a> [incident\_update\_outputs](#output\_incident\_update\_outputs) | Map of incident-update key to its exported response values. |
| <a name="output_incidents"></a> [incidents](#output\_incidents) | Map of incident key to its resource url and exported response values (create path). |
| <a name="output_manual_alert_ids"></a> [manual\_alert\_ids](#output\_manual\_alert\_ids) | Map of manual-alert key to the created alert resource id. |
| <a name="output_manual_alerts"></a> [manual\_alerts](#output\_manual\_alerts) | Map of manual-alert key to its resource url and exported response values. |
| <a name="output_security_resources"></a> [security\_resources](#output\_security\_resources) | Map of security-resource key to its resource url and exported response values. |
<!-- END_TF_DOCS -->
