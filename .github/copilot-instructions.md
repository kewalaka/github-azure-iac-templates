# GitHub Copilot Instructions for github-azure-iac-templates

## Repository Purpose

This repository provides reusable GitHub Actions workflows and composite actions designed for deploying Terraform code to Microsoft Azure. It facilitates multi-environment deployments (e.g., dev, test, prod) from a single Terraform codebase using environment-specific `.tfvars` files.

## Key Design Principles & Context

1. **Authentication:** Uses Azure OIDC with User-Assigned Managed Identities. Relies on GitHub Repository **Secrets** (`ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`) for credentials. These are accessed via `secrets.ARM_*` expressions in workflows and must be passed to called workflows using `secrets: inherit`.
2. **State Management:** Terraform state is stored in Azure Blob Storage, configured via `TF_STATE_*` variables.
3. **Plan Artifacts:** Terraform plan files (`tfplan`) are passed between `plan` and `apply` jobs using Azure Blob Storage (`ARTIFACT_STORAGE_CONTAINER_NAME` variable). This is a deliberate security choice to prevent exposure via standard GitHub artifacts, which are readable by anyone with repository read access. **Do not suggest switching to standard GitHub artifacts.**
4. **Environment Strategy:** Requires **two** GitHub Environments per target (e.g., `dev-iac-plan`, `dev-iac-apply`).
    * `_plan` environment: Contains variables for the plan step.
    * `_apply` environment: Contains the same variables *and* is where deployment protection rules (e.g., required reviewers) should be configured.
    * This two-environment setup is **required** to apply protection rules only to the deployment (`apply`) step. **Do not suggest simplifying to a single environment per target.**
5. **Firewall Handling (`azure-unlock-firewall` action):** Includes an *optional* mechanism (`azure-unlock-firewall` action, `unlock_resource_firewalls` input) to temporarily open Azure Storage/Key Vault firewalls for GitHub runner IPs.
    * This is an **alternative** for users unable to use self-hosted runners or Private Endpoints.
    * It is **not the recommended** approach for securing access. Prefer network-integrated runners where possible.
6. **Destroy Operations:** Supports destroy via `terraform_action: destroy` or `terraform_action: apply` combined with the `destroy_resources: true` flag. The `destroy_resources` flag is also used with `terraform_action: plan` to generate *destroy plans*. This dual mechanism is intentional for flexibility.
7. **Structure:** Comprises reusable workflows (`*-template.yml`) which call composite actions (under `.github/actions/`).
8. **Versioning:** Workflows and actions should be referenced using version tags (e.g., `@v1.0`) in consuming workflows for stability.
9. **Usage:** Intended to be called from other repositories using the `uses:` syntax (e.g., `uses: org/repo/.github/workflows/terraform-deploy-template.yml@v1.0`). Requires appropriate repository/organization access settings for private repositories.
10. **Common Workflow Pattern:** While `workflow_dispatch` is supported for manual runs, a primary use case is a CI/CD flow:
    * Run `terraform plan` (using `terraform-deploy-template.yml` with `terraform_action: plan`) on `pull_request` events targeting the main branch. This typically uses the `_plan` environment.
    * Run `terraform apply` (using `terraform-deploy-template.yml` with `terraform_action: apply`) on `push` events to the main branch (i.e., merges). This uses the `_apply` environment, which should have protection rules.

11. **PR Plan Commenting:** The `terraform-plan` composite action includes optional functionality to post a plan summary (from `tfplandoc`) as a comment on Pull Requests.
    * This only activates if the workflow is triggered by a `pull_request` event.
    * It requires the `github_token` input to be passed to the `terraform-plan` action (typically `${{ secrets.GITHUB_TOKEN }}` from the calling workflow).
    * The **top-level workflow** that initiates the run (e.g., the one triggering on `pull_request`) **must** have `permissions: pull-requests: write` defined for the comment posting to succeed.
12. **Variable Handling:** 
    * Job-level `env:` variables are accessible via `${{ env.VAR_NAME }}` expressions in YAML
    * However, these are NOT automatically available as shell environment variables in action scripts
    * For important backend configuration like `TF_STATE_*` variables, proper handling is required to ensure availability in both contexts
13. **Security Scanning:** Integrates Checkov for IaC security scanning
    * Plan outputs are scanned using tfplan.json format
    * Configurable via a flexible JSON-based parameter system allowing any Checkov environment variable to be set
    * Results are output in SARIF format and uploaded to GitHub code scanning
    * Can be bypassed using the `enable_static_analysis_checks` flag for development workflows
14. **Plan Output Enhancement:** 
    * Uses tfplandoc to generate human-readable summaries of Terraform plans
    * Plan summaries are added to workflow step summaries 
    * When triggered by pull requests, summaries can be posted as PR comments for reviewer convenience
    * Requires appropriate permissions: `pull-requests: write` on the workflow

## When Assisting

* Refer to the `README.md` for user-facing setup and usage instructions.
* Respect the design decisions outlined above, especially regarding artifact storage and the two-environment strategy.
* When suggesting changes or additions, consider the impact on consuming workflows and maintain consistency with the existing structure.
* Ensure code examples correctly distinguish between:
  * GitHub Secrets (`secrets.SECRET_NAME`) for sensitive values
  * GitHub Variables (`vars.VAR_NAME`) for non-sensitive configuration
  * Proper handling of shell environment variables within action scripts
* Always include `secrets: inherit` when calling reusable workflows to ensure secrets are passed through
