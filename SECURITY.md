# Security Policy

## Scope

This repository contains instructions, metric definitions and code patterns for AI agents. It
does not run services or store data. Security issues most likely to matter here:

- a skill that instructs an agent to expose credentials, bypass row-level security or move
  data somewhere unexpected;
- install scripts that write outside the intended folders;
- examples that would leak sensitive data (PHI, PII, salaries) if followed literally.

## Reporting

Use GitHub's private vulnerability reporting (Security tab ▸ Report a vulnerability). Please
don't open a public issue for security reports. We aim to acknowledge within 3 business days.

## Data rules for contributors

- No real customer, patient or employee data in issues, PRs, examples or screenshots.
- No credentials, connection strings with secrets, or tenant identifiers.
- Healthcare and HR skills must default to aggregated, de-identified designs.
