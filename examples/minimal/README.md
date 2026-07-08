<!--
  Header for the minimal example README. Edit this file, then run `just docs`
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

# Minimal example

Triage a single existing Defender incident (the smallest documented, stable operation): patch its
status, classification, determination, assignee and tags over the v1.0 Graph surface. Replace the
placeholder `incident_id` with a real one. Needs `SecurityIncident.ReadWrite.All` on a licensed
tenant.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
# Minimal call: triage one existing Defender incident (the smallest documented, stable operation).
# This patches the incident over the v1.0 Graph surface, which is the Microsoft Defender unified
# (security.microsoft.com) incident. Needs SecurityIncident.ReadWrite.All.
module "security" {
  source = "../../"

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
| <a name="input_incident_id"></a> [incident\_id](#input\_incident\_id) | Object id of an existing Defender incident to triage. Replace with a real id from your tenant. | `string` | `"00000000-0000-0000-0000-000000000000"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_incident_update_ids"></a> [incident\_update\_ids](#output\_incident\_update\_ids) | Target incident ids for the triage updates. |
<!-- END_TF_DOCS -->
