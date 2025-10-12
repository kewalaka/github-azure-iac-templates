# PR Validation Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Consuming Repository Workflow                       │
│                                                                          │
│  on: pull_request                                                        │
│                                                                          │
│  jobs:                                                                   │
│    pr-validation:                                                        │
│      uses: .../terraform-pr-validation-template.yml                      │
│      with:                                                               │
│        environment_name_plan: 'dev-iac-plan'  # Optional                │
│        tfvars_file: './environments/dev.terraform.tfvars'               │
└────────────────────────┬────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              terraform-pr-validation-template.yml                        │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │ Job 1: static-checks                                              │ │
│  │ ✓ No Azure auth required                                          │ │
│  │ ✓ Fast execution                                                  │ │
│  │                                                                    │ │
│  │   1. Checkout code                                                │ │
│  │   2. Install Terraform                                            │ │
│  │   3. Terraform Init (backend=false) ────────────────┐            │ │
│  │   4. Terraform Lint ─────────────────────────┐      │            │ │
│  │      • terraform validate                    │      │            │ │
│  │      • terraform fmt check                   │      │            │ │
│  │      • tflint                                │      │            │ │
│  │   5. Checkov static scan                     │      │            │ │
│  │      • Scans .tf files directly              │      │            │ │
│  │      • Uploads SARIF to GitHub Security      │      │            │ │
│  └──────────────────────────────────────────────┼──────┼────────────┘ │
│                                                  │      │              │
│                         ┌────────────────────────┘      │              │
│                         │                               │              │
│                         ▼                               │              │
│  ┌─────────────────────────────────────┐               │              │
│  │ Reusable Actions                    │               │              │
│  │                                     │               │              │
│  │ • terraform-init ◄──────────────────┼───────────────┘              │
│  │ • terraform-lint ◄──────────────────┘                              │
│  └─────────────────────────────────────┘                              │
│                                                                         │
│                         ┌─── If environment_name_plan is provided      │
│                         │                                               │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │ Job 2: terraform-plan (Optional)                                  │ │
│  │ ✓ Requires Azure auth                                             │ │
│  │ ✓ Uses environment approval                                       │ │
│  │                                                                    │ │
│  │   Calls: terraform-plan-template.yml                              │ │
│  │   with:                                                            │ │
│  │     - enable_static_analysis_checks: false  # Already done        │ │
│  │     - target_environment: {environment_name_plan}                 │ │
│  │     - upload_artifact: false  # No artifact for PR validation     │ │
│  │                                                                    │ │
│  │   ┌────────────────────────────────────────┐                      │ │
│  │   │ terraform-plan-template.yml            │                      │ │
│  │   │                                        │                      │ │
│  │   │ 1. Azure Login (OIDC)                 │                      │ │
│  │   │ 2. Unlock Firewalls (if needed)       │                      │ │
│  │   │ 3. Terraform Init (with backend)      │                      │ │
│  │   │ 4. Terraform Plan                     │                      │ │
│  │   │ 5. Generate Plan Summary (tfplandoc)  │                      │ │
│  │   │ 6. Post Summary to PR Comment         │                      │ │
│  │   │ 7. Checkov Scan (on tfplan.json)      │                      │ │
│  │   │ 8. Lock Firewalls                     │                      │ │
│  │   └────────────────────────────────────────┘                      │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

                                 ┌─────────────────────┐
                                 │  GitHub Environment  │
                                 │  'dev-iac-plan'     │
                                 │                     │
                                 │  • Secrets          │
                                 │  • Variables        │
                                 │  • Protection Rules │
                                 │    (Approvals)      │
                                 └─────────────────────┘
```

## Flow Description

### 1. Static Checks (Always Runs)
- **Trigger**: Automatic on PR creation/update
- **Duration**: Fast (1-3 minutes typically)
- **Cost**: Free (no Azure resources)
- **Actions**: Validates code syntax, style, and security
- **Output**: 
  - Pass/fail status on PR
  - SARIF security scan results
  - Inline comments for issues

### 2. Terraform Plan (Optional)
- **Trigger**: Only if `environment_name_plan` is provided
- **Approval**: Uses GitHub environment protection rules
- **Duration**: Moderate (3-5 minutes typically)
- **Cost**: Minimal (Azure API calls only)
- **Actions**: Generates actual terraform plan
- **Output**:
  - Plan summary in PR comment
  - Enhanced security scan (on plan)
  - Resource changes preview

## Decision Points

```
PR Created/Updated
      │
      ▼
Static Checks ──┐
      │         │
      ├─────────┴─► PASS? ──No──► PR blocked, fix required
      │                │
      │               Yes
      │                │
      ▼                ▼
environment_name_plan provided?
      │                │
     No               Yes
      │                │
      ▼                ▼
   Done          Environment configured
                  with approval rules?
                       │
                       ├──No──► Plan runs immediately
                       │
                      Yes
                       │
                       ▼
                  Waits for approval
                       │
                       ▼
                  Approved? ──No──► Plan skipped
                       │
                      Yes
                       │
                       ▼
                  Plan executes
                       │
                       ▼
                  Summary posted to PR
                       │
                       ▼
                     Done
```

## Key Benefits

1. **Fast Feedback Loop**
   - Static checks complete in 1-3 minutes
   - No waiting for Azure auth or approvals
   - Catches 80% of issues quickly

2. **Optional Deep Validation**
   - Plan step only when needed
   - Controlled by environment approvals
   - Shows actual infrastructure changes

3. **Cost Effective**
   - Static checks are free
   - Plans only run when approved
   - No unnecessary Azure API calls

4. **Flexible Configuration**
   - Enable/disable plan per PR
   - Different environments for different branches
   - Conditional logic based on labels/paths

5. **Security**
   - Environment-based approval gates
   - SARIF integration with GitHub Security
   - Scans both code and plans
