# ---------------------------------------------------------------------------------------------------
# UPDATE existing alerts_v2 (triage). PATCH only; destroy is a no-op.
# ---------------------------------------------------------------------------------------------------
variable "alert_updates" {
  description = <<-DESC
    Existing alerts (alerts_v2) to update (triage), keyed by a stable logical name. Patches the
    alert identified by alert_id. Typed fields cover the common updatable properties; use body for
    anything else (merged over the typed fields).
  DESC

  type = map(object({
    alert_id               = string
    api_version            = optional(string)
    status                 = optional(string)
    classification         = optional(string)
    determination          = optional(string)
    assigned_to            = optional(string)
    body                   = optional(any)
    response_export_values = optional(map(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.alert_updates :
      v.status == null ? true : contains(["new", "inProgress", "resolved"], v.status)
    ])
    error_message = "alert_updates status must be one of new, inProgress or resolved."
  }

  validation {
    condition = alltrue([
      for k, v in var.alert_updates :
      v.classification == null ? true : contains(["unknown", "falsePositive", "truePositive", "informationalExpectedActivity"], v.classification)
    ])
    error_message = "alert_updates classification must be one of unknown, falsePositive, truePositive or informationalExpectedActivity."
  }
}

variable "default_api_version" {
  description = <<-DESC
    Default Microsoft Graph API version for operations that do not set their own. One of "v1.0" or
    "beta". Update and comment operations are documented on v1.0 (stable) and default to it. The
    create operations (incidents, alerts) are only exposed on beta, so they default to beta
    regardless of this value unless you pin api_version on the entry.
  DESC
  type        = string
  default     = "v1.0"

  validation {
    condition     = contains(["v1.0", "beta"], var.default_api_version)
    error_message = "default_api_version must be v1.0 or beta."
  }
}

# ---------------------------------------------------------------------------------------------------
# Incident comments. POST /security/incidents/{id}/comments (documented). A one-time action.
# ---------------------------------------------------------------------------------------------------
variable "incident_comments" {
  description = "Comments to add to existing incidents, keyed by a stable logical name. Each posts one comment to the incident identified by incident_id. Adding a comment is a one-time action (not removed on destroy)."

  type = map(object({
    incident_id = string
    comment     = string
    api_version = optional(string)
  }))

  default = {}
}

# ---------------------------------------------------------------------------------------------------
# UPDATE existing incidents (triage). Documented on v1.0 and beta. PATCH only; destroy is a no-op so
# Terraform never tries to delete a system incident.
# ---------------------------------------------------------------------------------------------------
variable "incident_updates" {
  description = <<-DESC
    Existing security incidents to update (triage), keyed by a stable logical name. Patches the
    incident identified by incident_id. The typed fields cover the common updatable properties; use
    body to set anything else (it is merged over the typed fields).
  DESC

  type = map(object({
    incident_id            = string
    api_version            = optional(string)
    status                 = optional(string)
    classification         = optional(string)
    determination          = optional(string)
    assigned_to            = optional(string)
    custom_tags            = optional(list(string))
    body                   = optional(any)
    response_export_values = optional(map(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.incident_updates :
      v.status == null ? true : contains(["active", "resolved", "inProgress", "redirected", "awaitingAction"], v.status)
    ])
    error_message = "incident_updates status must be one of active, resolved, inProgress, redirected or awaitingAction."
  }

  validation {
    condition = alltrue([
      for k, v in var.incident_updates :
      v.classification == null ? true : contains(["unknown", "falsePositive", "truePositive", "informationalExpectedActivity"], v.classification)
    ])
    error_message = "incident_updates classification must be one of unknown, falsePositive, truePositive or informationalExpectedActivity."
  }
}

# ---------------------------------------------------------------------------------------------------
# CREATE incidents (EXPERIMENTAL). The beta metadata exposes POST /security/incidents, but Microsoft
# does not document a create-incident operation and describes incidents as system-generated, so this
# is unverified. Provided so it can be tested against a licensed tenant. Managed with full CRUD
# (POST create, PATCH/PUT update, DELETE destroy) via msgraph_resource.
# ---------------------------------------------------------------------------------------------------
variable "incidents" {
  description = <<-DESC
    Security incidents to create and manage, keyed by a stable logical name. EXPERIMENTAL: creating
    incidents through Graph is a beta, undocumented capability; verify it against your tenant. body
    is the raw incident object (for example displayName, severity, status, classification,
    determination, customTags). api_version defaults to beta because create is beta only.
  DESC

  type = map(object({
    body                   = any
    api_version            = optional(string)
    update_method          = optional(string)
    response_export_values = optional(map(string))
  }))

  default = {}
}

# ---------------------------------------------------------------------------------------------------
# CREATE a manual alert (createManualAlert): POST /security/alerts_v2. Documented on beta. This is a
# real, supported create (unlike incidents), and is how you raise a custom alert that rolls up into a
# Defender incident. title, description, severity and category are required by the API.
# ---------------------------------------------------------------------------------------------------
variable "manual_alerts" {
  description = <<-DESC
    Manual alerts to create via the createManualAlert operation (POST /security/alerts_v2), keyed by
    a stable logical name. The module always sends the required @odata.type
    (#microsoft.graph.security.manualAlert). title, description, severity, category and
    entity_definitions (1 to 100) are required by the API; the rest are optional. Anything else can
    be set through body (merged over the typed fields). Creating a manual alert makes Defender open
    (or, with link_to_incident, link to) an incident. api_version defaults to beta.
  DESC

  type = map(object({
    title       = optional(string)
    description = optional(string)
    severity    = optional(string)
    category    = optional(string)

    # 1 to 100 impacted/related entities. Required by the API (supply via body if you prefer).
    entity_definitions = optional(list(object({
      entity_type       = string # user, ip, device, file, ...
      entity_identifier = string # userPrincipalName, address, deviceName, sha256, ...
      identifier_value  = string
      role              = optional(string, "impacted") # impacted | related
    })), [])

    recommended_actions          = optional(string)
    mitre_techniques             = optional(list(string))
    sentinel_workspace           = optional(string) # route the alert to a Sentinel workspace
    link_to_incident             = optional(number) # link to an existing incident id instead of a new one
    is_excluded_from_correlation = optional(bool)

    body                   = optional(any)
    api_version            = optional(string)
    update_method          = optional(string)
    response_export_values = optional(map(string))
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.manual_alerts :
      v.severity == null ? true : contains(["unknown", "informational", "low", "medium", "high"], v.severity)
    ])
    error_message = "manual_alerts severity must be one of unknown, informational, low, medium or high."
  }

  validation {
    condition = alltrue([
      for k, v in var.manual_alerts :
      length(v.entity_definitions) <= 100 && (length(v.entity_definitions) >= 1 || v.body != null)
    ])
    error_message = "each manual_alerts entry needs 1 to 100 entity_definitions (or supply entityDefinitions through body)."
  }

  validation {
    condition = alltrue(flatten([
      for v in var.manual_alerts : [for e in v.entity_definitions : contains(["impacted", "related"], e.role)]
    ]))
    error_message = "entity_definitions role must be impacted or related."
  }
}

# ---------------------------------------------------------------------------------------------------
# Generic passthrough for any other Graph security resource with full CRUD, for example beta custom
# detection rules (security/rules/detectionRules), which are the documented way to have custom
# alerts and incidents generated into the Defender portal.
# ---------------------------------------------------------------------------------------------------
variable "security_resources" {
  description = <<-DESC
    Arbitrary Graph security resources to manage with full CRUD, keyed by a stable logical name.
    url is the collection URL (for example "security/rules/detectionRules"), body is the resource
    object. Use this for endpoints without a first-class input above, notably custom detection
    rules, which generate alerts and incidents that surface in the Defender portal.
  DESC

  type = map(object({
    url                    = string
    body                   = any
    api_version            = optional(string)
    update_method          = optional(string)
    response_export_values = optional(map(string))
  }))

  default = {}
}
