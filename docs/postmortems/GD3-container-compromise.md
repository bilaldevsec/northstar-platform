# Post-Incident Review: Game Day 3 (Container Compromise)
Severity: SEV1 | Incident Commander: @bilaldevsec
- Summary: A simulated attacker gained shell access to the orders-api container and attempted to read /etc/shadow.
- Detection (MTTD): Falco detected the interactive shell (Notice: A shell was spawned) in < 1 minute.
- Response (MTTR): Pod was quarantined via NetworkPolicy label.
- Action Items: Verify ReadOnlyRootFilesystem is enforced via Azure Policy.
