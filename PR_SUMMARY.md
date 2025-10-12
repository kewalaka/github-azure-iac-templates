# Pull Request Summary: Add PR Validation Workflow

## Overview
This PR implements a comprehensive PR validation workflow for Terraform infrastructure as code, addressing the need for "cheap" static validation and optional infrastructure plans with approval gates.

## What's New

### 1. New PR Validation Workflow
**File:** `.github/workflows/terraform-pr-validation-template.yml`

A flexible, two-stage validation workflow:
- **Stage 1 (Static Checks):** Always runs, no Azure auth required
  - Terraform validate
  - Terraform format check
  - TFLint
  - Checkov static security scan
- **Stage 2 (Plan):** Optional, runs only if `environment_name_plan` is provided
  - Uses GitHub environment protection rules for approval
  - Generates terraform plan
  - Posts plan summary to PR
  - Enhanced security scanning on plan output

### 2. Code Consolidation - terraform-init Action
**Files:** 
- `.github/actions/terraform-init/action.yml`
- `.github/actions/terraform-init/README.md`

New composite action that centralizes Terraform initialization:
- Supports both backend and non-backend modes
- Used by 3 workflows (plan, apply, pr-validation)
- Eliminates ~40 lines of duplicated code
- Single source of truth for init logic

### 3. Updated Workflows
**Files:**
- `.github/workflows/terraform-plan-template.yml`
- `.github/workflows/terraform-apply-template.yml`

Both workflows now use the new `terraform-init` action instead of inline shell scripts.

### 4. Comprehensive Documentation
**Files:**
- `README.md` - Added PR validation section with examples
- `.github/workflows/EXAMPLES.md` - Detailed usage patterns
- `.github/workflows/PR_VALIDATION_GUIDE.md` - Implementation details
- `.github/workflows/ARCHITECTURE.md` - Visual architecture diagrams

## Usage Example

### For Consuming Repositories

**Option 1: Static checks only (recommended for most PRs)**
```yaml
name: PR Validation

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './iac'
    secrets: inherit
```

**Option 2: Static checks + optional plan (with approval)**
```yaml
name: PR Validation with Plan

on:
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read
  pull-requests: write
  security-events: write

jobs:
  validate:
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-pr-validation-template.yml@main
    with:
      root_iac_folder_relative_path: './iac'
      environment_name_plan: 'dev-iac-plan'
      tfvars_file: './environments/dev.terraform.tfvars'
    secrets: inherit
```

## Benefits

### For Users
1. **Fast Feedback:** Static checks complete in 1-3 minutes
2. **Cost-Effective:** No Azure resources consumed for basic validation
3. **Flexible:** Easy to enable/disable plan step
4. **Controlled:** Plans require explicit approval via environment rules
5. **Informative:** Plan summaries posted as PR comments

### For Maintainers
1. **Reduced Duplication:** Consolidated initialization logic
2. **Easier Maintenance:** Changes in one place affect all workflows
3. **Consistent Behavior:** All workflows use same init process
4. **Better Testing:** Clearer separation between static and authenticated steps

## Technical Details

### Changes Summary
- **Files Added:** 6 (1 workflow, 1 action, 4 documentation files)
- **Files Modified:** 3 (README.md, 2 workflow templates)
- **Lines Added:** +664
- **Lines Removed:** -23
- **Net Change:** +641 lines

### Validation
- ✅ All YAML files validated
- ✅ All workflows syntactically correct
- ✅ All actions syntactically correct
- ✅ No breaking changes to existing workflows

## Testing Recommendations

For consuming repositories adopting this workflow:

1. **Test static checks:** Create a PR with a small change to verify checks run
2. **Test validation failures:** Introduce a formatting issue to verify detection
3. **Test optional plan:** Configure environment with approvals, verify gate works
4. **Test PR comments:** Verify plan summaries appear in comments
5. **Test security scans:** Check SARIF results appear in Security tab

## Migration Guide

Existing consumers using `terraform-deploy-template.yml` for PR validation can migrate:

**Before:**
```yaml
uses: .../terraform-deploy-template.yml@main
with:
  terraform_action: plan
  environment_name_plan: 'dev-iac-plan'
  # ... many other required inputs
```

**After:**
```yaml
uses: .../terraform-pr-validation-template.yml@main
with:
  environment_name_plan: 'dev-iac-plan'  # Optional!
  # ... minimal required inputs
```

## Breaking Changes
None. All existing workflows continue to work as before.

## Future Enhancements
Potential improvements identified but not implemented:
- Composite action for Azure login + firewall unlock pattern
- Support for parallel validation of multiple environments
- Integration with Infracost for cost estimation in PRs

## Documentation
See these files for detailed information:
- `README.md` - Quick start and basic examples
- `.github/workflows/EXAMPLES.md` - Comprehensive usage patterns
- `.github/workflows/PR_VALIDATION_GUIDE.md` - Implementation details and architecture
- `.github/workflows/ARCHITECTURE.md` - Visual diagrams and flow charts

## Acknowledgments
This implementation follows the design principles established in the repository:
- Two-environment strategy (plan/apply)
- Azure Blob Storage for artifacts (not GitHub artifacts)
- OIDC authentication
- Environment protection rules for approvals
