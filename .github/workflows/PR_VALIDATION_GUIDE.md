# PR Validation Workflow - Implementation Summary

## Overview

This document describes the new PR validation workflow that enables lightweight static checks and optional terraform plans with approval gates.

## Problem Solved

The issue requested a PR workflow that:

1. Runs "cheap" validation steps (validate, tflint, checkov)
2. Pauses at an environment before doing deploy (using environment approvals)
3. Allows calling workflows to control which environment needs validation
4. Enables PRs to always run static checks with optional plans

## Architecture

### Workflow: terraform-pr-validation-template.yml

This reusable workflow provides two validation modes:

#### Mode 1: Static Checks Only (Default)

- Runs without Azure authentication
- No secrets or environment configuration needed
- Fast feedback on code quality
- Includes:
  - Terraform validate
  - Terraform format check
  - TFLint
  - Checkov static code scanning

#### Mode 2: Static Checks + Optional Plan

- Static checks run first (no auth needed)
- Plan step runs conditionally if `environment_name_plan` is provided
- Uses GitHub environment protection rules for approval gates
- Posts plan summary to PR for reviewer visibility
- Reuses existing `terraform-plan-template.yml` workflow

### Key Design Decisions

1. **Two-Job Structure**: Separates concerns between unauthenticated static checks and authenticated plan operations
2. **Conditional Plan**: Plan job only runs if `environment_name_plan` input is provided
3. **Reuse Existing Workflows**: Plan job calls `terraform-plan-template.yml` to avoid duplication
4. **Environment-Based Approval**: Leverages GitHub environment protection rules for approval workflow

## Code Consolidation

### New Composite Action: terraform-init

Created a reusable composite action for Terraform initialization that:

- Supports both backend and non-backend initialization modes
- Centralizes initialization logic (previously duplicated across 3 workflows)
- Reduces ~40 lines of duplicated code
- Used by:
  - `terraform-plan-template.yml`
  - `terraform-apply-template.yml`
  - `terraform-pr-validation-template.yml`

## Usage Patterns

### Pattern 1: Always Static Checks, Never Plan

```yaml
uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
with:
  root_iac_folder_relative_path: './iac'
  # No environment_name_plan = no plan step
```

### Pattern 2: Always Static Checks, Optional Plan with Approval

```yaml
uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
with:
  root_iac_folder_relative_path: './iac'
  environment_name_plan: 'dev-iac-plan'  # Enables plan with approval
  tfvars_file: './environments/dev.terraform.tfvars'
```

### Pattern 3: Conditional Plan Based on PR Labels

Consuming repositories can implement logic to conditionally pass `environment_name_plan`:

```yaml
jobs:
  static-validation:
    # Always run static checks
    uses: .../terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './iac'
  
  conditional-plan:
    # Only run if PR has "run-plan" label
    if: contains(github.event.pull_request.labels.*.name, 'run-plan')
    uses: .../terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './iac'
      environment_name_plan: 'dev-iac-plan'
      tfvars_file: './environments/dev.terraform.tfvars'
```

## Benefits

### For Consumers

1. **Fast Feedback**: Static checks run immediately without waiting for approvals
2. **Cost Effective**: No Azure resources consumed for basic validation
3. **Controlled Access**: Plans require explicit approval via environment protection rules
4. **Flexible**: Easy to enable/disable plan step based on needs
5. **Gradual Adoption**: Can start with static checks only, add plans later

### For Maintainers

1. **Reduced Duplication**: terraform-init action eliminates repeated code
2. **Easier Maintenance**: Changes to init logic only need to be made once
3. **Consistent Behavior**: All workflows use the same initialization logic
4. **Clear Separation**: Static validation vs authenticated operations

## Files Changed

### New Files

- `.github/workflows/terraform-pr-validation-template.yml` - Main PR validation workflow
- `.github/actions/terraform-init/action.yml` - Reusable init action
- `.github/actions/terraform-init/README.md` - Init action documentation
- `.github/workflows/EXAMPLES.md` - Comprehensive usage examples

### Modified Files

- `README.md` - Added PR validation workflow documentation
- `.github/workflows/terraform-plan-template.yml` - Uses terraform-init action
- `.github/workflows/terraform-apply-template.yml` - Uses terraform-init action

## Testing Recommendations

For consuming repositories:

1. **Test Static Checks Only**: Create a PR to verify static checks run successfully
2. **Test Optional Plan**: Configure environment with approval rules, verify approval workflow
3. **Test Conditional Logic**: If using conditional plans, verify conditions work as expected
4. **Verify PR Comments**: Ensure plan summaries appear in PR comments when applicable

## Future Enhancements

Potential improvements:

1. Create composite action for Azure login + firewall unlock pattern
2. Consider creating a "static checks only" composite action
3. Add support for parallel validation of multiple environments
4. Add cost estimation (Infracost) to PR validation workflow

## Migration Guide

For existing consumers using `terraform-deploy-template.yml` for PR validation:

### Before

```yaml
on:
  pull_request:
jobs:
  validate:
    uses: .../terraform-deploy-template.yml@main
    with:
      terraform_action: plan
      environment_name_plan: 'dev-iac-plan'
      # ... other inputs
```

### After

```yaml
on:
  pull_request:
jobs:
  validate:
    uses: .../terraform-pr-validation-template.yml@main
    with:
      environment_name_plan: 'dev-iac-plan'  # Optional
      # ... other inputs
```

Benefits of migration:

- Faster static checks (no wait for environment access)
- Clearer intent (dedicated PR validation workflow)
- More flexible (easy to disable plan step)
