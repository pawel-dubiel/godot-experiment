# Project Instructions

Avoid defensive fallback logic that masks ownership or configuration errors. Systems should have clear responsibilities and explicit dependencies.

When required collaborators or data are missing, report the missing contract clearly and abort the operation instead of catching the problem, substituting defaults, or repairing state in an ad hoc way.
