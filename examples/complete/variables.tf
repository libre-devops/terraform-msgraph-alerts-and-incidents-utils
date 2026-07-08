variable "alert_id" {
  description = "Object id of an existing Defender alert (alerts_v2) to triage. Replace with a real id."
  type        = string
  default     = "11111111-1111-1111-1111-111111111111"
}

variable "enable_experimental_create" {
  description = <<-DESC
    Whether to attempt creating an incident through the experimental beta POST path. Off by default:
    creating incidents through Graph is undocumented and unverified. Turn it on only to test the
    behaviour against a licensed tenant.
  DESC
  type        = bool
  default     = false
}

variable "incident_id" {
  description = "Object id of an existing Defender incident to triage and comment on. Replace with a real id."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}
