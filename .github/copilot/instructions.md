# GitHub Copilot Instructions for github-azure-iac-templates

## Repository Purpose

This repository provides reusable GitHub Actions workflows and composite actions designed for deploying Terraform code to Microsoft Azure. It facilitates multi-environment deployments (e.g., dev, test, prod) from a single Terraform codebase using environment-specific `.tfvars` files.

## Key Design Principles & Context

1. **Authentication:** Uses Azure OIDC with User-Assigned Managed Identities. Relies on GitHub Environment **Variables** (`AZURE_CLIENT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`) for credentials. **Do not suggest changing these to Secrets unless explicitly asked.**
2. **State Management:** Terraform state is stored in Azure Blob Storage, configured via `TF_STATE_*` variables.
3. **Plan Artifacts:** Terraform plan files (`tfplan`) are passed between `plan` and `apply` jobs using Azure Blob Storage (`ARTIFACT_BLOB_CONTAINER` variable and custom `create/download/deleteartifact` actions). This is a deliberate security choice to prevent exposure via standard GitHub artifacts, which are readable by anyone with repository read access. **Do not suggest switching to standard GitHub artifacts.**
4. **Environment Strategy:** Requires **two** GitHub Environments per target (e.g., `dev_plan`, `dev_apply`).
    * `_plan` environment: Contains variables for the plan step.
    * `_apply` environment: Contains the same variables *and* is where deployment protection rules (e.g., required reviewers) should be configured.
    * This two-environment setup is **required** to apply protection rules only to the deployment (`apply`) step. **Do not suggest simplifying to a single environment per target.**
5. **Firewall Handling (`ipdefault` action):** Includes an *optional* mechanism (`ipdefault` action, `requireStorageAccountFirewallAction` input) to temporarily open Azure Storage/Key Vault firewalls for GitHub runner IPs.
    * This is an **alternative** for users unable to use self-hosted runners or Private Endpoints.
    * It is **not the recommended** approach for securing access. Prefer network-integrated runners where possible.
6. **Destroy Operations:** Supports destroy via `terraform_action: destroy` or `terraform_action: apply` combined with the `destroyResources: true` flag. The `destroyResources` flag is also used with `terraform_action: plan` to generate *destroy plans*. This dual mechanism is intentional for flexibility.
7. **Structure:** Comprises reusable workflows (`*-template.yml`) which call composite actions (under `.github/actions/`).
8. **Versioning:** Workflows and actions should be referenced using version tags (e.g., `@v1.0`) in consuming workflows for stability.
9. **Usage:** Intended to be called from other repositories using the `uses:` syntax (e.g., `uses: org/repo/.github/workflows/terraform-deploy-template.yml@v1.0`). Requires appropriate repository/organization access settings for private repositories.

## When Assisting

* Refer to the `README.md` for user-facing setup and usage instructions.
* Respect the design decisions outlined above, especially regarding artifact storage and the two-environment strategy.
* When suggesting changes or additions, consider the impact on consuming workflows and maintain consistency with the existing structure.
* Ensure code examples use GitHub Environment Variables (`vars.VAR_NAME`) for configuration unless explicitly dealing with secrets passed via `secrets: inherit`.
