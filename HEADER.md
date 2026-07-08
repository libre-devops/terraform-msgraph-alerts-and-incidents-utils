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