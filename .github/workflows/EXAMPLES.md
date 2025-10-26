# Example PR Validation Workflow for Consuming Repositories

This directory contains example workflows that consuming repositories can use.

## Example 1: PR Validation with Static Checks Only

This workflow runs static checks on every PR without requiring Azure authentication or environment approvals.

```yaml
name: Terraform PR Validation

on:
  pull_request:
    branches:
      - main
    paths:
      - 'iac/**'
      - '.github/workflows/**'

permissions:
  contents: read
  pull-requests: write
  security-events: write

jobs:
  pr-validation:
    name: "PR Validation - Static Checks"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './infra'
      enable_static_analysis_checks: true
      enable_checkov: true
    secrets: inherit
```

## Example 2: PR Validation with Optional Plan (Approval Required)

This workflow runs static checks first, then optionally runs a terraform plan if approved via GitHub environment protection rules.

```yaml
name: Terraform PR Validation with Optional Plan

on:
  pull_request:
    branches:
      - main
    paths:
      - 'iac/**'
      - '.github/workflows/**'

permissions:
  contents: read
  pull-requests: write
  security-events: write
  id-token: write

jobs:
  pr-validation:
    name: "PR Validation with Optional Plan"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './infra'
      enable_static_analysis_checks: true
      enable_checkov: true
      # Providing environment_name_plan enables the optional plan step
      environment_name_plan: 'dev-iac-plan'  # Must have approval rules configured
      tfvars_file: './environments/dev.terraform.tfvars'
    secrets: inherit
```

## Example 3: Dynamic Environment Detection

This example shows how a consuming workflow can detect which environment needs validation based on branch or PR labels.

```yaml
name: Smart PR Validation

on:
  pull_request:
    branches:
      - main
      - develop
    paths:
      - 'iac/**'
      - '.github/workflows/**'

permissions:
  contents: read
  pull-requests: write
  security-events: write
  id-token: write

jobs:
  # First job: Always run static checks
  static-validation:
    name: "Static Code Validation"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './infra'
      enable_static_analysis_checks: true
      enable_checkov: true
      # No environment_name_plan = no plan step
    secrets: inherit

  # Second job: Conditional plan based on PR label
  conditional-plan:
    name: "Optional Terraform Plan"
    # Only run if PR has "run-plan" label
    if: contains(github.event.pull_request.labels.*.name, 'run-plan')
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './infra'
      enable_static_analysis_checks: false  # Already done in static-validation
      enable_checkov: false  # Already done in static-validation
      environment_name_plan: 'dev-iac-plan'
      tfvars_file: './environments/dev.terraform.tfvars'
    secrets: inherit
```

## Environment Setup

For workflows that include the optional plan step, ensure you have configured:

1. **GitHub Environment** (e.g., `dev-iac-plan`) with:
   - Required reviewers (optional but recommended)
   - Secrets: `ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`
   - Secrets: `TF_STATE_RESOURCE_GROUP_NAME`, `TF_STATE_STORAGE_ACCOUNT_NAME`

2. **Protection Rules** on the environment to require approvals before running the plan

## Benefits

- **Fast Feedback**: Static checks run immediately without waiting for approvals
- **Cost Effective**: No Azure resources consumed for basic validation
- **Controlled Access**: Plans require explicit approval via environment protection rules
- **Flexible**: Easy to enable/disable plan step based on your needs
