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
